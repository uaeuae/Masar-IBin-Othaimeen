/**
 * Minimal client for the foundation's site API (shekhapi.binothaimeen.net) —
 * the audio library that backs the app's audio series. Endpoints discovered
 * from the official site's JS bundle (documented in docs/CURATION.md):
 *
 *   GET {api}/course/sections/audio_library/many_lessons/{sectionId}/{pageSize}?page={n}
 *     → paginated lessons of a section; each carries the MP3 path in
 *       `certificate_url` (sic) and a chaptered study text in
 *       `objective.content.ar`.
 *
 * MP3 files live on https://sounds.binothaimeen.net with byte-range support.
 */

export const SITE_API = 'https://shekhapi.binothaimeen.net';
export const SOUND_HOST = 'https://sounds.binothaimeen.net';

export interface SiteAudioChapter {
  /** Offset within the audio, seconds; null when the marker had no time. */
  startSeconds: number | null;
  title: string;
  /** Plain-text body (the hadith/matn passages under the marker). */
  body: string;
}

export interface SiteAudioLesson {
  siteId: string;
  title: string;
  /** Absolute, URL-encoded MP3 URL. */
  audioUrl: string;
  chapters: SiteAudioChapter[];
  publishedAt: string | null;
}

type FetchLike = (url: string) => Promise<{ ok: boolean; status: number; json(): Promise<unknown> }>;

interface LessonsPage {
  data?: Array<{
    id?: string;
    title?: { ar?: string };
    objective?: { content?: { ar?: string | null } };
    certificate_url?: string | null;
    created_at?: string | null;
  }>;
  meta?: { last_page?: number };
}

/** "01:02:30" or "08:09" → seconds; null for anything unparsable. */
export function parseClockTime(value: string): number | null {
  const match = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(value.trim());
  if (!match) return null;
  const a = Number(match[1] ?? 0);
  const b = Number(match[2] ?? 0);
  const c = match[3];
  return c !== undefined ? a * 3600 + b * 60 + Number(c) : a * 60 + b;
}

/**
 * The site reports dates as "dd-mm-yyyy"; the catalog (and the app's
 * DateTime.parse) want ISO 8601. Unparsable input becomes null.
 */
export function normalizeSiteDate(value: string | null | undefined): string | null {
  if (!value) return null;
  const match = /^(\d{2})-(\d{2})-(\d{4})$/.exec(value.trim());
  if (match) return `${match[3]}-${match[2]}-${match[1]}T00:00:00.000Z`;
  const timestamp = Date.parse(value);
  return Number.isNaN(timestamp) ? null : new Date(timestamp).toISOString();
}

/**
 * The API's media paths are inconsistent: usually rooted ("/storage/…"),
 * occasionally missing the leading slash, rarely already absolute.
 */
export function toAudioUrl(certificateUrl: string): string {
  const raw = certificateUrl.trim();
  if (/^https?:\/\//.test(raw)) return encodeURI(raw);
  return encodeURI(`${SOUND_HOST}${raw.startsWith('/') ? '' : '/'}${raw}`);
}

function stripHtml(html: string): string {
  return html
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#0?39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * Parses the site's chaptered lesson text: `.mat-parts` blocks hold a marker
 * title + clock offset, and the passages between blocks belong to the marker
 * above them. Regex-based on purpose — the markup is machine-generated and
 * flat, and a DOM dependency would be heavier than the format deserves.
 */
export function parseChapters(html: string | null | undefined): SiteAudioChapter[] {
  if (!html) return [];

  const parts = html.split(/<div class="mat-parts">/).slice(1);
  const chapters: SiteAudioChapter[] = [];

  for (const part of parts) {
    const titleMatch = /<div class="mat-parts-title"[^>]*>([\s\S]*?)<\/div>/.exec(part);
    const timeMatch = /<div class="mat-parts-time"[^>]*>([\s\S]*?)<\/div>/.exec(part);
    if (!titleMatch) continue;

    // Body = everything after the block's outer closing </div> (the block is
    // title div + optional time div + one wrapping close).
    const lastInner = timeMatch ?? titleMatch;
    const anchor = lastInner.index + lastInner[0].length;
    const outerClose = part.indexOf('</div>', anchor);
    const bodyHtml = outerClose === -1 ? '' : part.slice(outerClose + '</div>'.length);

    chapters.push({
      startSeconds: timeMatch ? parseClockTime(stripHtml(timeMatch[1] ?? '')) : null,
      title: stripHtml(titleMatch[1] ?? ''),
      body: stripHtml(bodyHtml),
    });
  }

  return chapters;
}

/**
 * Estimates an MP3's duration from its first bytes + total size.
 * Handles a leading ID3v2 tag, then reads the first MPEG frame header for
 * the bitrate (CBR assumption — the foundation's files are CBR lecture
 * recordings). Returns null when the bytes don't look like MP3.
 */
export function estimateMp3DurationSeconds(head: Uint8Array, totalBytes: number): number | null {
  let offset = 0;

  // ID3v2 header: "ID3" + version(2) + flags(1) + syncsafe size(4).
  if (head.length >= 10 && head[0] === 0x49 && head[1] === 0x44 && head[2] === 0x33) {
    const size =
      (((head[6] ?? 0) & 0x7f) << 21) |
      (((head[7] ?? 0) & 0x7f) << 14) |
      (((head[8] ?? 0) & 0x7f) << 7) |
      ((head[9] ?? 0) & 0x7f);
    offset = 10 + size;
  }

  // Find the frame sync within what we have.
  while (offset + 4 <= head.length) {
    if (head[offset] === 0xff && ((head[offset + 1] ?? 0) & 0xe0) === 0xe0) break;
    offset++;
  }
  if (offset + 4 > head.length) return null;

  const b1 = head[offset + 1] ?? 0;
  const b2 = head[offset + 2] ?? 0;
  const versionBits = (b1 >> 3) & 0x03; // 3 = MPEG1, 2 = MPEG2, 0 = MPEG2.5
  const layerBits = (b1 >> 1) & 0x03; // 1 = Layer III
  const bitrateIndex = (b2 >> 4) & 0x0f;
  if (layerBits !== 1 || bitrateIndex === 0 || bitrateIndex === 0x0f) return null;

  const kbpsTable =
    versionBits === 3
      ? [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320] // MPEG1 L3
      : [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160]; // MPEG2/2.5 L3
  const kbps = kbpsTable[bitrateIndex];
  if (!kbps) return null;

  const audioBytes = Math.max(0, totalBytes - offset);
  return Math.round((audioBytes * 8) / (kbps * 1000));
}

export interface SiteClient {
  /** All audio lessons of a section, across pages, in the API's order. */
  fetchSectionLessons(sectionId: string): Promise<SiteAudioLesson[]>;
}

export function createSiteClient(fetchFn: FetchLike = fetch as unknown as FetchLike): SiteClient {
  async function getJson<T>(url: string): Promise<T> {
    const response = await fetchFn(url);
    if (!response.ok) {
      throw new Error(`Site API request failed (${response.status}): ${url}`);
    }
    return (await response.json()) as T;
  }

  return {
    async fetchSectionLessons(sectionId: string): Promise<SiteAudioLesson[]> {
      const lessons: SiteAudioLesson[] = [];
      let page = 1;
      let lastPage = 1;

      do {
        const url = `${SITE_API}/course/sections/audio_library/many_lessons/${sectionId}/50?page=${page}`;
        const body = await getJson<LessonsPage>(url);
        lastPage = body.meta?.last_page ?? 1;

        for (const item of body.data ?? []) {
          if (!item.id || !item.certificate_url) continue;
          lessons.push({
            siteId: item.id,
            title: item.title?.ar ?? '',
            audioUrl: toAudioUrl(item.certificate_url),
            chapters: parseChapters(item.objective?.content?.ar),
            publishedAt: normalizeSiteDate(item.created_at),
          });
        }
        page++;
      } while (page <= lastPage);

      return lessons;
    },
  };
}
