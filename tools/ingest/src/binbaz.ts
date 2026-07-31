/**
 * Adapter for binbaz.org.sa — the second scholar's audio library.
 *
 * Unlike the Ibn Uthaymeen foundation, this site publishes no JSON API: it is
 * server-rendered Laravel, so this scrapes HTML. It implements the same
 * `SiteClient` interface, which is why nothing downstream changes — the sync
 * command, the merge and the idempotency contract are shared.
 *
 * The routes (verified against the live site):
 *
 *   GET /audios/series/{id}/{anything}
 *     → 15 lessons per page inside `<article class="box__body__element audio">`.
 *       The slug segment is decorative FOR PAGE 1 ONLY: the router resolves the
 *       series by id, but the paginator is built from the canonical URL, so
 *       `?page=2` on a placeholder slug silently re-serves page 1. Seeds
 *       therefore carry only the id — which cannot rot when a title is edited —
 *       and the client reads the canonical URL out of page 1 before paging.
 *
 *   GET /audios/{id}/{anything}
 *     → `<h1>` title, `<audio src>` pointing at files.zadapps.info, and the
 *       full transcript in `.original-text`.
 *
 * Two things this source does NOT provide, and their consequences:
 *   - No duration. Callers must probe the MP3 (`probeMp3` already does this).
 *   - No timestamps of any kind, so the transcript carries no markers. Chapters
 *     come back empty and read-along times can only come from forced alignment.
 */

import type { SiteAudioLesson, SiteClient } from './site.js';
import { stripHtml } from './site.js';

export const BINBAZ_SITE = 'https://binbaz.org.sa';

/** Lessons per page in the site's own pagination. */
const PAGE_SIZE = 15;

/** Guard against an unbounded crawl if pagination ever stops terminating. */
const MAX_PAGES = 60;

type TextFetch = (url: string) => Promise<{ ok: boolean; status: number; text(): Promise<string> }>;

export interface BinbazLessonLink {
  id: string;
  title: string;
}

/**
 * Lesson titles lead with their number — «01 باب كتاب التوحيد» — where the
 * YouTube pipeline's `sortByEpisodeNumber` expects it to trail. That helper
 * therefore no-ops here (it bails when any title lacks a trailing number), so
 * ordering is this adapter's job.
 */
export function leadingNumber(title: string): number | null {
  const match = /^\s*(\d{1,4})\b/.exec(title);
  return match ? Number(match[1]) : null;
}

/** Lesson links from one series page, in document order. */
export function parseSeriesPage(html: string): BinbazLessonLink[] {
  const lessons: BinbazLessonLink[] = [];
  const blocks = html.split('<article class="box__body__element audio">').slice(1);

  for (const block of blocks) {
    const anchor = /<a\s+href="[^"]*\/audios\/(\d+)\/[^"]*"[^>]*>([\s\S]*?)<\/a>/.exec(block);
    if (!anchor) continue;
    const title = stripHtml(anchor[2] ?? '');
    if (!title) continue;
    lessons.push({ id: anchor[1] ?? '', title });
  }

  return lessons;
}

/**
 * The page's own canonical URL. Needed because the paginator only advances on
 * the real slug — see the note at the top of this file.
 */
export function parseCanonicalUrl(html: string): string | null {
  const link = /<link\s+rel="canonical"\s+href="([^"]+)"/i.exec(html);
  return link ? (link[1] ?? null) : null;
}

export interface BinbazLessonPage {
  title: string;
  audioUrl: string | null;
  /** Plain-text transcript, paragraphs joined; '' when the page carries none. */
  transcript: string;
}

export function parseLessonPage(html: string): BinbazLessonPage {
  const audio = /<audio[^>]*\ssrc="([^"]+\.mp3)"/i.exec(html);
  const heading = /<h1[^>]*>([\s\S]*?)<\/h1>/.exec(html);

  // The transcript is `<p dir="RTL">` paragraphs inside `.original-text`. Take
  // everything from that div to the utility block the template closes with;
  // paragraph breaks become newlines so the sentence splitter keeps them.
  let transcript = '';
  const start = html.indexOf('class="original-text"');
  if (start !== -1) {
    const rest = html.slice(start);
    const end = rest.indexOf('utility__internal-border-top');
    const body = end === -1 ? rest : rest.slice(0, end);
    transcript = [...body.matchAll(/<p[^>]*>([\s\S]*?)<\/p>/gi)]
      .map((match) => stripHtml(match[1] ?? ''))
      .filter((part) => part.length > 0)
      .join('\n')
      .trim();
  }

  return {
    title: heading ? stripHtml(heading[1] ?? '') : '',
    audioUrl: audio ? encodeURI(audio[1] ?? '') : null,
    transcript,
  };
}

export function createBinbazClient(
  fetchFn: TextFetch = fetch as unknown as TextFetch,
): SiteClient {
  async function getHtml(url: string): Promise<string> {
    const response = await fetchFn(url);
    if (!response.ok) {
      throw new Error(`binbaz.org.sa request failed (${response.status}): ${url}`);
    }
    return response.text();
  }

  return {
    async fetchSectionLessons(seriesId: string): Promise<SiteAudioLesson[]> {
      // Page 1 under a placeholder slug, purely to learn the canonical URL —
      // paging on the placeholder would silently re-serve page 1 forever and
      // sync a 75-lesson series as 15.
      const firstUrl = `${BINBAZ_SITE}/audios/series/${seriesId}/x`;
      const firstHtml = await getHtml(firstUrl);
      const canonical = parseCanonicalUrl(firstHtml) ?? firstUrl;

      // Stop when a page adds nothing new rather than trusting a page count:
      // the pagination markup is a plain list of `?page=` links with no total,
      // and a short last page is normal. The identity check is also the
      // backstop if the canonical URL ever stops advancing again.
      const links = new Map<string, string>();
      for (const link of parseSeriesPage(firstHtml)) links.set(link.id, link.title);

      if (links.size >= PAGE_SIZE) {
        for (let page = 2; page <= MAX_PAGES; page++) {
          const found = parseSeriesPage(await getHtml(`${canonical}?page=${page}`));
          const before = links.size;
          for (const link of found) links.set(link.id, link.title);
          if (links.size === before || found.length < PAGE_SIZE) break;
        }
      }

      const ordered = [...links.entries()]
        .map(([id, title], index) => ({ id, title, index, episode: leadingNumber(title) }))
        .sort(
          (a, b) =>
            (a.episode ?? Number.POSITIVE_INFINITY) - (b.episode ?? Number.POSITIVE_INFINITY) ||
            a.index - b.index,
        );

      const lessons: SiteAudioLesson[] = [];
      for (const entry of ordered) {
        const page = await getHtml(`${BINBAZ_SITE}/audios/${entry.id}/x`);
        const parsed = parseLessonPage(page);
        // No audio = nothing to play; skip rather than ship a dead lesson.
        if (!parsed.audioUrl) continue;
        lessons.push({
          siteId: `binbaz-${entry.id}`,
          title: parsed.title || entry.title,
          audioUrl: parsed.audioUrl,
          // The site timestamps nothing, so there are no markers to carry.
          // `build:texts` takes the transcript from `transcriptText` instead.
          chapters: [],
          publishedAt: null,
          transcriptText: parsed.transcript || null,
        });
      }

      return lessons;
    },
  };
}
