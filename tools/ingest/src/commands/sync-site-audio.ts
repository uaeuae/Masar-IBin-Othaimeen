import { loadSeeds } from '../seeds.js';
import { mergeAudioLessons, sortByEpisodeNumber } from '../merge.js';
import { readStoredLessons, writeStoredLessons } from '../store.js';
import { estimateMp3DurationSeconds } from '../site.js';
import type { SiteAudioLesson, SiteClient } from '../site.js';

export interface AudioProbe {
  durationSeconds: number | null;
  /** false = the file is missing/empty on the server (broken upload). */
  playable: boolean;
}

export interface SyncSiteAudioOptions {
  seedDir: string;
  dataDir: string;
  client: SiteClient;
  dryRun: boolean;
  /** Injectable for tests; default probes the MP3's first bytes over HTTP. */
  probeAudio?: (audioUrl: string) => Promise<AudioProbe>;
  log?: (line: string) => void;
}

/**
 * Range-fetches the start of an MP3 and estimates its duration. When the
 * file opens with an ID3v2 tag larger than the first window (embedded cover
 * art), a second range request reads right past the tag.
 */
export async function probeMp3(audioUrl: string): Promise<AudioProbe> {
  async function fetchRange(from: number, to: number): Promise<{ bytes: Uint8Array; total: number } | null> {
    const response = await fetch(audioUrl, { headers: { Range: `bytes=${from}-${to}` } });
    // 416 with "bytes */0" = zero-byte file; any error = unreachable.
    if (!response.ok) return null;
    const contentRange = response.headers.get('content-range');
    const total = contentRange
      ? Number(contentRange.split('/')[1])
      : Number(response.headers.get('content-length') ?? 0);
    if (!Number.isFinite(total) || total <= 0) return null;
    return { bytes: new Uint8Array(await response.arrayBuffer()), total };
  }

  try {
    const first = await fetchRange(0, 65535);
    if (!first) return { durationSeconds: null, playable: false };
    const direct = estimateMp3DurationSeconds(first.bytes, first.total);
    if (direct !== null) return { durationSeconds: direct, playable: true };

    // Oversized ID3v2 tag? Read its declared size and skip past it.
    const h = first.bytes;
    if (h.length >= 10 && h[0] === 0x49 && h[1] === 0x44 && h[2] === 0x33) {
      const tagSize =
        (((h[6] ?? 0) & 0x7f) << 21) |
        (((h[7] ?? 0) & 0x7f) << 14) |
        (((h[8] ?? 0) & 0x7f) << 7) |
        ((h[9] ?? 0) & 0x7f);
      const audioStart = 10 + tagSize;
      if (audioStart > h.length) {
        const second = await fetchRange(audioStart, audioStart + 8191);
        if (second) {
          const est = estimateMp3DurationSeconds(second.bytes, second.total - audioStart);
          if (est !== null) return { durationSeconds: est, playable: true };
        }
      }
    }
    // Reachable but not parsable — playable, duration unknown (the player
    // reports the exact duration at runtime anyway).
    return { durationSeconds: null, playable: true };
  } catch {
    return { durationSeconds: null, playable: false };
  }
}

/**
 * Pulls every seeded audio-library section from the foundation's site API
 * and merges it into the content store. Same idempotency contract as
 * sync:youtube. Duration probes only run for lessons that don't have a
 * stored duration yet (they're derived from static files — they don't drift).
 */
export async function syncSiteAudio(
  options: SyncSiteAudioOptions,
): Promise<{ changedSeries: string[] }> {
  const log = options.log ?? console.log;
  const probe = options.probeAudio ?? probeMp3;
  const { series } = loadSeeds(options.seedDir);
  const changedSeries: string[] = [];

  for (const seed of series) {
    if (seed.media !== 'audio') continue;
    if (seed.site_audio_sections.length === 0) {
      log(`- ${seed.slug}: no site audio sections configured, skipping`);
      continue;
    }

    const lessons: SiteAudioLesson[] = [];
    for (const sectionId of seed.site_audio_sections) {
      // Per section (not across): multi-section series restart numbering.
      lessons.push(...sortByEpisodeNumber(await options.client.fetchSectionLessons(sectionId)));
    }

    const previous = readStoredLessons(options.dataDir, seed.slug);
    const knownDurations = new Map(
      previous.filter((l) => l.duration_seconds != null).map((l) => [l.youtube_video_id, l.duration_seconds]),
    );

    const durations = new Map<string, number | null>();
    const playability = new Map<string, boolean>();
    for (const lesson of lessons) {
      const known = knownDurations.get(lesson.siteId);
      if (known != null) {
        durations.set(lesson.siteId, known);
        playability.set(lesson.siteId, true);
      } else {
        const probed = await probe(lesson.audioUrl);
        durations.set(lesson.siteId, probed.durationSeconds);
        playability.set(lesson.siteId, probed.playable);
      }
    }

    const result = mergeAudioLessons(seed, previous, lessons, durations, playability);
    const changed =
      result.added.length > 0 ||
      result.updated.length > 0 ||
      result.lessons.length !== previous.length;

    log(
      `- ${seed.slug}: ${result.lessons.length} audio lessons ` +
        `(+${result.added.length} added, ~${result.updated.length} updated, ` +
        `${result.markedUnavailable.length} became unavailable)${options.dryRun ? ' [dry-run]' : ''}`,
    );

    if (changed) {
      changedSeries.push(seed.slug);
      if (!options.dryRun) {
        writeStoredLessons(options.dataDir, seed.slug, result.lessons);
      }
    }
  }

  return { changedSeries };
}
