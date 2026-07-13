import type { SeriesSeed } from './schemas.js';
import type { StoredLesson } from './store.js';
import type { YoutubeVideo } from './youtube.js';

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
