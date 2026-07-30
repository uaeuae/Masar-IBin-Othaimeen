"""Hold-out validation for the forced aligner.

Comparing aligned times against the markers the aligner *used* as segment
boundaries proves little: a section's first sentence is constrained to start at
that boundary, so small errors there are guaranteed by construction rather than
earned. This hides half the markers, aligns without them, and checks the
predictions at the hidden ones — times the aligner had no way to know.

  python validate_holdout.py --data-dir ../ingest/data \
      --texts-dir ../../app/assets/texts --lessons 6
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import torch

from align_lessons import (
    FRAMES_PER_SECOND,
    Aligner,
    Sentence,
    align_segment,
    load_audio,
    read_script,
)


def segments_from(sections: list[dict], duration: float, keep_every: int):
    """Groups sections so only every `keep_every`-th marker stays a boundary;
    the rest are swallowed into the preceding segment."""
    kept: list[dict] = []
    for position, section in enumerate(sections):
        if section["start"] is None:
            continue
        if position % keep_every == 0 or not kept:
            kept.append(
                {
                    "start": float(section["start"]),
                    "sentences": list(section["sentences"]),
                    "hidden": [],
                }
            )
        else:
            # Hidden: its sentences ride along in the previous segment, and its
            # true start becomes a test case.
            first = section["sentences"][0].index if section["sentences"] else None
            if first is not None:
                kept[-1]["hidden"].append((first, float(section["start"])))
            kept[-1]["sentences"].extend(section["sentences"])

    for position, segment in enumerate(kept):
        following = kept[position + 1]["start"] if position + 1 < len(kept) else duration
        segment["end"] = following
    return kept


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True, type=Path)
    parser.add_argument("--texts-dir", required=True, type=Path)
    parser.add_argument("--lessons", type=int, default=6)
    parser.add_argument("--min-markers", type=int, default=6)
    parser.add_argument("--series", action="append")
    parser.add_argument("--keep-every", type=int, default=2)
    # Production-representative: hide ONE marker at a time so its neighbours
    # keep their real, production-length segments. keep-every=2 doubles every
    # segment at once, which is a harder task than the app ever faces.
    parser.add_argument("--drop-one", action="store_true")
    parser.add_argument(
        "--device", default="cuda" if torch.cuda.is_available() else "cpu"
    )
    args = parser.parse_args()

    aligner = Aligner(args.device)
    errors: list[float] = []
    checked = 0

    files = sorted((args.data_dir / "series").glob("*.json"))
    if args.series:
        files = [f for f in files if f.stem in args.series]
    for path in files:
        if checked >= args.lessons:
            break
        lessons = json.loads(path.read_text(encoding="utf-8"))
        for lesson in lessons:
            if checked >= args.lessons:
                break
            if not lesson.get("sentence_times"):
                continue
            script = read_script(lesson, args.texts_dir, aligner)
            if not script:
                continue
            timed = [s for s in script["sections"] if s["start"] is not None]
            if len(timed) < args.min_markers:
                continue

            duration = float(lesson.get("duration_seconds") or 0)
            waveform = load_audio(lesson["audio_url"])
            total = waveform.shape[-1] / FRAMES_PER_SECOND / (16000 / FRAMES_PER_SECOND)
            emission = aligner.emissions(waveform)
            if emission.shape[0] == 0:
                continue

            lesson_errors = []
            if args.drop_one:
                # Emissions are already computed; only the (cheap) alignment
                # repeats, once per hidden marker.
                for hide in range(1, len(timed)):
                    merged = []
                    for position, section in enumerate(timed):
                        if position == hide and merged:
                            first = (
                                section["sentences"][0].index
                                if section["sentences"]
                                else None
                            )
                            if first is not None:
                                merged[-1]["hidden"].append(
                                    (first, float(section["start"]))
                                )
                            merged[-1]["sentences"].extend(section["sentences"])
                        else:
                            merged.append(
                                {
                                    "start": float(section["start"]),
                                    "sentences": list(section["sentences"]),
                                    "hidden": [],
                                }
                            )
                    for position, segment in enumerate(merged):
                        segment["end"] = (
                            merged[position + 1]["start"]
                            if position + 1 < len(merged)
                            else (duration or total)
                        )
                    times: dict[int, float] = {}
                    for segment in merged:
                        align_segment(
                            aligner,
                            emission,
                            segment["sentences"],
                            segment["start"],
                            segment["end"],
                            times,
                        )
                    for segment in merged:
                        for index, truth in segment["hidden"]:
                            predicted = times.get(index)
                            if predicted is not None:
                                lesson_errors.append(abs(predicted - truth))
            else:
                segments = segments_from(
                    script["sections"], duration or total, args.keep_every
                )
                times = {}
                for segment in segments:
                    align_segment(
                        aligner,
                        emission,
                        segment["sentences"],
                        segment["start"],
                        segment["end"],
                        times,
                    )
                for segment in segments:
                    for index, truth in segment["hidden"]:
                        predicted = times.get(index)
                        if predicted is not None:
                            lesson_errors.append(abs(predicted - truth))
            if not lesson_errors:
                continue
            errors.extend(lesson_errors)
            checked += 1
            mean = sum(lesson_errors) / len(lesson_errors)
            print(
                f"{path.stem} #{lesson['position']}: {len(lesson_errors)} hidden markers"
                f"  mean |err| {mean:.2f}s  max {max(lesson_errors):.1f}s",
                flush=True,
            )

    if not errors:
        print("no hold-out cases found")
        return 1

    errors.sort()
    def pct(q: float) -> float:
        return errors[min(int(len(errors) * q), len(errors) - 1)]

    print()
    print(f"HOLD-OUT: {len(errors)} markers the aligner never saw, {checked} lessons")
    print(
        f"  median {pct(0.5):.2f}s   p90 {pct(0.9):.2f}s   max {errors[-1]:.1f}s"
    )
    for bound in (1, 3, 5, 10):
        share = 100 * len([e for e in errors if e <= bound]) / len(errors)
        print(f"  within {bound}s: {share:.0f}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
