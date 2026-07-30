# Forced alignment — accurate read-along timing

Measures where each sentence of a lesson is actually spoken, so the player's
highlight tracks the audio instead of guessing.

## Why it's needed

The foundation's site timestamps «mat-parts» markers only, and the median
transcript lesson has a **34 minute stretch between them**. Interpolating
sentence times across that gap drifts by minutes — measured, not assumed:

Accuracy is measured by **hold-out**: markers are hidden from the aligner, it
runs without them, and its predictions at those hidden times are scored.
`validate_holdout.py --drop-one` hides one marker at a time so its neighbours
keep production-length segments.

| | interpolated | aligned |
|---|---|---|
| median error | minutes | **1.26 s** |
| p90 | — | **3.26 s** |
| worst | 994 s | 21.3 s |
| within 3 s | — | **88%** |

(80 hidden markers over 5 تفسير جزء عمّ lessons.)

**Do not score against markers the aligner used as segment boundaries.** A
section's first sentence is constrained to start at its boundary, so errors
there are small by construction rather than earned — that measure reports
~1.2 s even when mid-segment alignment is minutes off.

Blob-transcript series (زاد المستقنع) score worse on the same test — mean 6-24 s
per lesson. Some of that is genuine, but some is *reference* error: their section
boundaries were themselves derived by fuzzy text matching in `text-align.ts`, so
the hidden marker's position in the text is uncertain by a sentence or two.
Series the site pre-segments (تفسير, أصول التفسير, الحج) have authoritative
boundaries and are the trustworthy measurement.

## Setup

Needs an NVIDIA GPU and `ffmpeg` on PATH. **The torch build matters**: CUDA 13
dropped Pascal, so a GTX 10-series card needs a cu124 wheel. Check
`torch.cuda.get_arch_list()` contains your card's capability — `is_available()`
returning True is not enough, the kernels will simply fail at launch.

```bash
py -3.12 -m venv .venv
.venv/Scripts/python -m pip install torch==2.6.0 torchaudio==2.6.0 \
    --index-url https://download.pytorch.org/whl/cu124
.venv/Scripts/python -m pip install "transformers>=4.40,<5"
```

## Running

```bash
# always build the scripts first: the aligner reads sentences from them
cd ../ingest && npm run build:texts && cd ../align

.venv/Scripts/python align_lessons.py \
    --data-dir ../ingest/data --texts-dir ../../app/assets/texts

# then fold the measured times into the assets
cd ../ingest && npm run build:texts
```

~90x realtime on a 1080 Ti, so the full 351 hours of audio takes about 4 hours.
Resumable: lessons already carrying `sentence_times` are skipped, `--force`
redoes them. `--limit N` and `--series SLUG` for trial runs. Audio is streamed
and decoded through ffmpeg, never stored.

## The trap, if you touch the windowing

Forced alignment **must** fit every token into the frames it is handed, and it
cannot tell you the fit was absurd — it just returns confident nonsense:

- too much text for the window → times compress (measured 2.7x fast)
- too little → the text is free to stretch, and each window's over-advance
  compounds into the next (measured drifting from +1 s to +650 s across a lesson)

Both failures place 100% of sentences and look like success. That is why sections
are aligned inside the audio their own markers bound rather than in guessed
windows: real boundaries mean error cannot escape the section it happened in.
Only sections too long for one trellis get sub-divided, sized by that section's
own measured text density.

**If you change any of this, re-run the marker comparison above.** Sentence
counts prove nothing.
