import type { StoredLesson } from './store.js';

/**
 * Turns a lesson's scraped chapters into a read-along script: sections with a
 * real timestamp, each holding sentences with an *estimated* one.
 *
 * The site only ever gives marker-level timing (`mat-parts`: a title + a clock
 * offset), so per-sentence times cannot be measured — only interpolated between
 * markers. That's deliberate and bounded: every section boundary is exact, so
 * the app's highlight snaps back to the truth several times per lesson and
 * drift never accumulates across one. Swapping in forced-alignment timings
 * later means filling in better `t` values; the shape below doesn't change.
 */

export type LessonTextKind = 'transcript' | 'matn';

export interface TextSentence {
  /** Estimated start, seconds. Absent on matn text (the speech isn't in it). */
  t?: number;
  s: string;
}

export interface TextSection {
  /** Real marker timestamp, seconds. */
  start: number | null;
  title: string;
  sentences: TextSentence[];
}

export interface LessonText {
  lesson: string;
  kind: LessonTextKind;
  duration: number | null;
  sections: TextSection[];
}

/** Below this, a body is a marker label rather than prose worth sectioning. */
const SUBSTANTIAL_BODY_CHARS = 200;
/** Longer sentences get re-split at «،» — a whole screen of unbroken text
 * highlights as one blob and reads as if nothing is happening. */
const MAX_SENTENCE_CHARS = 220;
/** Shorter marker titles match too loosely to trust as anchors. */
const MIN_ANCHOR_CHARS = 12;
const ANCHOR_KEY_CHARS = 40;
/** Measured speech density is 7.6–9.0 chars/s; anything outside this is a
 * false match (the sheikh re-quotes the matn, so titles recur). */
const MIN_RATE = 3;
const MAX_RATE = 20;
/** Transcripts run ~8 chars/s, matn indexes ~0.1 — no lesson lands between. */
const TRANSCRIPT_DENSITY = 3;

/**
 * Match-only form: diacritics, tatweel and punctuation dropped, and the letter
 * variants that the site spells inconsistently folded together. Never shown.
 */
export function normalizeArabic(text: string): string {
  return (text ?? '')
    .replace(/[ً-ْٰـ]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .replace(/[^ء-ي]/g, '');
}

/** Normalized text plus, per surviving character, its index in the original —
 * matching happens on the normalized form but the cuts land in the original. */
function normalizeWithMap(text: string): { norm: string; map: number[] } {
  const out: string[] = [];
  const map: number[] = [];
  for (let i = 0; i < text.length; i++) {
    const normalized = normalizeArabic(text[i]!);
    if (!normalized) continue;
    out.push(normalized);
    map.push(i);
  }
  return { norm: out.join(''), map };
}

export function splitSentences(text: string, maxChars = MAX_SENTENCE_CHARS): string[] {
  const sentences: string[] = [];
  for (const chunk of (text ?? '').split(/(?<=[.؟!])\s+|\n+/)) {
    const trimmed = chunk.trim();
    if (!trimmed) continue;
    if (trimmed.length <= maxChars) {
      sentences.push(trimmed);
      continue;
    }
    let buffer = '';
    for (const part of trimmed.split(/(?<=،)\s*/)) {
      if (buffer && (buffer + part).length > maxChars) {
        sentences.push(buffer.trim());
        buffer = part;
      } else {
        buffer += part;
      }
    }
    if (buffer.trim()) sentences.push(buffer.trim());
  }
  return sentences;
}

/** null = no usable text at all (114 of the 500 audio lessons). */
export function classifyLesson(lesson: StoredLesson): LessonTextKind | null {
  const chapters = lesson.chapters ?? [];
  const chars = chapters.reduce((sum, c) => sum + (c.body ?? '').length, 0);
  if (chars === 0) return null;
  const duration = lesson.duration_seconds ?? 0;
  if (duration <= 0) return 'matn';
  return chars / duration >= TRANSCRIPT_DENSITY ? 'transcript' : 'matn';
}

/** Spreads [start, end] across sentences by character count. */
export function timeSentences(sentences: string[], start: number, end: number): TextSentence[] {
  const total = sentences.reduce((sum, s) => sum + Math.max(s.length, 1), 0);
  if (!Number.isFinite(start) || !Number.isFinite(end) || end <= start || total === 0) {
    return sentences.map((s) => ({ s }));
  }
  const span = end - start;
  let consumed = 0;
  return sentences.map((s) => {
    const t = Math.round(start + (span * consumed) / total);
    consumed += Math.max(s.length, 1);
    return { t, s };
  });
}

interface Anchor {
  charOffset: number;
  seconds: number;
  title: string;
}

/**
 * Locates each marker title inside a single-blob transcript. The search is
 * forward-constrained (resumes past the previous hit) and rate-checked, so a
 * later re-quote of the same matn can't drag the timeline backwards; markers
 * that don't match cleanly are dropped rather than guessed at.
 */
export function anchorMarkers(
  transcript: string,
  markers: { start_seconds: number | null; title: string }[],
  firstSeconds: number,
): Anchor[] {
  const { norm, map } = normalizeWithMap(transcript);
  const anchors: Anchor[] = [];
  let searchFrom = 0;
  let lastOffset = 0;
  let lastSeconds = firstSeconds;

  for (const marker of markers) {
    const seconds = marker.start_seconds;
    if (seconds == null || seconds <= lastSeconds) continue;

    const key = normalizeArabic(marker.title).slice(0, ANCHOR_KEY_CHARS);
    if (key.length < MIN_ANCHOR_CHARS) continue;

    const found = norm.indexOf(key, searchFrom);
    if (found < 0) continue;

    const charOffset = map[found]!;
    const rate = (charOffset - lastOffset) / (seconds - lastSeconds);
    if (rate < MIN_RATE || rate > MAX_RATE) continue;

    anchors.push({ charOffset, seconds, title: marker.title });
    searchFrom = found + key.length;
    lastOffset = charOffset;
    lastSeconds = seconds;
  }

  return anchors;
}

function sectionsFromChapters(
  chapters: NonNullable<StoredLesson['chapters']>,
  duration: number | null,
): TextSection[] {
  const ordered = [...chapters].sort((a, b) => (a.start_seconds ?? 0) - (b.start_seconds ?? 0));
  const sections: TextSection[] = [];

  for (const [index, chapter] of ordered.entries()) {
    const sentences = splitSentences(chapter.body ?? '');
    const start = chapter.start_seconds;
    const end = ordered[index + 1]?.start_seconds ?? duration;
    sections.push({
      start: start ?? null,
      title: chapter.title ?? '',
      sentences:
        start == null || end == null ? sentences.map((s) => ({ s })) : timeSentences(sentences, start, end),
    });
  }

  return sections;
}

function sectionsFromBlob(
  transcript: string,
  transcriptStart: number,
  markers: { start_seconds: number | null; title: string }[],
  duration: number | null,
): TextSection[] {
  const anchors = anchorMarkers(transcript, markers, transcriptStart);
  const cuts: Anchor[] = [{ charOffset: 0, seconds: transcriptStart, title: '' }, ...anchors];
  const sections: TextSection[] = [];

  for (const [index, cut] of cuts.entries()) {
    const next = cuts[index + 1];
    const slice = transcript.slice(cut.charOffset, next?.charOffset ?? transcript.length);
    const sentences = splitSentences(slice);
    if (sentences.length === 0) continue;
    const end = next?.seconds ?? duration;
    sections.push({
      start: cut.seconds,
      title: cut.title,
      sentences: end == null ? sentences.map((s) => ({ s })) : timeSentences(sentences, cut.seconds, end),
    });
  }

  return sections;
}

/** null when the lesson carries no text worth showing. */
export function buildLessonText(lesson: StoredLesson): LessonText | null {
  const kind = classifyLesson(lesson);
  if (kind === null) return null;

  const chapters = (lesson.chapters ?? []).filter((c) => (c.title ?? '') || (c.body ?? ''));
  const duration = lesson.duration_seconds ?? null;

  let sections: TextSection[];
  if (kind === 'matn') {
    // The speech isn't in this text, so nothing below section level can be
    // timed — the chapters' own timestamps are the whole story.
    sections = chapters.map((c) => ({
      start: c.start_seconds ?? null,
      title: c.title ?? '',
      sentences: splitSentences(c.body ?? '').map((s) => ({ s })),
    }));
  } else {
    const substantial = chapters.filter(
      (c) => (c.body ?? '').length >= SUBSTANTIAL_BODY_CHARS && c.start_seconds != null,
    );
    if (substantial.length >= 2) {
      // Already segmented upstream: each chapter is its own timed slice.
      sections = sectionsFromChapters(substantial, duration);
    } else {
      // One blob holds the whole transcript; the rest are matn markers to
      // anchor it against.
      const blob = chapters.reduce((a, b) => ((b.body ?? '').length > (a.body ?? '').length ? b : a));
      sections = sectionsFromBlob(
        blob.body ?? '',
        blob.start_seconds ?? 0,
        chapters.filter((c) => c !== blob),
        duration,
      );
    }
  }

  sections = sections.filter((s) => s.sentences.length > 0);
  if (sections.length === 0) return null;

  return { lesson: lesson.youtube_video_id, kind, duration, sections };
}
