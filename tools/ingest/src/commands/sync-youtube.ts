import { loadSeeds } from '../seeds.js';
import { mergeLessons } from '../merge.js';
import { readStoredLessons, writeStoredLessons } from '../store.js';
import type { YoutubeClient, YoutubeVideo } from '../youtube.js';

export interface SyncOptions {
  seedDir: string;
  dataDir: string;
  client: YoutubeClient;
  dryRun: boolean;
  log?: (line: string) => void;
}

/**
 * Pulls every seeded playlist and merges it into the content store.
 * Idempotent: running twice with the same remote state changes nothing.
 */
export async function syncYoutube(options: SyncOptions): Promise<{ changedSeries: string[] }> {
  const log = options.log ?? console.log;
  const { series } = loadSeeds(options.seedDir);
  const changedSeries: string[] = [];

  for (const seed of series) {
    if (seed.youtube_playlists.length === 0) {
      log(`- ${seed.slug}: no playlists configured, skipping`);
      continue;
    }

    const videos: YoutubeVideo[] = [];
    for (const playlistId of seed.youtube_playlists) {
      videos.push(...(await options.client.fetchPlaylistVideos(playlistId)));
    }

    const previous = readStoredLessons(options.dataDir, seed.slug);
    const result = mergeLessons(seed, previous, videos);

    const changed =
      result.added.length > 0 ||
      result.updated.length > 0 ||
      result.lessons.length !== previous.length;

    log(
      `- ${seed.slug}: ${result.lessons.length} lessons ` +
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
