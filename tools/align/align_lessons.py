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
import difflib
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
# match the recognised words against the transcript's, and every long run of
# agreement is a place where we know what is being said and when. Those become
# segment bounds, which puts a marker-less source back into the case the aligner
# was built for.
#
# A run this long is required before a match is trusted. Arabic religious prose
# repeats short formulas constantly — «صلى الله عليه وسلم» is four words on its
# own — so shorter runs match the wrong instance; raising it costs anchors and
# lengthens the unbounded stretches between them. Measured on binbaz, paired
# over 96 sentences (validate_decode gap): 3 -> +0.068, 4 -> +0.109,
# 5 -> +0.113. Three is worse than doing nothing at all (+0.069).
ANCHOR_WORDS = 5
# The anchor rarely lands on a sentence's first word. When it lands a few words
# in, the sentence's start is estimated by stepping back that many words in the
# recognised text. That extrapolation assumes the two word streams run 1:1 over
# the step, which only holds for a short one — allowing 16 buys more anchors and
# measures worse for it (+0.099 against +0.113).
ANCHOR_BACKOFF_WORDS = 8
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

    Greedy-decodes the window and matches the recognised words against the
    transcript's. difflib's matching blocks are a longest-common-subsequence, so
    they are monotonic by construction — a run of agreement cannot be matched to
    an earlier moment than the run before it, which is exactly the property a
    segment bound needs.

    Returns (position in `sentences`, seconds) pairs, increasing in both.
    """
    first = int(start_seconds * FRAMES_PER_SECOND)
    last = min(int(end_seconds * FRAMES_PER_SECOND), emission.shape[0])
    if last - first < 2:
        return []
    heard = aligner.decode_words(emission[first:last])
    if len(heard) < ANCHOR_WORDS:
        return []

    # Transcript words, each tagged with the sentence it belongs to and how far
    # into that sentence it sits, so a match can be turned back into a sentence
    # start rather than just a word start.
    written: list[str] = []
    origin: list[tuple[int, int]] = []
    for position, sentence in enumerate(sentences):
        offset = 0
        for raw in normalise(sentence.text).split():
            word = "".join(c for c in raw if c.isalpha())
            if word:
                written.append(word)
                origin.append((position, offset))
                offset += 1
    if len(written) < ANCHOR_WORDS:
        return []

    matcher = difflib.SequenceMatcher(
        None, written, [w for w, _ in heard], autojunk=False
    )
    # Each sentence keeps its best candidate — the one whose match landed
    # closest to the sentence's own first word, since that needs the least
    # extrapolation back.
    best: dict[int, tuple[int, float]] = {}
    for block in matcher.get_matching_blocks():
        if block.size < ANCHOR_WORDS:
            continue
        for step in range(block.size):
            position, offset = origin[block.a + step]
            if offset > ANCHOR_BACKOFF_WORDS:
                continue
            source = block.b + step - offset
            if source < 0:
                continue
            seconds = (first + heard[source][1]) / FRAMES_PER_SECOND
            if offset:
                seconds -= ANCHOR_MARGIN_SECONDS
            previous = best.get(position)
            if previous is None or offset < previous[0]:
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


def align_segment(
    aligner: Aligner,
    emission: torch.Tensor,
    sentences: list[Sentence],
    start_seconds: float,
    end_seconds: float,
    times: dict[int, float],
    anchored: bool = False,
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
    # puts each piece back into the short, bounded case above. `anchored` stops
    # a piece that is still too long from being decoded a second time — there
    # are no further anchors to find inside one, by construction.
    if not anchored:
        anchors = find_anchors(
            aligner, emission, sentences, start_seconds, end_seconds
        )
        if anchors:
            mark, clock = 0, start_seconds
            for position, seconds in [*anchors, (len(sentences), end_seconds)]:
                align_segment(
                    aligner,
                    emission,
                    sentences[mark:position],
                    clock,
                    seconds,
                    times,
                    anchored=True,
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
) -> dict[int, float] | None:
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
            aligner, emission, section["sentences"], float(start), end, times
        )

    log(f"  placed {len(times)}/{script['count']} sentences")
    return times


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
                times = align_lesson(lesson, aligner, args.texts_dir, log)
            except Exception as error:  # noqa: BLE001 — one bad lesson must not stop the run
                log(f"  ! failed: {error}")
                continue
            if not times:
                continue
            lesson["sentence_times"] = {
                str(k): round(v, 2) for k, v in sorted(times.items())
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
