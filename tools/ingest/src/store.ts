import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

/**
 * The synced content store: one JSON file per series under data/series/,
 * committed to git. Seeds own curation; this store owns synced metadata.
 */

export interface StoredLesson {
  youtube_video_id: string;
  position: number;
  title_ar: string;
  duration_seconds: number | null;
  published_at: string | null;
  thumbnail_url: string | null;
  status: 'active' | 'hidden' | 'unavailable';
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
