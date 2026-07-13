import { describe, expect, it } from 'vitest';
import { createYoutubeClient, parseIso8601Duration } from '../src/youtube.js';

describe('parseIso8601Duration', () => {
  it('parses hour/minute/second combinations', () => {
    expect(parseIso8601Duration('PT45M')).toBe(2700);
    expect(parseIso8601Duration('PT1H2M30S')).toBe(3750);
    expect(parseIso8601Duration('PT58S')).toBe(58);
    expect(parseIso8601Duration('PT2H')).toBe(7200);
  });

  it('returns null for missing or malformed input', () => {
    expect(parseIso8601Duration(undefined)).toBeNull();
    expect(parseIso8601Duration('P1D')).toBeNull();
  });
});

describe('createYoutubeClient', () => {
  it('walks playlist pages and joins durations from the videos endpoint', async () => {
    const responses = new Map<string, unknown>();
    const playlistBase = 'playlistItems';
    const calls: string[] = [];

    const fetchFn = async (url: string) => {
      calls.push(url);
      for (const [needle, body] of responses) {
        if (url.includes(needle)) return { ok: true, status: 200, json: async () => body };
      }
      throw new Error(`unexpected url: ${url}`);
    };

    responses.set(`${playlistBase}?part=snippet,status&maxResults=50&playlistId=PLx&key=`, {
      nextPageToken: 'page2',
      items: [
        {
          snippet: { title: '01 - درس', resourceId: { videoId: 'vid1' }, publishedAt: '2020-01-01T00:00:00Z' },
          status: { privacyStatus: 'public' },
        },
        {
          snippet: { title: 'Private video', resourceId: { videoId: 'vid-private' } },
          status: { privacyStatus: 'private' },
        },
      ],
    });
    responses.set('pageToken=page2', {
      items: [
        {
          snippet: { title: '02 - درس آخر', resourceId: { videoId: 'vid2' } },
          status: { privacyStatus: 'public' },
        },
      ],
    });
    responses.set('videos?part=contentDetails', {
      items: [
        { id: 'vid1', contentDetails: { duration: 'PT45M' } },
        { id: 'vid2', contentDetails: { duration: 'PT1H' } },
      ],
    });

    const client = createYoutubeClient('KEY', fetchFn);
    const videos = await client.fetchPlaylistVideos('PLx');

    expect(videos.map((v) => [v.videoId, v.durationSeconds, v.playable])).toEqual([
      ['vid1', 2700, true],
      ['vid-private', null, false],
      ['vid2', 3600, true],
    ]);
    // 2 playlist pages + 1 videos page.
    expect(calls).toHaveLength(3);
  });

  it('throws a readable error with the api key redacted', async () => {
    const client = createYoutubeClient('SECRET', async () => ({
      ok: false,
      status: 403,
      json: async () => ({}),
    }));
    await expect(client.fetchPlaylistVideos('PLx')).rejects.toThrow(/403/);
    await expect(client.fetchPlaylistVideos('PLx')).rejects.not.toThrow(/SECRET/);
  });
});
