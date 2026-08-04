"""Hold-out validation for sources that publish no markers — error in seconds.

`validate_holdout.py` hides a published marker and scores the prediction at that
moment. binbaz.org.sa publishes none, so there is nothing to hide, and
`validate_decode.py` falls back to a character error rate. That rate answers a
different question than it appears to: its magnitude depends on how well the
audio decodes at least as much as on how well it is timed, so a small gap does
not by itself mean bad timing (measured — see README).

This recovers the missing markers from the audio. `find_anchors` already locates
places where the greedy decode and the transcript agree over a long run; half of
them are withheld from the aligner and used as ground truth, exactly as
`--drop-one` does with real ones. What it reports is a real offset in seconds.

Two limits, both load-bearing:

  * The withheld anchors carry their own error — a word or so of back-off — which
    puts a floor of roughly half a second on anything measurable here.
  * It can only score lessons that yielded anchors in the first place. A lesson
    whose audio decodes too poorly to anchor is *skipped*, not scored badly, so
    the headline number describes the lessons that could be anchored and says
    nothing about the rest. Read the skip count, not just the median.

  python validate_anchors.py --data-dir ../ingest/data \
      --texts-dir ../../app/assets/texts --series binbaz-sharh-altahawiyah
"""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

import torch

from align_lessons import (
    FRAMES_PER_SECOND,
    MAX_ANCHOR_DEPTH,
    Coverage,
    Aligner,
    align_segment,
    find_anchors,
    load_audio,
    read_script,
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", required=True, type=Path)
    parser.add_argument("--texts-dir", required=True, type=Path)
    parser.add_argument("--series", action="append", required=True)
    parser.add_argument("--lessons", type=int, default=6)
    parser.add_argument(
        "--device", default="cuda" if torch.cuda.is_available() else "cpu"
    )
    args = parser.parse_args()

    aligner = Aligner(args.device)
    errors: list[float] = []
    scored = skipped = 0

    for name in args.series:
        path = args.data_dir / "series" / f"{name}.json"
        if not path.exists():
            print(f"! no data file for {name}", flush=True)
            continue
        lessons = [
            lesson
            for lesson in json.loads(path.read_text(encoding="utf-8"))
            if lesson.get("audio_url")
        ]
        for lesson in lessons[: args.lessons]:
            script = read_script(lesson, args.texts_dir, aligner)
            if not script:
                continue
            emission = aligner.emissions(load_audio(lesson["audio_url"]))
            if emission.shape[0] == 0:
                continue
            total = emission.shape[0] / FRAMES_PER_SECOND
            sentences = [s for sec in script["sections"] for s in sec["sentences"]]

            anchors = find_anchors(aligner, emission, sentences, 0.0, total)
            if len(anchors) < 6:
                skipped += 1
                print(f"{name} #{lesson['position']}: {len(anchors)} anchors — "
                      f"too few to hold any out, skipped", flush=True)
                continue

            # Every other anchor is withheld; the aligner never sees it.
            kept, held = anchors[0::2], anchors[1::2]
            times: dict[int, float] = {}
            mark, clock = 0, 0.0
            for position, seconds in [*kept, (len(sentences), total)]:
                # depth at the cap: the held-out anchors must stay held out,
                # so the segment may not go looking for them again.
                align_segment(
                    aligner, emission, sentences[mark:position], clock, seconds,
                    times, Coverage(), depth=MAX_ANCHOR_DEPTH,
                )
                mark, clock = position, seconds

            mine = [
                abs(times[sentences[position].index] - seconds)
                for position, seconds in held
                if sentences[position].index in times
            ]
            if not mine:
                continue
            errors.extend(mine)
            scored += 1
            print(f"{name} #{lesson['position']}: {len(mine)} held out, "
                  f"median {statistics.median(mine):.1f}s", flush=True)

    if not errors:
        print("nothing scored", flush=True)
        return 1

    errors.sort()
    print()
    print(f"lessons scored   : {scored}  (skipped for want of anchors: {skipped})")
    print(f"predictions      : {len(errors)}")
    print(f"median error     : {statistics.median(errors):.2f} s")
    print(f"p90 error        : {errors[int(len(errors) * 0.9)]:.1f} s")
    print(f"worst            : {errors[-1]:.1f} s")
    print(f"within 3 s       : {sum(e <= 3 for e in errors) / len(errors):.0%}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
