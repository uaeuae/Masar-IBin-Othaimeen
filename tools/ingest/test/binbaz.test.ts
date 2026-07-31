import { describe, expect, it } from 'vitest';
import {
  createBinbazClient,
  leadingNumber,
  parseLessonPage,
  parseSeriesPage,
} from '../src/binbaz.js';

/** Trimmed from the live series page — the shape the parser depends on. */
function seriesPage(entries: Array<[string, string]>): string {
  return `<div class="box"><div class="box__body">
    ${entries
      .map(
        ([id, title]) => `<article class="box__body__element audio">
        <a href="https://binbaz.org.sa/audios/${id}/%D8%A8%D8%A7%D8%A8">
          <i class="box__body__element__bullet fa-sound"></i>
          ${title}
        </a>
        <p>مقتطف من الدرس</p>
      </article>`,
      )
      .join('\n')}
  </div></div>`;
}

/** The site slugs its own URLs in Arabic; the client only ever seeds the id. */
const CANONICAL = 'https://binbaz.org.sa/audios/series/83/%D8%B4%D8%B1%D8%AD';
const CANONICAL_LINK = `<link rel="canonical" href="${CANONICAL}"/>`;

const LESSON_PAGE = `<h1 class="article-title">01 باب كتاب التوحيد</h1>
<audio src="https://files.zadapps.info/binbaz.org.sa/sawtyaat/shar7_ketab_tawheed01.mp3" controls></audio>
<div itemprop="text" class="article-content"><div style="text-align: justify;"><div class="original-text">
<p dir="RTL">قال شيخ الإسلام محمد بن عبد الوهاب رحمه الله تعالى:</p>
<p dir="RTL"><strong>كتاب التوحيد</strong></p>
</div></div></div>
<div class="utility__internal-border-top"><p dir="RTL">روابط ذات صلة لا تخص التفريغ</p></div>`;

describe('parseSeriesPage', () => {
  it('reads lesson id and title from each article block', () => {
    const links = parseSeriesPage(seriesPage([['2016', '01 باب كتاب التوحيد'], ['2018', '04 باب من حقق التوحيد']]));
    expect(links).toEqual([
      { id: '2016', title: '01 باب كتاب التوحيد' },
      { id: '2018', title: '04 باب من حقق التوحيد' },
    ]);
  });

  it('returns nothing for a page with no lessons', () => {
    expect(parseSeriesPage('<div class="box__body"></div>')).toEqual([]);
  });
});

describe('parseLessonPage', () => {
  it('pulls the title, the mp3 and the transcript', () => {
    const page = parseLessonPage(LESSON_PAGE);
    expect(page.title).toBe('01 باب كتاب التوحيد');
    expect(page.audioUrl).toBe(
      'https://files.zadapps.info/binbaz.org.sa/sawtyaat/shar7_ketab_tawheed01.mp3',
    );
    expect(page.transcript).toBe(
      'قال شيخ الإسلام محمد بن عبد الوهاب رحمه الله تعالى:\nكتاب التوحيد',
    );
  });

  it('stops the transcript at the related-links block', () => {
    // Everything after `utility__internal-border-top` is site furniture; letting
    // it through would put navigation prose into the read-along text.
    expect(parseLessonPage(LESSON_PAGE).transcript).not.toContain('روابط ذات صلة');
  });

  it('survives a lesson with no audio and no transcript', () => {
    const page = parseLessonPage('<h1>درس بلا صوت</h1>');
    expect(page.audioUrl).toBeNull();
    expect(page.transcript).toBe('');
  });
});

describe('leadingNumber', () => {
  it('reads the number binbaz titles lead with', () => {
    // The YouTube pipeline's sorter looks for a TRAILING number and so bails
    // on every one of these — ordering has to happen in this adapter.
    expect(leadingNumber('01 باب كتاب التوحيد')).toBe(1);
    expect(leadingNumber('12 باب الشفاعة')).toBe(12);
    expect(leadingNumber('باب بلا رقم')).toBeNull();
  });
});

describe('createBinbazClient', () => {
  function fakeFetch(pages: Record<string, string>) {
    const calls: string[] = [];
    const fetchFn = async (url: string) => {
      calls.push(url);
      const body = pages[url];
      return {
        ok: body !== undefined,
        status: body === undefined ? 404 : 200,
        text: async () => body ?? '',
      };
    };
    return { fetchFn, calls };
  }

  it('crawls pages, orders by the leading number, and fetches each lesson', async () => {
    // Page 1 is full (the page size), so the client must ask for page 2 — and
    // must ask for it on the CANONICAL url, not the placeholder slug.
    const fullPage =
      CANONICAL_LINK +
      seriesPage(
        Array.from({ length: 15 }, (_, i) => [
          String(100 + i),
          `${String(i + 2).padStart(2, '0')} باب رقم ${i + 2}`,
        ]),
      );
    const pages: Record<string, string> = {
      'https://binbaz.org.sa/audios/series/83/x': fullPage,
      [`${CANONICAL}?page=2`]: seriesPage([['999', '01 الباب الأول']]),
    };
    for (const id of [...Array.from({ length: 15 }, (_, i) => String(100 + i)), '999']) {
      pages[`https://binbaz.org.sa/audios/${id}/x`] = LESSON_PAGE.replace(
        'shar7_ketab_tawheed01.mp3',
        `lesson${id}.mp3`,
      );
    }

    const { fetchFn } = fakeFetch(pages);
    const lessons = await createBinbazClient(fetchFn).fetchSectionLessons('83');

    expect(lessons).toHaveLength(16);
    // «01» was on the second page; it still sorts first.
    expect(lessons[0]?.siteId).toBe('binbaz-999');
    expect(lessons[0]?.audioUrl).toContain('lesson999.mp3');
    // Ids are namespaced so a binbaz lesson can never collide with a
    // foundation uuid or a YouTube video id in the same store.
    expect(lessons.every((l) => l.siteId.startsWith('binbaz-'))).toBe(true);
    // The source timestamps nothing, so there are no markers to carry.
    expect(lessons.every((l) => l.chapters.length === 0)).toBe(true);
    expect(lessons[0]?.transcriptText).toContain('كتاب التوحيد');
  });

  it('stops paging on a short page', async () => {
    const { fetchFn, calls } = fakeFetch({
      'https://binbaz.org.sa/audios/series/51/x': seriesPage([['1', '01 أ']]),
      'https://binbaz.org.sa/audios/1/x': LESSON_PAGE,
    });
    await createBinbazClient(fetchFn).fetchSectionLessons('51');
    expect(calls.filter((c) => c.includes('?page='))).toEqual([]);
  });

  it('pages on the canonical url, not the placeholder slug', async () => {
    // The trap this guards: the router resolves a series by id, so page 1
    // renders fine under any slug — but the paginator is built from the
    // canonical URL, so `?page=2` on the placeholder re-serves page 1. Left
    // unhandled, a 75-lesson series syncs as 15 and looks like a short series
    // rather than a bug.
    const full =
      CANONICAL_LINK +
      seriesPage(Array.from({ length: 15 }, (_, i) => [String(200 + i), `${i + 1} باب`]));
    const pages: Record<string, string> = {
      'https://binbaz.org.sa/audios/series/83/x': full,
      // Deliberately NOT registered: `.../83/x?page=2`. Requesting it 404s,
      // so this test fails loudly if the client ever pages the wrong URL.
      [`${CANONICAL}?page=2`]: seriesPage([['300', '16 باب']]),
    };
    for (const id of [...Array.from({ length: 15 }, (_, i) => String(200 + i)), '300']) {
      pages[`https://binbaz.org.sa/audios/${id}/x`] = LESSON_PAGE;
    }

    const { fetchFn, calls } = fakeFetch(pages);
    const lessons = await createBinbazClient(fetchFn).fetchSectionLessons('83');

    expect(lessons).toHaveLength(16);
    expect(calls).toContain(`${CANONICAL}?page=2`);
  });

  it('skips a lesson whose page has no audio rather than shipping a dead row', async () => {
    const { fetchFn } = fakeFetch({
      'https://binbaz.org.sa/audios/series/9/x': seriesPage([
        ['1', '01 أ'],
        ['2', '02 ب'],
      ]),
      'https://binbaz.org.sa/audios/1/x': LESSON_PAGE,
      'https://binbaz.org.sa/audios/2/x': '<h1>02 ب</h1>',
    });
    const lessons = await createBinbazClient(fetchFn).fetchSectionLessons('9');
    expect(lessons.map((l) => l.siteId)).toEqual(['binbaz-1']);
  });

  it('throws on an unreachable page instead of silently syncing a short series', async () => {
    const { fetchFn } = fakeFetch({});
    await expect(createBinbazClient(fetchFn).fetchSectionLessons('83')).rejects.toThrow(/404/);
  });
});
