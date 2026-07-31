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

## Sources with no markers at all

The hold-out test needs markers to hide. **binbaz.org.sa publishes none** — not
on the lesson page, not in the transcript. Its lessons used to align as one
unanchored segment each, and the sub-window walk had nothing to re-anchor
against: each window's over- or under-advance was carried into the next for an
hour. Measured, on held-out anchors (below), that walk was **135 s off at the
median and up to 690 s** on the long الطحاوية lessons.

**The binbaz transcript is verbatim** — worth stating, because if it were not,
no amount of windowing work could succeed and the answer would be "give up". Two
measurements say it is. Its text density is 9.5–10.4 chars/s against 9.5 chars/s
for the trusted source measured inside real marker bounds; and between
audio-derived anchors the local rate holds at 9.3–11.2 chars/s (p10 3.6, p90
17.9) with no stretch of audio that the text skips. The problem was our
windowing, not the source.

### Anchors recovered from the audio

`find_anchors` gets the missing markers out of the recording. Greedy-decode the
segment, match the recognised words against the transcript's with an LCS, and
every run of ≥ `ANCHOR_WORDS` agreeing words is a place where we know both what
is being said and when. Those runs become segment bounds, which puts a
marker-less source back into the case the aligner was built for.

Two things make it work at all. The model's vocabulary **includes tashkeel**, so
it decodes «قَوْمٌ» where the transcript writes «قوم» — both sides must go through
`normalise()` or the match rate reads 0.6% instead of 23%. And the LCS is
monotonic by construction, so a run cannot be matched to an earlier moment than
the run before it, which is exactly what a bound needs.

Tuning, all paired over the same 96 sentences (gap, higher is better):

| `ANCHOR_WORDS` | 3 | 4 | **5** | back-off 16 |
|---|---|---|---|---|
| gap | +0.068 | +0.109 | **+0.113** | +0.099 |

Three matches the wrong instance too often — Arabic religious prose repeats
short formulas constantly. Sizing each walk window from the greedy decode's
*local* character count instead of the section average was also tried, on the
theory that speech rate varies within a lesson; it measured +0.114 against
+0.113, i.e. nothing, and was dropped rather than add complexity to the
windowing.

`validate_decode.py` scores placement from the audio: sample aligned sentences,
cut the audio at the time alignment claims, greedy-CTC-decode that window, and
compare to the sentence by character error rate. A correctly placed sentence
decodes to roughly itself; a drifted one decodes to whatever is really being
said there.

```bash
.venv/Scripts/python validate_decode.py --data-dir ../ingest/data \
    --texts-dir ../../app/assets/texts --series binbaz-sharh-kitab-altawhid
.venv/Scripts/python validate_decode.py --data-dir ../ingest/data \
    --texts-dir ../../app/assets/texts --series tafsir-juz-amma-audio  # control
```

`validate_anchors.py` is the better test where it applies: it withholds half the
audio-derived anchors and scores the prediction at them, so it reports **seconds**
rather than a rate. On the الطحاوية lessons that anchor at all, the walk was
135 s off at the median and anchoring brings it to **0.25 s, 95% within 3 s** —
comparable to the 0.25–0.43 s the same test gives on the trusted source.

Its blind spot is the whole reason binbaz still ships no text: it **skips**
lessons too poorly decoded to anchor rather than scoring them badly. Three of
six الطحاوية lessons yielded 1–3 anchors and were skipped, and those are exactly
the lessons anchoring cannot fix. Always read the skip count.

```bash
.venv/Scripts/python validate_anchors.py --data-dir ../ingest/data \
    --texts-dir ../../app/assets/texts --series binbaz-sharh-altahawiyah
```

Absolute CER runs high (~0.6) even on good alignment, because greedy decoding
without a language model is noisy. **Read the `--shift` gap, not the raw CER.**
Comparing CER across sources confounds alignment quality with audio quality —
older, noisier recordings decode worse however well they are timed. The gap
between the aligned time and a deliberately wrong one (t+45s) is measured within
a single source, so it isolates the timing.

Measured 2026-08-01, 96 sentences each, paired (same sentences before and after):

| | aligned | p90 | at t+45s | gap |
|---|---|---|---|---|
| تفسير + أصول التفسير, marker-bounded | 0.601 | 0.844 | 0.798 | **+0.197** |
| …same, with audio anchors as well | 0.567 | 0.854 | 0.781 | **+0.214** |
| binbaz, one unanchored segment | 0.708 | 1.207 | 0.778 | **+0.069** |
| binbaz, with audio anchors | 0.671 | 1.150 | 0.785 | **+0.113** |

Anchoring helps both sources, and helps binbaz most — but binbaz still reaches
only about half the trusted source's gap, so **those series keep
`read_along: false`** and play audio with no text.

**Sample size matters here.** At 16 sentences the same comparison read 0.522 vs
0.467 and looked fine. Use at least ~96.

**Compare only paired samples.** `validate_decode.py` walks ONE seeded RNG
through every lesson, so anything that changes a lesson's placed-sentence count
— or the number of lessons in the file — changes *which* sentences get sampled
from that point on. Scoring a 6-lesson trial file against a baseline taken over
the full file compares two different samples: that mistake read +0.083 where the
paired comparison reads +0.113. Graft trial times back into a full-size copy of
the data before scoring.

A low CER does **not** mean "1.3 s accurate". It says the audio at that timestamp
matches the sentence; it does not measure the offset.

### The gap is not comparable across sources either

The gap was introduced because raw CER confounds alignment quality with audio
quality. It does fix the *direction* of the measure, but not its *scale*: both
CERs saturate on audio that decodes badly, so a well-aligned lesson in a noisy
recording still shows a small gap. Per-lesson, within the trusted source:

| | aligned CER | gap |
|---|---|---|
| تفسير #18 | 0.322 | +0.515 |
| تفسير #12 | 0.553 | +0.209 |
| أصول التفسير #8 | 0.738 | +0.066 |
| أصول التفسير #3 | 0.818 | −0.027 |

Those are all marker-bounded, hold-out-validated lessons that ship
`read_along: true`, and the worst-decoding of them scores a gap of **zero**. So a
small gap is evidence of bad timing *only* when the audio decodes well enough for
the measure to have any range. Prefer `validate_anchors.py`, which reports
seconds.

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
Sections too long for one trellis are first re-bounded by audio anchors, and only
walked blind where no anchor can be found.

**If you change any of this, re-run the marker comparison above.** Sentence
counts prove nothing — the binbaz alignment placed 100% of sentences and spanned
the full duration while being ten minutes out by the end of a lesson.
