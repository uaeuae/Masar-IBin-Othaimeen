"""Scores alignment accuracy from the audio alone, with no ground-truth markers.

Why this exists
---------------
`validate_holdout.py` proves alignment quality by dropping a marker the aligner
never saw and scoring against it. That needs markers — and binbaz.org.sa
publishes none at all, not on the lesson page and not in the transcript. There
is nothing to hold out, so the 1.26 s median recorded in DECISIONS.md 8 cannot
be reproduced or even measured for that source.

This scores the same failure from the other side. For a sampled sentence:

    cut the audio at the time alignment claims  ->  decode it  ->  compare to
    the sentence's own text

A correctly placed sentence decodes to roughly itself. A drifted one decodes to
whatever is actually being said at that moment, and the character error rate
goes up. The CER is not an accuracy in seconds — it is a *comparative* signal,
which is why the run below is only meaningful against a control:

    # the source being judged
    python validate_decode.py --data-dir ../ingest/data --texts-dir \
        ../../app/assets/texts --series binbaz-sharh-kitab-altawhid

    # the control: a source already validated the hold-out way
    python validate_decode.py --data-dir ../ingest/data --texts-dir \
        ../../app/assets/texts --series sharh-zad-taharah

If the medians are comparable, the new source's alignment is as good as the one
we already trust. If the new one is much worse, its text should not ship — the
app renders «لا يوجد نص لهذا الدرس» perfectly well.

Do NOT read a low CER here as "1.3 s accurate". It says the audio at that
timestamp matches the sentence; it does not measure the offset.
"""

from __future__ import annotations

import argparse
import gzip
import json
import random
import statistics
import sys
from pathlib import Path

import torch

from align_lessons import Aligner, load_audio, normalise, SAMPLE_RATE

# Decoded window around the claimed start. Long enough to contain a typical
# sentence, short enough that a drifted placement cannot accidentally cover it.
WINDOW_SECONDS = 6.0

# Sentences shorter than this decode too noisily to score.
MIN_CHARS = 25


def cer(reference: str, hypothesis: str) -> float:
    """Levenshtein distance / reference length, on the match-only form."""
    ref, hyp = normalise(reference), normalise(hypothesis)
    if not ref:
        return 1.0
    previous = list(range(len(hyp) + 1))
    for i, r in enumerate(ref, 1):
        current = [i]
        for j, h in enumerate(hyp, 1):
            current.append(
                min(
                    previous[j] + 1,
                    current[j - 1] + 1,
                    previous[j - 1] + (r != h),
                )
            )
        previous = current
    return previous[-1] / len(ref)


@torch.inference_mode()
def greedy_decode(aligner: Aligner, waveform: torch.Tensor) -> str:
    """Plain CTC greedy decode — no language model, so what comes out is what
    the acoustic model actually heard."""
    logits = aligner.model(waveform.to(aligner.device)).logits[0]
    ids = logits.argmax(dim=-1).tolist()
    out: list[str] = []
    previous = None
    inverse = {v: k for k, v in aligner.vocab.items()}
    for token in ids:
        if token != previous and token != aligner.blank:
            char = inverse.get(token, "")
            out.append(" " if char == "|" else char)
        previous = token
    return "".join(out).strip()


def sentences_of(lesson: dict, texts_dir: Path) -> list[str]:
    asset = texts_dir / f"{lesson['youtube_video_id']}.json.gz"
    if not asset.exists():
        return []
    with gzip.open(asset, "rt", encoding="utf-8") as handle:
        raw = json.load(handle)
    return [
        sentence.get("s", "")
        for section in raw.get("sections", [])
        for sentence in section.get("sentences", [])
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True, type=Path)
    parser.add_argument("--texts-dir", required=True, type=Path)
    parser.add_argument("--series", action="append", required=True)
    parser.add_argument("--lessons", type=int, default=6, help="lessons sampled")
    parser.add_argument("--per-lesson", type=int, default=8, help="sentences each")
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument(
        "--shift",
        type=float,
        default=45.0,
        help=(
            "Also score each sentence at t+shift, where it is known to be wrong. "
            "This is the control that matters: comparing CER across sources "
            "confounds alignment quality with audio quality (older, noisier "
            "recordings decode worse however well they are aligned). The gap "
            "between aligned and shifted CER is within-source, so it isolates "
            "alignment. A small gap means the timing carries no information."
        ),
    )
    parser.add_argument(
        "--device", default="cuda" if torch.cuda.is_available() else "cpu"
    )
    args = parser.parse_args()

    rng = random.Random(args.seed)
    aligner = Aligner(args.device)

    scores: list[float] = []
    shifted_scores: list[float] = []
    checked = 0

    for name in args.series:
        path = args.data_dir / "series" / f"{name}.json"
        if not path.exists():
            print(f"! no data file for {name}", flush=True)
            continue
        lessons = [
            lesson
            for lesson in json.loads(path.read_text(encoding="utf-8"))
            if lesson.get("sentence_times") and lesson.get("audio_url")
        ]
        if not lessons:
            print(f"! {name}: no aligned lessons", flush=True)
            continue
        rng.shuffle(lessons)

        for lesson in lessons[: args.lessons]:
            sentences = sentences_of(lesson, args.texts_dir)
            if not sentences:
                continue
            times = {int(k): v for k, v in lesson["sentence_times"].items()}
            candidates = [
                (i, t)
                for i, t in sorted(times.items())
                if i < len(sentences) and len(sentences[i]) >= MIN_CHARS
            ]
            if not candidates:
                continue
            picks = rng.sample(candidates, min(args.per_lesson, len(candidates)))

            waveform = load_audio(lesson["audio_url"])
            total = waveform.shape[-1]
            for index, start in sorted(picks):
                first = int(start * SAMPLE_RATE)
                last = min(first + int(WINDOW_SECONDS * SAMPLE_RATE), total)
                if last - first < SAMPLE_RATE:
                    continue
                heard = greedy_decode(aligner, waveform[..., first:last])
                # The window holds only the sentence's opening, so score the
                # reference truncated to what the window could contain.
                expected = sentences[index][: max(len(heard), MIN_CHARS)]
                scores.append(cer(expected, heard))
                checked += 1

                # Same sentence, same audio, deliberately wrong moment.
                off = first + int(args.shift * SAMPLE_RATE)
                if off + int(WINDOW_SECONDS * SAMPLE_RATE) <= total:
                    wrong = greedy_decode(
                        aligner,
                        waveform[..., off : off + int(WINDOW_SECONDS * SAMPLE_RATE)],
                    )
                    shifted_scores.append(
                        cer(sentences[index][: max(len(wrong), MIN_CHARS)], wrong)
                    )
            print(
                f"{name} #{lesson['position']}: {len(picks)} sampled "
                f"(running median CER {statistics.median(scores):.3f})",
                flush=True,
            )

    if not scores:
        print("nothing scored", flush=True)
        return 1

    scores.sort()
    aligned_median = statistics.median(scores)
    print()
    print(f"sentences scored : {checked}")
    print(f"median CER       : {aligned_median:.3f}")
    print(f"p90 CER          : {scores[int(len(scores) * 0.9) - 1]:.3f}")
    print(f"share under 0.50 : {sum(s < 0.5 for s in scores) / len(scores):.0%}")

    if shifted_scores:
        shifted_median = statistics.median(shifted_scores)
        print()
        print(f"median CER at t+{args.shift:.0f}s (known wrong) : {shifted_median:.3f}")
        print(f"gap (wrong - aligned)                : {shifted_median - aligned_median:+.3f}")
        print()
        print(
            "The gap is the real signal, because it is measured within one\n"
            "source: noisy audio raises both numbers together. A clear positive\n"
            "gap means the timestamps point at the right moment. A gap near zero\n"
            "means they carry no information and the text should not ship."
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
