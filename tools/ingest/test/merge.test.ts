import { describe, expect, it } from 'vitest';
import { mergeLessons } from '../src/merge.js';
import { seriesSeedSchema } from '../src/schemas.js';
import type { StoredLesson } from '../src/store.js';
import type { YoutubeVideo } from '../src/youtube.js';

const seed = seriesSeedSchema.parse({
  slug: 'sharh-test',
  title_ar: 'شرح تجريبي',
  science: 'fiqh',
  youtube_playlists: ['PLx'],
  overrides: {
    exclude_videos: ['skip-me'],
    title_cleanup: '^\\s*\\d+\\s*[-|/]\\s*',
  },
});

function video(id: string, title: string, opts: Partial<YoutubeVideo> = {}): YoutubeVideo {
  return {
    videoId: id,
    title,
    durationSeconds: 100,
    publishedAt: '2020-01-01T00:00:00Z',
    thumbnailUrl: null,
    playable: true,
    ...opts,
  };
}

function stored(id: string, position: number, opts: Partial<StoredLesson> = {}): StoredLesson {
  return {
    youtube_video_id: id,
    position,
    title_ar: `درس ${position}`,
    duration_seconds: 100,
    published_at: '2020-01-01T00:00:00Z',
    thumbnail_url: null,
    status: 'active',
    ...opts,
  };
}

describe('mergeLessons', () => {
  it('builds a fresh list with cleaned titles and playlist order', () => {
    const result = mergeLessons(seed, [], [video('a', '01 - مقدمة الشرح'), video('b', '02 | باب المياه')]);
    expect(result.lessons.map((l) => [l.youtube_video_id, l.position, l.title_ar])).toEqual([
      ['a', 1, 'مقدمة الشرح'],
      ['b', 2, 'باب المياه'],
    ]);
    expect(result.added).toEqual(['a', 'b']);
  });

  it('drops excluded videos and duplicate ids', () => {
    const result = mergeLessons(seed, [], [video('skip-me', 'مقطع دعائي'), video('a', 'درس'), video('a', 'درس مكرر')]);
    expect(result.lessons.map((l) => l.youtube_video_id)).toEqual(['a']);
  });

  it('is idempotent: same remote state → no changes reported', () => {
    const first = mergeLessons(seed, [], [video('a', 'درس أول'), video('b', 'درس ثان')]);
    const second = mergeLessons(seed, first.lessons, [video('a', 'درس أول'), video('b', 'درس ثان')]);
    expect(second.added).toEqual([]);
    expect(second.updated).toEqual([]);
    expect(second.lessons).toEqual(first.lessons);
  });

  it('vanished lessons move to the end as unavailable, never deleted', () => {
    const previous = [stored('a', 1), stored('gone', 2), stored('b', 3)];
    const result = mergeLessons(seed, previous, [video('a', 'درس 1'), video('b', 'درس 2')]);

    expect(result.lessons.map((l) => [l.youtube_video_id, l.position, l.status])).toEqual([
      ['a', 1, 'active'],
      ['b', 2, 'active'],
      ['gone', 3, 'unavailable'],
    ]);
    expect(result.markedUnavailable).toEqual(['gone']);
  });

  it('deleted-in-place videos keep their known title and become unavailable', () => {
    const previous = [stored('a', 1, { title_ar: 'العنوان الأصلي' })];
    const result = mergeLessons(seed, previous, [video('a', 'Deleted video', { playable: false, durationSeconds: null })]);
    expect(result.lessons[0]).toMatchObject({
      youtube_video_id: 'a',
      title_ar: 'العنوان الأصلي',
      duration_seconds: 100, // kept from the old record
      status: 'unavailable',
    });
  });

  it('manually hidden lessons stay hidden across syncs', () => {
    const previous = [stored('a', 1, { status: 'hidden' })];
    const result = mergeLessons(seed, previous, [video('a', 'درس')]);
    expect(result.lessons[0]?.status).toBe('hidden');
  });
});
