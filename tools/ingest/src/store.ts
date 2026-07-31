import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

/**
 * The synced content store: one JSON file per series under data/series/,
 * committed to git. Seeds own curation; this store owns synced metadata.
 */

export interface StoredChapter {
  start_seconds: number | null;
  title: string;
  body: string;
}

export interface StoredLesson {
  /** External id: YouTube video id for video lessons, site lesson uuid for audio. */
  youtube_video_id: string;
  position: number;
  title_ar: string;
  duration_seconds: number | null;
  published_at: string | null;
  thumbnail_url: string | null;
  status: 'active' | 'hidden' | 'unavailable';
  /** Absent/'video' = YouTube lesson; 'audio' = foundation-hosted MP3. */
  media?: 'video' | 'audio';
  audio_url?: string | null;
  /**
   * Integrated loudness in LUFS (EBU R128), measured by `analyze:loudness`.
   * The uploads' levels wander by 8+ dB within a single series, so the player
   * needs this per lesson to even them out.
   */
  loudness_lufs?: number | null;
  /**
   * Measured sentence start times in seconds, keyed by the sentence's index in
   * the lesson's read-along script — produced by `tools/align` forced
   * alignment. Present only for lessons that have been aligned; the rest fall
   * back to interpolation between markers, which drifts.
   */
  sentence_times?: Record<string, number> | null;
  chapters?: StoredChapter[];
  /**
   * Flat lesson transcript, for sources that publish the text without markers
   * (binbaz.org.sa). Chaptered sources leave this unset and carry their text in
   * `chapters`. Never exported to the catalog — like chapter bodies, it is
   * megabytes of prose that only `build:texts` reads.
   */
  transcript_text?: string | null;
}

export function readStoredLessons(dataDir: string, seriesSlug: string): StoredLesson[] {
  const file = join(dataDir, 'series', `${seriesSlug}.json`);
  if (!existsSync(file)) return [];
  return JSON.parse(readFileSync(file, 'utf8')) as StoredLesson[];
}

export function writeStoredLessons(dataDir: string, seriesSlug: string, lessons: StoredLesson[]): void {
  mkdirSync(join(dataDir, 'series'), { recursive: true });
  writeFileSync(join(dataDir, 'series', `${seriesSlug}.json`), JSON.stringify(lessons, null, 2) + '\n');
}
