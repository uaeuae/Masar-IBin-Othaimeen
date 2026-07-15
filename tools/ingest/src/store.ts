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
  chapters?: StoredChapter[];
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
