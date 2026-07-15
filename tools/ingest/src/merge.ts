import type { SeriesSeed } from './schemas.js';
import type { StoredLesson } from './store.js';
import type { SiteAudioLesson } from './site.js';
import type { YoutubeVideo } from './youtube.js';

const TRAILING_NUMBER = /([0-9٠-٩]+)\s*$/;

function trailingNumber(title: string): number | null {
  const digits = title.trim().match(TRAILING_NUMBER)?.[1];
  if (digits === undefined) return null;
  const western = digits.replace(/[٠-٩]/g, (d) =>
    String(d.charCodeAt(0) - 0x0660),
  );
  return Number.parseInt(western, 10);
}

/**
 * Some channel playlists are not in episode order, but every lesson title ends
 * with its episode number — that number is authoritative. Sorts one playlist's
 * videos by it when EVERY playable video has one; otherwise returns the input
 * order untouched (ties and numberless videos keep playlist order).
 */
export function sortByEpisodeNumber<T extends { title: string; playable?: boolean }>(
  videos: T[],
): T[] {
  const playable = videos.filter((v) => v.playable !== false);
  if (playable.length === 0 || playable.some((v) => trailingNumber(v.title) === null)) {
    return videos;
  }
  return videos
    .map((video, index) => ({ video, index, episode: trailingNumber(video.title) }))
    .sort(
      (a, b) =>
        (a.episode ?? Number.POSITIVE_INFINITY) - (b.episode ?? Number.POSITIVE_INFINITY) ||
        a.index - b.index,
    )
    .map((entry) => entry.video);
}

export interface MergeResult {
  lessons: StoredLesson[];
  added: string[];
  updated: string[];
  markedUnavailable: string[];
}

/**
 * Merges freshly-synced playlist videos with the previously stored lessons.
 *
 * Rules (seeds > YouTube):
 * - `overrides.exclude_videos` are dropped entirely
 * - `overrides.title_cleanup` regex is stripped from titles
 * - playlist order (across the seed's playlists, in seed order) defines positions
 * - lessons that vanished from the playlist are NEVER deleted — they keep
 *   their identity, move to the end, and get status 'unavailable'
 *   (user progress may reference them)
 * - previously 'hidden' lessons keep that status (manual curation decision)
 */
export function mergeLessons(
  seed: SeriesSeed,
  previous: StoredLesson[],
  videosInOrder: YoutubeVideo[],
): MergeResult {
  const excluded = new Set(seed.overrides.exclude_videos);
  const cleanup = seed.overrides.title_cleanup ? new RegExp(seed.overrides.title_cleanup) : null;
  const previousById = new Map(previous.map((l) => [l.youtube_video_id, l]));

  const added: string[] = [];
  const updated: string[] = [];
  const markedUnavailable: string[] = [];
  const next: StoredLesson[] = [];
  const seen = new Set<string>();

  for (const video of videosInOrder) {
    if (excluded.has(video.videoId) || seen.has(video.videoId)) continue;
    seen.add(video.videoId);

    const old = previousById.get(video.videoId);
    const cleanTitle = (cleanup ? video.title.replace(cleanup, '') : video.title).trim();
    const lesson: StoredLesson = {
      youtube_video_id: video.videoId,
      position: next.length + 1,
      // A deleted video reports a useless title — keep the one we knew.
      title_ar: video.playable ? cleanTitle : (old?.title_ar ?? cleanTitle),
      duration_seconds: video.durationSeconds ?? old?.duration_seconds ?? null,
      published_at: video.publishedAt ?? old?.published_at ?? null,
      thumbnail_url: video.thumbnailUrl ?? old?.thumbnail_url ?? null,
      status: old?.status === 'hidden' ? 'hidden' : video.playable ? 'active' : 'unavailable',
    };
    next.push(lesson);

    if (!old) {
      added.push(video.videoId);
    } else if (
      old.title_ar !== lesson.title_ar ||
      old.duration_seconds !== lesson.duration_seconds ||
      old.published_at !== lesson.published_at ||
      old.status !== lesson.status ||
      old.position !== lesson.position
    ) {
      updated.push(video.videoId);
      if (old.status !== 'unavailable' && lesson.status === 'unavailable') {
        markedUnavailable.push(video.videoId);
      }
    }
  }

  // Vanished lessons: keep them, at the end, unavailable.
  for (const old of previous) {
    if (seen.has(old.youtube_video_id) || excluded.has(old.youtube_video_id)) continue;
    const lesson: StoredLesson = {
      ...old,
      position: next.length + 1,
      status: old.status === 'hidden' ? 'hidden' : 'unavailable',
    };
    next.push(lesson);
    if (old.status !== lesson.status) {
      updated.push(old.youtube_video_id);
      markedUnavailable.push(old.youtube_video_id);
    }
  }

  return { lessons: next, added, updated, markedUnavailable };
}

/**
 * Audio counterpart of [mergeLessons] — same rules (seed overrides win,
 * order defines positions, vanished lessons become 'unavailable' at the end,
 * manual 'hidden' survives), for lessons synced from the foundation's site.
 */
export function mergeAudioLessons(
  seed: SeriesSeed,
  previous: StoredLesson[],
  lessonsInOrder: SiteAudioLesson[],
  durations: Map<string, number | null>,
  playability?: Map<string, boolean>,
): MergeResult {
  const excluded = new Set(seed.overrides.exclude_videos);
  const cleanup = seed.overrides.title_cleanup ? new RegExp(seed.overrides.title_cleanup) : null;
  const previousById = new Map(previous.map((l) => [l.youtube_video_id, l]));

  const added: string[] = [];
  const updated: string[] = [];
  const markedUnavailable: string[] = [];
  const next: StoredLesson[] = [];
  const seen = new Set<string>();

  for (const audio of lessonsInOrder) {
    if (excluded.has(audio.siteId) || seen.has(audio.siteId)) continue;
    seen.add(audio.siteId);

    const old = previousById.get(audio.siteId);
    const cleanTitle = (cleanup ? audio.title.replace(cleanup, '') : audio.title).trim();
    const playable = playability?.get(audio.siteId) !== false;
    const lesson: StoredLesson = {
      youtube_video_id: audio.siteId,
      position: next.length + 1,
      title_ar: cleanTitle,
      duration_seconds: durations.get(audio.siteId) ?? old?.duration_seconds ?? null,
      published_at: audio.publishedAt ?? old?.published_at ?? null,
      thumbnail_url: null,
      status: old?.status === 'hidden' ? 'hidden' : playable ? 'active' : 'unavailable',
      media: 'audio',
      audio_url: audio.audioUrl,
      chapters: audio.chapters.map((c) => ({
        start_seconds: c.startSeconds,
        title: c.title,
        body: c.body,
      })),
    };
    next.push(lesson);

    if (!old) {
      added.push(audio.siteId);
    } else if (
      old.title_ar !== lesson.title_ar ||
      old.duration_seconds !== lesson.duration_seconds ||
      old.published_at !== lesson.published_at ||
      old.audio_url !== lesson.audio_url ||
      old.status !== lesson.status ||
      old.position !== lesson.position ||
      JSON.stringify(old.chapters ?? []) !== JSON.stringify(lesson.chapters)
    ) {
      updated.push(audio.siteId);
      if (old.status !== 'unavailable' && lesson.status === 'unavailable') {
        markedUnavailable.push(audio.siteId);
      }
    }
  }

  for (const old of previous) {
    if (seen.has(old.youtube_video_id) || excluded.has(old.youtube_video_id)) continue;
    const lesson: StoredLesson = {
      ...old,
      position: next.length + 1,
      status: old.status === 'hidden' ? 'hidden' : 'unavailable',
    };
    next.push(lesson);
    if (old.status !== lesson.status) {
      updated.push(old.youtube_video_id);
      markedUnavailable.push(old.youtube_video_id);
    }
  }

  return { lessons: next, added, updated, markedUnavailable };
}
