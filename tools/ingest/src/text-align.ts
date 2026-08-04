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
  /** Sentences whose time was measured by forced alignment, not estimated. */
  measured?: number;
  /**
   * Whether those times can actually be followed along to.
   *
   * Distinct from `measured`, and the distinction is the whole point: a lesson
   * walked blind across an hour of audio has a number on every sentence and is
   * still minutes wrong. `measured` counts sentences that got a value; this
   * says every value was bounded at both ends — by a marker, by an
   * audio-derived anchor, or by a span short enough to align in one piece.
   *
   * Absent means false. A lesson that is not synced still ships its text; the
   * app shows it as a reading page with no highlight, which is honest, rather
   * than highlighting a sentence that is not the one being spoken.
   */
  synced?: boolean;
  sections: TextSection[];
}

/** Below this, a body is a marker label rather than prose worth sectioning. */
const SUBSTANTIAL_BODY_CHARS = 200;
/** Longer sentences get re-split at «،» — a whole screen of unbroken text
 * highlights as one blob and reads as if nothing is happening. */
const MAX_SENTENCE_CHARS = 220;
/** Shorter marker titles match too loosely to trust as anchors. */
const MIN_ANCHOR_CHARS = 12;
/**
 * Prefix lengths tried when locating a marker, longest first. The sheikh reads
 * the matn back with interjections («قال المؤلف رحمه الله»), so demanding one
 * exact 40-character run threw away 56% of the timestamps the site gives us —
 * and every discarded marker widens the stretch that has to be interpolated.
 * Shorter keys match more loosely; the forward-only search and the rate check
 * below are what keep a loose match from being accepted.
 */
const ANCHOR_KEY_LENGTHS = [40, 28, 20, 14];
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
  // A flat transcript is by definition the speech, so it is never matn. Sources
  // that publish one (binbaz.org.sa) timestamp nothing, so every sentence time
  // has to come from forced alignment — there is nothing to interpolate from.
  if ((lesson.transcript_text ?? '').trim().length > 0) return 'transcript';

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

    const title = normalizeArabic(marker.title);
    if (title.length < MIN_ANCHOR_CHARS) continue;

    // Most specific prefix first, then progressively shorter ones.
    let found = -1;
    let matched = 0;
    for (const length of ANCHOR_KEY_LENGTHS) {
      const key = title.slice(0, Math.min(length, title.length));
      if (key.length < MIN_ANCHOR_CHARS) break;
      found = norm.indexOf(key, searchFrom);
      if (found >= 0) {
        matched = key.length;
        break;
      }
    }
    if (found < 0) continue;

    const charOffset = map[found]!;
    const rate = (charOffset - lastOffset) / (seconds - lastSeconds);
    if (rate < MIN_RATE || rate > MAX_RATE) continue;

    anchors.push({ charOffset, seconds, title: marker.title });
    searchFrom = found + matched;
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

  const flat = (lesson.transcript_text ?? '').trim();
  if (flat.length > 0) {
    // A marker-less source: one section spanning the lesson, and NO times.
    // Interpolating across a whole lesson drifts by minutes (DECISIONS.md 8),
    // so these sentences stay untimed until forced alignment fills them in —
    // an untimed script still reads, it just does not highlight.
    const flatSections: TextSection[] = [
      { start: 0, title: '', sentences: splitSentences(flat).map((s) => ({ s })) },
    ].filter((s) => s.sentences.length > 0);
    if (flatSections.length === 0) return null;
    const flatAligned = applyMeasuredTimes(flatSections, lesson.sentence_times);
    return {
      lesson: lesson.youtube_video_id,
      kind: 'transcript',
      duration,
      ...(flatAligned > 0 ? { measured: flatAligned } : {}),
      ...(isSynced(lesson, flatAligned) ? { synced: true } : {}),
      sections: flatSections,
    };
  }

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

  const aligned = applyMeasuredTimes(sections, lesson.sentence_times);

  return {
    lesson: lesson.youtube_video_id,
    kind,
    duration,
    // How many sentences carry a measured time — a coverage figure, and NOT a
    // statement that the highlight can be followed. `synced` is that statement.
    ...(aligned > 0 ? { measured: aligned } : {}),
    ...(isSynced(lesson, aligned) ? { synced: true } : {}),
    sections,
  };
}

/**
 * The longest span the aligner had to walk without bounds at both ends. Beyond
 * this, its own error compounds window over window — measured at 135 s off at
 * the median and up to 690 s (tools/align/README.md), which is the difference
 * between reading along and being lied to.
 *
 * Mirrors `MAX_SEGMENT_SECONDS` in align_lessons.py, where the same number
 * decides whether a span gets walked in the first place.
 */
const MAX_TRUSTED_UNBOUNDED_SECONDS = 300;

/**
 * Whether a lesson's times are good enough to follow along to.
 *
 * A lesson aligned before `alignment` was recorded has no coverage to read, and
 * is treated as unsynced rather than assumed good: that is exactly the
 * population — 376 of 386 assets — whose drift this whole change exists to fix,
 * so guessing in its favour would preserve the bug.
 */
function isSynced(lesson: StoredLesson, aligned: number): boolean {
  if (aligned <= 0) return false;
  const coverage = lesson.alignment;
  if (!coverage) return false;
  return (coverage.unbounded_seconds ?? Infinity) <= MAX_TRUSTED_UNBOUNDED_SECONDS;
}

/**
 * Overwrites interpolated sentence times with the ones forced alignment
 * measured. Returns how many sentences were replaced.
 *
 * Applied per sentence rather than all-or-nothing: a window the aligner could
 * not place keeps its estimate instead of losing its time entirely, and the
 * section's own marker start still bounds it.
 */
function applyMeasuredTimes(
  sections: TextSection[],
  times: Record<string, number> | null | undefined,
): number {
  if (!times) return 0;
  let index = 0;
  let applied = 0;
  let previous = -Infinity;
  for (const section of sections) {
    for (const sentence of section.sentences) {
      const measured = times[String(index)];
      index++;
      // Monotonic or nothing: a stray out-of-order value would make the
      // highlight jump backwards, which reads as a bug.
      if (typeof measured === 'number' && Number.isFinite(measured) && measured >= previous) {
        sentence.t = Math.round(measured * 10) / 10;
        previous = measured;
        applied++;
      } else if (sentence.t != null) {
        // A sentence the aligner skipped keeps its estimate — but that estimate
        // was interpolated against the old timeline and can easily land before
        // a measured neighbour, which would make the highlight jump backwards.
        if (Number.isFinite(previous) && sentence.t < previous) {
          sentence.t = Math.round(previous * 10) / 10;
        }
        previous = sentence.t;
      }
    }
  }
  return applied;
}
