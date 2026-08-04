"""Forced alignment of lesson transcripts to the foundation's audio.

Why this exists: the site timestamps only «mat-parts» markers, and the median
lesson has a ~34 minute stretch between them. Interpolating sentence times across
that drifts by minutes, which is useless for reading along. This measures where
each sentence is actually spoken.

A wav2vec2 CTC model with an Arabic character vocabulary gives frame-level
emissions; torchaudio's forced_align finds the most likely monotonic mapping of
our known transcript onto those frames. That is alignment, not recognition — the
text is given, so the model only has to place it.

The trap, learned the hard way: forced alignment MUST fit every token into the
frames it is handed, and it cannot report that the fit was absurd. Hand a window
more text than it contains and the result silently compresses (measured 2.7x
fast); hand it less and the text is free to stretch, and the over-advance
compounds into the next window. So windows are not guessed — each section is
aligned inside the audio its own markers bound, which is ground truth, and error
cannot escape the section it happened in.

A section too long for one trellis, or a source that publishes no markers at all
(binbaz.org.sa), has no such bounds to work with. Those are re-bounded against
the audio first — see find_anchors — and only walked blind where the recording
decodes too poorly to anchor.

Usage:
  python align_lessons.py --data-dir ../ingest/data --texts-dir ../../app/assets/texts
Add --limit N for a trial, --series SLUG to restrict, --force to redo.
Times are written back into data/series/*.json as `sentence_times`, so the run is
resumable and `npm run build:texts` picks them up.
"""

from __future__ import annotations

import argparse
import bisect
import gzip
import json
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

import torch
import torchaudio.functional as AF
from transformers import Wav2Vec2CTCTokenizer, Wav2Vec2ForCTC

SAMPLE_RATE = 16_000
# wav2vec2 emits one frame per 20 ms.
FRAMES_PER_SECOND = 50.0
MODEL_ID = "jonatasgrosman/wav2vec2-large-xlsr-53-arabic"

# Audio per forward pass. 30 s at 16 kHz is comfortable on an 11 GB card and
# keeps boundary effects negligible once the overlap is discarded.
CHUNK_SECONDS = 30.0
CHUNK_OVERLAP_SECONDS = 1.0

# The alignment trellis is frames x tokens, so a 20 minute section will not fit
# in memory; anything longer than this gets sub-divided.
MAX_SEGMENT_SECONDS = 300.0
# Within a sub-divided section: how much of each sub-window to trust before
# resuming from the last sentence it placed.
WINDOW_TRUST = 0.6

# --- Anchors read off the audio, for sources that publish no markers ---
#
# A section with real marker bounds cannot drift far, because error is trapped
# between two known times. A source with no markers at all (binbaz.org.sa) hands
# the whole lesson over as one segment, and the sub-window walk above then has
# nothing to re-anchor against — each window's over- or under-advance is carried
# into the next for an hour.
#
# So anchors are recovered from the audio instead: greedy-decode the segment,
# match what was recognised against the transcript, and every unambiguous
# agreement is a place where we know what is being said and when. Those become
# segment bounds, which puts a marker-less source back into the case the aligner
# was built for.
#
# Matching is done on CHARACTERS, not words. Word matching needs the decode to
# agree about where words end, and on this material it does not — «كل أمة» is
# recognised as the single token «قلكلمه». It cost a 91-minute lesson all but 8
# of its anchors, every one of them in the first third, leaving the 50 minutes
# after minute 40 to be walked blind. That is where a reader reported the
# highlight coming apart, and the characters were there the whole time.
#
#: Seed length in characters. A seed has to occur exactly once on each side —
#: that is what makes a match unambiguous without any scoring — so it cannot be
#: short. Measured on the reference lesson, by anchors found and by the worst
#: span left unanchored: 10 -> 1,170 seeds / 3.8 min, 12 -> 770 / 6.5 min,
#: 14 -> 489 / 21.8 min, 18 -> 189 / 26.5 min.
ANCHOR_NGRAM = 10
# A seed rarely lands on a sentence's first character. When it lands further in,
# the sentence's start is dated from the seed's own time — an approximation that
# only stays honest over a short backoff, so a seed deep inside a sentence is
# discarded rather than extrapolated back.
#: Characters, not words: the stream this indexes into has no spaces in it.
ANCHOR_BACKOFF_CHARS = 60
# Boundaries are pulled this much earlier than measured. Forced alignment cannot
# place a token before the window starts, so a boundary that is slightly late
# clips the sentence it opens, while one that is slightly early costs nothing.
ANCHOR_MARGIN_SECONDS = 0.25
# An anchor implying a speech rate outside this band of the segment's own average
# is a mis-match, not a fast passage. Both failures the windowing can produce
# show up here: far too much text between two anchors, or far too little.
ANCHOR_RATE_BAND = (0.3, 3.0)
# Anchors closer together than this are not worth a separate segment; the first
# one already bounds the error well enough.
ANCHOR_MIN_SPACING_SECONDS = 1.0
#: How many times a span may be re-anchored inside its own pieces.
#:
#: One pass used to be the rule, on the reasoning that the match is exhaustive
#: so there is nothing left to find. That holds only for the stream it was
#: given, and a narrower window is a different problem: seeds must be unique on
#: each side, so a repeated phrase that is ambiguous across a whole lesson can
#: be the only occurrence inside one of its pieces, and the rate band is
#: recomputed from the piece rather than the lesson. Each level is nearly free —
#: `decode_words` is an argmax over emissions already in memory, and the n-gram
#: index is over a shorter stream than its parent's.
MAX_ANCHOR_DEPTH = 3


def normalise(text: str) -> str:
    """Match-only form, mirroring normalizeArabic in tools/ingest/src/text-align.ts."""
    text = unicodedata.normalize("NFKC", text)
    text = re.sub(r"[ً-ْٰـ]", "", text)
    text = re.sub(r"[أإآٱ]", "ا", text)
    return text.replace("ى", "ي").replace("ة", "ه")


@dataclass
class Sentence:
    index: int
    text: str
    tokens: list[int]


class Aligner:
    def __init__(self, device: str) -> None:
        self.device = device
        self.tokenizer = Wav2Vec2CTCTokenizer.from_pretrained(MODEL_ID)
        self.model = Wav2Vec2ForCTC.from_pretrained(MODEL_ID).to(device).eval()
        self.vocab = dict(self.tokenizer.get_vocab())
        self.blank = self.vocab.get("<pad>", 0)
        self.word_delimiter = self.vocab.get("|")

    def encode(self, text: str) -> list[int]:
        """Characters the model knows; anything else (digits, punctuation) is
        dropped, since it is not pronounced as a distinct sound."""
        out: list[int] = []
        for char in normalise(text):
            if char == " ":
                if self.word_delimiter is not None and (
                    not out or out[-1] != self.word_delimiter
                ):
                    out.append(self.word_delimiter)
                continue
            token = self.vocab.get(char)
            if token is not None:
                out.append(token)
        return out

    @torch.inference_mode()
    def emissions(self, waveform: torch.Tensor) -> torch.Tensor:
        """Frame-wise log-probabilities for a whole lesson, chunked so each
        forward pass fits in VRAM, with the overlap trimmed to hide the seams."""
        step = int((CHUNK_SECONDS - CHUNK_OVERLAP_SECONDS) * SAMPLE_RATE)
        chunk = int(CHUNK_SECONDS * SAMPLE_RATE)
        trim = int(CHUNK_OVERLAP_SECONDS * FRAMES_PER_SECOND / 2)

        pieces: list[torch.Tensor] = []
        for start in range(0, waveform.shape[-1], step):
            audio = waveform[..., start : start + chunk]
            if audio.shape[-1] < SAMPLE_RATE // 2:
                break
            logits = self.model(audio.to(self.device)).logits[0]
            probs = torch.log_softmax(logits.float(), dim=-1).cpu()
            head = 0 if start == 0 else trim
            tail = (
                probs.shape[0]
                if start + chunk >= waveform.shape[-1]
                else probs.shape[0] - trim
            )
            pieces.append(probs[head:tail])
        return torch.cat(pieces, dim=0) if pieces else torch.zeros(0, 1)

    @torch.inference_mode()
    def decode_words(self, emission: torch.Tensor) -> list[tuple[str, int]]:
        """Greedy CTC over a window: each recognised word and the frame it starts.

        This is recognition, not alignment — what the model actually heard, with
        no transcript to constrain it. Note the model's vocabulary includes
        tashkeel, so it decodes fully diacritised text («قَوْمٌ» for «قوم»); both
        sides go through normalise() before anything is compared, or nothing
        matches at all.
        """
        if not hasattr(self, "_inverse"):
            self._inverse = {v: k for k, v in self.vocab.items()}
        words: list[tuple[str, int]] = []
        current, start = "", 0
        previous = None
        for frame, token in enumerate(emission.argmax(dim=-1).tolist()):
            if token != previous and token != self.blank:
                char = self._inverse.get(token, "")
                if char == "|":
                    if current:
                        words.append((current, start))
                    current = ""
                elif char:
                    if not current:
                        start = frame
                    current += char
            previous = token
        if current:
            words.append((current, start))
        out: list[tuple[str, int]] = []
        for word, frame in words:
            clean = "".join(c for c in normalise(word) if c.isalpha())
            if clean:
                out.append((clean, frame))
        return out

    def align_window(
        self, emission: torch.Tensor, tokens: list[int]
    ) -> list[int] | None:
        """Frame index for each token, or None when this window can't hold them."""
        if not tokens or emission.shape[0] < len(tokens):
            return None
        targets = torch.tensor([tokens], dtype=torch.int32)
        try:
            paths, scores = AF.forced_align(
                emission.unsqueeze(0), targets, blank=self.blank
            )
        except (RuntimeError, ValueError):
            return None
        # merge_tokens collapses each token's run of frames into one span, in
        # target order — doing that by hand mis-handles repeated letters.
        spans = AF.merge_tokens(paths[0], scores[0])
        if len(spans) != len(tokens):
            return None
        return [span.start for span in spans]


def load_audio(url_or_path: str) -> torch.Tensor:
    """Decode straight to 16 kHz mono through ffmpeg — no need to keep 10 GB of
    MP3s on disk just to read their timing."""
    command = [
        "ffmpeg", "-nostdin", "-loglevel", "error",
        "-i", url_or_path,
        "-f", "f32le", "-ac", "1", "-ar", str(SAMPLE_RATE), "-",
    ]
    raw = subprocess.run(command, capture_output=True, check=False).stdout
    if not raw:
        raise RuntimeError("ffmpeg produced no audio")
    return torch.frombuffer(bytearray(raw), dtype=torch.float32).unsqueeze(0)


def read_script(lesson: dict, texts_dir: Path, aligner: Aligner) -> dict | None:
    """The lesson's read-along script exactly as build-texts emitted it: sections
    with their real marker times, sentences carrying their flat index.

    Read from the built asset rather than re-split here, because a second
    implementation of splitSentences would be free to drift from the TypeScript
    one and silently shift every index.
    """
    asset = texts_dir / f"{lesson['youtube_video_id']}.json.gz"
    if not asset.exists():
        return None
    with gzip.open(asset, "rt", encoding="utf-8") as handle:
        raw = json.load(handle)
    if raw.get("kind") != "transcript":
        return None

    sections = []
    index = 0
    count = 0
    for section in raw.get("sections", []):
        items: list[Sentence] = []
        for sentence in section.get("sentences", []):
            text = sentence.get("s", "")
            tokens = aligner.encode(text)
            if tokens:
                items.append(Sentence(index=index, text=text, tokens=tokens))
            index += 1
            count += 1
        sections.append({"start": section.get("start"), "sentences": items})
    return {"sections": sections, "count": count} if count else None


def find_anchors(
    aligner: Aligner,
    emission: torch.Tensor,
    sentences: list[Sentence],
    start_seconds: float,
    end_seconds: float,
) -> list[tuple[int, float]]:
    """Segment bounds recovered from the audio, for a section no markers bound.

    Greedy-decodes the window and matches what was recognised against the
    transcript **as characters, not words**.

    Word-level matching was tried first and quietly fails on the material this
    library is made of. It needs the decode to agree with the transcript about
    where words *end*, and a model listening to recitation and connected speech
    does not: «كل أمة» comes back as one token, «قلكلمه». One 91-minute lesson
    yielded 8 anchors, all in its first third, and every one of the 50 minutes
    after minute 40 went unmatched — which is precisely where a reader reported
    the highlight coming apart. The characters are all there; only the spaces
    are wrong. Dropping to a character stream found 1,170 seeds across the same
    lesson and cut its worst unanchored span from 58 minutes to 6.5.

    Seeds are n-grams occurring exactly **once on each side**, so a match is
    unambiguous without any scoring, and the chain through them is a longest
    increasing subsequence — monotonic by construction, which is what a segment
    bound requires.

    Returns (position in `sentences`, seconds) pairs, increasing in both.
    """
    first = int(start_seconds * FRAMES_PER_SECOND)
    last = min(int(end_seconds * FRAMES_PER_SECOND), emission.shape[0])
    if last - first < 2:
        return []
    heard = aligner.decode_words(emission[first:last])
    if not heard:
        return []

    # Audio side: one character stream, each character carrying the frame of
    # the word it came from.
    audio_chars: list[str] = []
    audio_frame: list[int] = []
    for word, frame in heard:
        for char in word:
            audio_chars.append(char)
            audio_frame.append(frame)

    # Text side: the same, each character carrying the sentence it belongs to
    # and how far into that sentence it sits — so a match can be turned back
    # into a sentence *start* rather than a position in the middle of one.
    text_chars: list[str] = []
    origin: list[tuple[int, int]] = []
    for position, sentence in enumerate(sentences):
        offset = 0
        for raw in normalise(sentence.text).split():
            for char in "".join(c for c in raw if c.isalpha()):
                text_chars.append(char)
                origin.append((position, offset))
                offset += 1
    if len(audio_chars) < ANCHOR_NGRAM or len(text_chars) < ANCHOR_NGRAM:
        return []

    audio = "".join(audio_chars)
    text = "".join(text_chars)

    audio_at: dict[str, list[int]] = {}
    for i in range(len(audio) - ANCHOR_NGRAM + 1):
        audio_at.setdefault(audio[i : i + ANCHOR_NGRAM], []).append(i)
    text_at: dict[str, list[int]] = {}
    for i in range(len(text) - ANCHOR_NGRAM + 1):
        text_at.setdefault(text[i : i + ANCHOR_NGRAM], []).append(i)

    seeds = sorted(
        (positions[0], audio_at[gram][0])
        for gram, positions in text_at.items()
        if len(positions) == 1 and len(audio_at.get(gram, ())) == 1
    )
    if not seeds:
        return []

    # Longest increasing subsequence over the audio index: the seeds are already
    # sorted by text position, so this keeps the largest subset that also
    # advances through the audio, and drops any that would go backwards.
    tails: list[int] = []
    tail_audio: list[int] = []
    previous = [-1] * len(seeds)
    for i, (_, audio_index) in enumerate(seeds):
        slot = bisect.bisect_left(tail_audio, audio_index)
        previous[i] = tails[slot - 1] if slot else -1
        if slot == len(tails):
            tails.append(i)
            tail_audio.append(audio_index)
        else:
            tails[slot] = i
            tail_audio[slot] = audio_index
    chain: list[tuple[int, int]] = []
    cursor = tails[-1] if tails else -1
    while cursor != -1:
        chain.append(seeds[cursor])
        cursor = previous[cursor]
    chain.reverse()

    # Each sentence keeps the seed that landed closest to its own first
    # character, since that needs the least extrapolation back.
    best: dict[int, tuple[int, float]] = {}
    for text_index, audio_index in chain:
        position, offset = origin[text_index]
        if offset > ANCHOR_BACKOFF_CHARS:
            continue
        seconds = (first + audio_frame[audio_index]) / FRAMES_PER_SECOND
        if offset:
            seconds -= ANCHOR_MARGIN_SECONDS
        existing = best.get(position)
        if existing is None or offset < existing[0]:
            best[position] = (offset, seconds)

    # Keep only a chain that advances through both the text and the audio at a
    # rate this section could actually have been spoken at.
    span = max(end_seconds - start_seconds, 1.0)
    rate = max(sum(len(s.tokens) for s in sentences) / span, 1.0)
    low, high = ANCHOR_RATE_BAND

    anchors: list[tuple[int, float]] = []
    mark, clock = 0, start_seconds
    for position in sorted(best):
        if position <= mark:
            continue
        seconds = best[position][1]
        if seconds <= clock + ANCHOR_MIN_SPACING_SECONDS or seconds >= end_seconds:
            continue
        tokens = sum(len(s.tokens) for s in sentences[mark:position])
        implied = tokens / (seconds - clock)
        if not low * rate <= implied <= high * rate:
            continue
        anchors.append((position, seconds))
        mark, clock = position, seconds
    return anchors


@dataclass
class Coverage:
    """How well a lesson could be *bounded* — which is not what `measured` says.

    Every sentence the aligner touches gets a number, including the ones it
    walked blind across an hour of audio; counting them says nothing about
    whether they are right. What separates a trustworthy lesson from a drifting
    one is whether every span it placed was bounded at both ends — by a real
    marker, by an audio-derived anchor, or by being short enough for one
    trellis. So record the spans that were not.
    """

    anchors: int = 0
    #: Lengths, in seconds, of the spans that had to be walked blind.
    unbounded: list[float] = None  # type: ignore[assignment]

    def __post_init__(self) -> None:
        if self.unbounded is None:
            self.unbounded = []

    @property
    def worst_unbounded(self) -> float:
        return max(self.unbounded, default=0.0)


def align_segment(
    aligner: Aligner,
    emission: torch.Tensor,
    sentences: list[Sentence],
    start_seconds: float,
    end_seconds: float,
    times: dict[int, float],
    coverage: Coverage,
    depth: int = 0,
) -> None:
    """Places one section's sentences inside the audio its markers bound."""
    if not sentences:
        return

    first = int(start_seconds * FRAMES_PER_SECOND)
    last = min(int(end_seconds * FRAMES_PER_SECOND), emission.shape[0])
    if last - first < len(sentences):
        return

    tokens: list[int] = []
    offsets: list[int] = []
    for sentence in sentences:
        offsets.append(len(tokens))
        tokens.extend(sentence.tokens)

    # Short enough for one trellis: exact, and error cannot propagate at all.
    window = emission[first:last]
    if (end_seconds - start_seconds) <= MAX_SEGMENT_SECONDS and len(
        tokens
    ) <= window.shape[0] * 0.9:
        frames = aligner.align_window(window, tokens)
        if frames is not None:
            for sentence, offset in zip(sentences, offsets):
                times[sentence.index] = (first + frames[offset]) / FRAMES_PER_SECOND
            return

    # Too long for one trellis, and (for a marker-less source) with no real
    # bounds to trap the error. Recover bounds from the audio and recurse, which
    # puts each piece back into the short, bounded case above.
    #
    # Each piece is re-anchored in turn rather than only the parent, up to
    # MAX_ANCHOR_DEPTH: a gap left by the parent's pass is its own span, with its
    # own speech rate, and anchors the parent rejected can be found inside it.
    # Termination is by construction — find_anchors returns positions strictly
    # inside (mark, len) and times strictly inside (clock, end), so every child
    # is shorter than its parent in both text and audio — with the depth cap as
    # a backstop.
    if depth < MAX_ANCHOR_DEPTH:
        anchors = find_anchors(
            aligner, emission, sentences, start_seconds, end_seconds
        )
        if anchors:
            coverage.anchors += len(anchors)
            mark, clock = 0, start_seconds
            for position, seconds in [*anchors, (len(sentences), end_seconds)]:
                align_segment(
                    aligner,
                    emission,
                    sentences[mark:position],
                    clock,
                    seconds,
                    times,
                    coverage,
                    depth=depth + 1,
                )
                mark, clock = position, seconds
            return

    # Long section with no anchors to be had: walk it, trusting the front of
    # each sub-window and resuming from the last sentence placed. The text slice
    # is sized from this section's own measured density, so it neither
    # compresses nor stretches.
    #
    # Sizing each window from the greedy decode's local character count instead
    # — a real speech-rate signal rather than a section-wide average — was tried
    # and measured no better (gap +0.114 against +0.113 over 96 sentences), so
    # the simpler rule stays.
    span = max(end_seconds - start_seconds, 1.0)
    # The one path whose output cannot be trusted, so it is the one worth
    # recording: everything placed from here on is carried on the previous
    # window's error. Measured at 135 s off at the median and up to 690 s.
    coverage.unbounded.append(span)
    tokens_per_second = max(sum(len(s.tokens) for s in sentences) / span, 1.0)
    sub_frames = int(MAX_SEGMENT_SECONDS * FRAMES_PER_SECOND)
    cursor = first
    index = 0
    while index < len(sentences) and cursor < last:
        window = emission[cursor : min(cursor + sub_frames, last)]
        if window.shape[0] < 2:
            break
        budget = int((window.shape[0] / FRAMES_PER_SECOND) * tokens_per_second)
        budget = min(budget, int(window.shape[0] * 0.9))

        chunk_tokens: list[int] = []
        chunk_offsets: list[int] = []
        chunk: list[Sentence] = []
        for sentence in sentences[index:]:
            if chunk_tokens and len(chunk_tokens) + len(sentence.tokens) > budget:
                break
            chunk_offsets.append(len(chunk_tokens))
            chunk_tokens.extend(sentence.tokens)
            chunk.append(sentence)
        if not chunk_tokens:
            break

        frames = aligner.align_window(window, chunk_tokens)
        if frames is None:
            cursor += sub_frames // 2
            continue

        is_final = cursor + sub_frames >= last
        trusted = window.shape[0] * (1.0 if is_final else WINDOW_TRUST)
        placed = 0
        furthest = 0
        for sentence, offset in zip(chunk, chunk_offsets):
            frame = frames[offset]
            if frame > trusted:
                break
            times[sentence.index] = (cursor + frame) / FRAMES_PER_SECOND
            furthest = frame
            placed += 1
        if placed == 0:
            cursor += sub_frames // 2
            continue
        index += placed
        cursor += max(furthest, 1)


def align_lesson(
    lesson: dict, aligner: Aligner, texts_dir: Path, log
) -> tuple[dict[int, float], Coverage] | None:
    url = lesson.get("audio_url")
    if not url:
        return None
    script = read_script(lesson, texts_dir, aligner)
    if not script:
        return None

    log("  decoding audio…")
    waveform = load_audio(url)
    total_seconds = waveform.shape[-1] / SAMPLE_RATE
    duration = float(lesson.get("duration_seconds") or 0) or total_seconds

    log(f"  running the model over {total_seconds / 60:.0f} min…")
    emission = aligner.emissions(waveform)
    if emission.shape[0] == 0:
        return None

    times: dict[int, float] = {}
    coverage = Coverage()
    sections = script["sections"]
    for position, section in enumerate(sections):
        start = section["start"]
        if start is None:
            continue
        following = next(
            (s["start"] for s in sections[position + 1 :] if s["start"] is not None),
            None,
        )
        end = float(
            following if following is not None else min(duration, total_seconds)
        )
        if end <= start:
            continue
        align_segment(
            aligner, emission, section["sentences"], float(start), end, times, coverage
        )

    worst = coverage.worst_unbounded
    log(
        f"  placed {len(times)}/{script['count']} sentences"
        f" · {coverage.anchors} anchors"
        + (
            f" · WALKED BLIND across {worst / 60:.0f} min — not trustworthy"
            if worst > MAX_SEGMENT_SECONDS
            else " · fully bounded"
        )
    )
    return times, coverage


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True, type=Path)
    parser.add_argument("--texts-dir", required=True, type=Path)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--series", action="append")
    parser.add_argument("--force", action="store_true")
    parser.add_argument(
        "--device", default="cuda" if torch.cuda.is_available() else "cpu"
    )
    args = parser.parse_args()

    def log(message: str) -> None:
        print(message, flush=True)

    log(f"device: {args.device}")
    if args.device == "cuda":
        log(f"gpu: {torch.cuda.get_device_name(0)}")
    aligner = Aligner(args.device)

    files = sorted((args.data_dir / "series").glob("*.json"))
    if args.series:
        files = [f for f in files if f.stem in args.series]

    done = 0
    for path in files:
        lessons = json.loads(path.read_text(encoding="utf-8"))
        dirty = False
        for lesson in lessons:
            if args.limit is not None and done >= args.limit:
                break
            if lesson.get("status") != "active" or not lesson.get("audio_url"):
                continue
            if lesson.get("sentence_times") and not args.force:
                continue
            # Chapters used to be the gate, because the foundation's text only
            # exists inside them. A source that publishes a flat transcript
            # (binbaz.org.sa) has none, and needs alignment more, not less —
            # with no markers there is nothing to interpolate from either.
            if not lesson.get("chapters") and not lesson.get("transcript_text"):
                continue

            log(f"{path.stem} #{lesson['position']}")
            try:
                result = align_lesson(lesson, aligner, args.texts_dir, log)
            except Exception as error:  # noqa: BLE001 — one bad lesson must not stop the run
                log(f"  ! failed: {error}")
                continue
            if not result or not result[0]:
                continue
            times, coverage = result
            lesson["sentence_times"] = {
                str(k): round(v, 2) for k, v in sorted(times.items())
            }
            # Travels with the times so `build:texts` can tell the app whether
            # to trust them. Without it the app can only count sentences that
            # got a number, which is true of a drifting lesson too.
            lesson["alignment"] = {
                "anchors": coverage.anchors,
                "unbounded_seconds": round(coverage.worst_unbounded, 1),
            }
            dirty = True
            done += 1
            # Written as we go: this is a long job and must be resumable.
            path.write_text(
                json.dumps(lessons, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        if dirty:
            log(f"{path.stem}: saved")
        if args.limit is not None and done >= args.limit:
            break

    log(f"aligned {done} lesson(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
