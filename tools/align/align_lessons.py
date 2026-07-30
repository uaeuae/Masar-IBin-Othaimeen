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
cannot escape the section it happened in. Only sections too long for one trellis
are sub-divided, using that section's own measured text density.

Usage:
  python align_lessons.py --data-dir ../ingest/data --texts-dir ../../app/assets/texts
Add --limit N for a trial, --series SLUG to restrict, --force to redo.
Times are written back into data/series/*.json as `sentence_times`, so the run is
resumable and `npm run build:texts` picks them up.
"""

from __future__ import annotations

import argparse
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


def align_segment(
    aligner: Aligner,
    emission: torch.Tensor,
    sentences: list[Sentence],
    start_seconds: float,
    end_seconds: float,
    times: dict[int, float],
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

    # Long section: walk it, trusting the front of each sub-window and resuming
    # from the last sentence placed. The text slice is sized from this section's
    # own measured density, so it neither compresses nor stretches.
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
            if not lesson.get("chapters"):
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
