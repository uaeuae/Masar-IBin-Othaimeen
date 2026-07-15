import { describe, expect, it } from 'vitest';
import {
  createSiteClient,
  estimateMp3DurationSeconds,
  parseChapters,
  parseClockTime,
  toAudioUrl,
} from '../src/site.js';

describe('normalizeSiteDate', () => {
  it('converts the site dd-mm-yyyy format to ISO', async () => {
    const { normalizeSiteDate } = await import('../src/site.js');
    expect(normalizeSiteDate('05-04-2022')).toBe('2022-04-05T00:00:00.000Z');
    expect(normalizeSiteDate(null)).toBeNull();
    expect(normalizeSiteDate('garbage')).toBeNull();
  });
});

describe('toAudioUrl', () => {
  it('handles rooted, unrooted, and absolute media paths', () => {
    expect(toAudioUrl('/storage/a b.mp3')).toBe(
      'https://sounds.binothaimeen.net/storage/a%20b.mp3',
    );
    expect(toAudioUrl('sounds/x.mp3')).toBe('https://sounds.binothaimeen.net/sounds/x.mp3');
    expect(toAudioUrl('https://other.host/x.mp3')).toBe('https://other.host/x.mp3');
  });
});

describe('parseClockTime', () => {
  it('parses mm:ss and hh:mm:ss', () => {
    expect(parseClockTime('08:09')).toBe(489);
    expect(parseClockTime('00:00:54')).toBe(54);
    expect(parseClockTime('01:02:30')).toBe(3750);
  });

  it('returns null for junk', () => {
    expect(parseClockTime('')).toBeNull();
    expect(parseClockTime('abc')).toBeNull();
  });
});

describe('parseChapters', () => {
  const sample = `
<div class="mat-parts">
<div class="mat-parts-title"><span><strong>مقدمة : ( باب إخلاص النية )</strong></span></div>
<div class="mat-parts-time">00:00:54</div>
</div>
<p>قال الله تعالى : (وما أمروا إلا ليعبدوا الله)&nbsp;الآية.</p>
<div class="mat-parts">
<div class="mat-parts-title"><span><strong>الحديث الأول : ( إنما الأعمال بالنيات )</strong></span></div>
<div class="mat-parts-time">00:08:09</div>
</div>
<p>عن عمر بن الخطاب رضي الله عنه.</p>`;

  it('extracts titles, offsets, and passage bodies', () => {
    const chapters = parseChapters(sample);
    expect(chapters).toHaveLength(2);
    expect(chapters[0]?.title).toBe('مقدمة : ( باب إخلاص النية )');
    expect(chapters[0]?.startSeconds).toBe(54);
    expect(chapters[0]?.body).toContain('وما أمروا إلا ليعبدوا الله');
    expect(chapters[1]?.startSeconds).toBe(489);
    expect(chapters[1]?.body).toContain('عمر بن الخطاب');
  });

  it('is empty for null/blank content', () => {
    expect(parseChapters(null)).toEqual([]);
    expect(parseChapters('<p>نص بلا فصول</p>')).toEqual([]);
  });
});

describe('estimateMp3DurationSeconds', () => {
  function mp3Head(kbpsIndex: number, withId3 = false): Uint8Array {
    // MPEG1 Layer III frame header: FF FB (sync + v1 + L3), bitrate index high nibble.
    const frame = [0xff, 0xfb, (kbpsIndex << 4) | 0x00, 0x00];
    if (!withId3) return new Uint8Array([...frame, 0, 0, 0, 0, 0, 0]);
    // "ID3" v2.3, no flags, syncsafe size = 100 bytes of tag data.
    const id3 = [0x49, 0x44, 0x33, 3, 0, 0, 0, 0, 0, 100];
    return new Uint8Array([...id3, ...new Array(100).fill(0), ...frame, 0, 0]);
  }

  it('estimates CBR duration from bitrate and size', () => {
    // index 9 = 128 kbps (MPEG1 L3): 1,280,000 bytes → 80 seconds.
    expect(estimateMp3DurationSeconds(mp3Head(9), 1_280_000)).toBe(80);
  });

  it('skips a leading ID3v2 tag', () => {
    const total = 1_280_000 + 110;
    expect(estimateMp3DurationSeconds(mp3Head(9, true), total)).toBe(80);
  });

  it('returns null for non-MP3 bytes', () => {
    expect(estimateMp3DurationSeconds(new Uint8Array([1, 2, 3, 4, 5, 6]), 1000)).toBeNull();
  });
});

describe('createSiteClient', () => {
  it('walks pagination and builds absolute encoded audio URLs', async () => {
    const pages: Record<string, unknown> = {
      'page=1': {
        meta: { last_page: 2 },
        data: [
          {
            id: 'uuid-1',
            title: { ar: 'رياض الصالحين - 1' },
            objective: { content: { ar: null } },
            certificate_url: '/storage/uploads/uploadbin//x/riyadh 01.mp3',
            created_at: '05-04-2022',
          },
        ],
      },
      'page=2': {
        meta: { last_page: 2 },
        data: [
          {
            id: 'uuid-2',
            title: { ar: 'رياض الصالحين - 2' },
            objective: { content: { ar: '' } },
            certificate_url: '/storage/x/riyadh_02.mp3',
            created_at: null,
          },
          { id: 'no-audio', title: { ar: 'بلا ملف' }, certificate_url: null },
        ],
      },
    };
    const client = createSiteClient(async (url: string) => {
      const key = Object.keys(pages).find((k) => url.includes(k));
      if (!key) throw new Error(`unexpected url ${url}`);
      return { ok: true, status: 200, json: async () => pages[key] };
    });

    const lessons = await client.fetchSectionLessons('section-1');
    expect(lessons.map((l) => l.siteId)).toEqual(['uuid-1', 'uuid-2']);
    expect(lessons[0]?.audioUrl).toBe(
      'https://sounds.binothaimeen.net/storage/uploads/uploadbin//x/riyadh%2001.mp3',
    );
  });
});
