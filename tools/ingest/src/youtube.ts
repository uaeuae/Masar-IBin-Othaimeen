/** Minimal YouTube Data API v3 client (REST, injectable fetch for tests). */

export interface YoutubeVideo {
  videoId: string;
  title: string;
  durationSeconds: number | null;
  publishedAt: string | null;
  thumbnailUrl: string | null;
  /** false when the video is deleted/private (still occupies a playlist slot). */
  playable: boolean;
}

export interface YoutubePlaylistInfo {
  playlistId: string;
  title: string;
  itemCount: number;
}

export interface YoutubeClient {
  /** All videos of a playlist, in playlist order. */
  fetchPlaylistVideos(playlistId: string): Promise<YoutubeVideo[]>;
  /** Every public playlist of a channel, by @handle — used for curation. */
  fetchChannelPlaylists(handle: string): Promise<YoutubePlaylistInfo[]>;
}

type FetchLike = (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

const API = 'https://www.googleapis.com/youtube/v3';

/** "PT1H2M30S" → 3750. Returns null for missing/unparsable input. */
export function parseIso8601Duration(value: string | undefined): number | null {
  if (!value) return null;
  const match = /^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/.exec(value);
  if (!match) return null;
  const [, h, m, s] = match;
  return (Number(h ?? 0) * 3600) + (Number(m ?? 0) * 60) + Number(s ?? 0);
}

interface PlaylistItemsPage {
  nextPageToken?: string;
  items?: Array<{
    snippet?: {
      title?: string;
      publishedAt?: string;
      resourceId?: { videoId?: string };
      thumbnails?: { medium?: { url?: string } };
    };
    status?: { privacyStatus?: string };
  }>;
}

interface VideosPage {
  items?: Array<{
    id?: string;
    contentDetails?: { duration?: string };
    status?: { embeddable?: boolean };
  }>;
}

export function createYoutubeClient(apiKey: string, fetchFn: FetchLike = fetch as unknown as FetchLike): YoutubeClient {
  async function getJson<T>(url: string): Promise<T> {
    const response = await fetchFn(url);
    if (!response.ok) {
      throw new Error(`YouTube API request failed (${response.status}): ${url.replace(apiKey, '***')}`);
    }
    return (await response.json()) as T;
  }

  return {
    async fetchPlaylistVideos(playlistId: string): Promise<YoutubeVideo[]> {
      const videos: YoutubeVideo[] = [];
      let pageToken: string | undefined;

      do {
        const url =
          `${API}/playlistItems?part=snippet,status&maxResults=50&playlistId=${encodeURIComponent(playlistId)}` +
          `${pageToken ? `&pageToken=${pageToken}` : ''}&key=${apiKey}`;
        const page = await getJson<PlaylistItemsPage>(url);

        for (const item of page.items ?? []) {
          const videoId = item.snippet?.resourceId?.videoId;
          if (!videoId) continue;
          const title = item.snippet?.title ?? '';
          const privacy = item.status?.privacyStatus;
          const playable =
            privacy !== 'private' && title !== 'Deleted video' && title !== 'Private video';
          videos.push({
            videoId,
            title,
            durationSeconds: null,
            publishedAt: item.snippet?.publishedAt ?? null,
            thumbnailUrl: item.snippet?.thumbnails?.medium?.url ?? null,
            playable,
          });
        }
        pageToken = page.nextPageToken;
      } while (pageToken);

      // Durations + embeddability come from the videos endpoint, 50 ids per
      // call (1 unit each). The app plays via the iframe embed, so a video
      // with embedding disabled is as unplayable as a deleted one.
      const playableIds = videos.filter((v) => v.playable).map((v) => v.videoId);
      const durations = new Map<string, number | null>();
      const embeddable = new Map<string, boolean>();
      for (let i = 0; i < playableIds.length; i += 50) {
        const chunk = playableIds.slice(i, i + 50);
        const url = `${API}/videos?part=contentDetails,status&id=${chunk.join(',')}&key=${apiKey}`;
        const page = await getJson<VideosPage>(url);
        for (const item of page.items ?? []) {
          if (!item.id) continue;
          durations.set(item.id, parseIso8601Duration(item.contentDetails?.duration));
          embeddable.set(item.id, item.status?.embeddable !== false);
        }
      }

      return videos.map((v) => ({
        ...v,
        durationSeconds: durations.get(v.videoId) ?? null,
        // A video the videos endpoint no longer returns is gone even if the
        // playlist still lists it.
        playable: v.playable && durations.has(v.videoId) && embeddable.get(v.videoId) !== false,
      }));
    },

    async fetchChannelPlaylists(handle: string): Promise<YoutubePlaylistInfo[]> {
      const channelPage = await getJson<{ items?: Array<{ id?: string }> }>(
        `${API}/channels?part=id&forHandle=${encodeURIComponent(handle)}&key=${apiKey}`,
      );
      const channelId = channelPage.items?.[0]?.id;
      if (!channelId) throw new Error(`No channel found for handle "${handle}"`);

      const playlists: YoutubePlaylistInfo[] = [];
      let pageToken: string | undefined;
      do {
        const page = await getJson<{
          nextPageToken?: string;
          items?: Array<{ id?: string; snippet?: { title?: string }; contentDetails?: { itemCount?: number } }>;
        }>(
          `${API}/playlists?part=snippet,contentDetails&maxResults=50&channelId=${channelId}` +
            `${pageToken ? `&pageToken=${pageToken}` : ''}&key=${apiKey}`,
        );
        for (const item of page.items ?? []) {
          if (!item.id) continue;
          playlists.push({
            playlistId: item.id,
            title: item.snippet?.title ?? '',
            itemCount: item.contentDetails?.itemCount ?? 0,
          });
        }
        pageToken = page.nextPageToken;
      } while (pageToken);

      return playlists;
    },
  };
}
