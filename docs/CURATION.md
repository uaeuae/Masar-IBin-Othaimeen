# Content Curation Guide

## Scholars

Every series belongs to exactly one scholar (`scholar:` in the series seed;
defaults to `ibn-uthaymeen`). Scholars live in `seed/scholars.yaml` with
their rights-holding foundation for attribution.

Fields beyond the obvious ones:

| field | notes |
| --- | --- |
| `initial_ar` | The letter in his roundel. **Curated, not derived** — it is the شهرة, not the start of `name_ar`: العثيمين gives ع and ابن باز gives ب, while `name_ar[0]` would print ا for both. |
| `accent` | `green` \| `blue` \| `gold`. A palette key; the theme owns the actual colours (`MasarColors.scholarAccents`) so they can differ light/dark. |
| `honorific_ar` | «رحمه الله» / «حفظه الله». Get this right — it is wrong, not merely missing, on a living scholar. |
| `status` | `active` \| `coming_soon`. |
| `youtube_url` | Optional; listed among his sources. |

`status: coming_soon` announces a scholar the app does not carry yet: he
appears in المكتبة → الشيوخ and in الإعدادات → المصادر والإسناد, badged
«قريبًا», and his page says so instead of showing an empty list. Publishing
enforces the promise both ways — a `coming_soon` scholar with active series
fails, and so does an `active` scholar with none.

To add a scholar: add the entry, create series seeds with `scholar: <slug>`,
and add sync tooling for his official sources (own YouTube channel id / site
adapter — the current ones are Ibn-Uthaymeen specific). Seed him as
`coming_soon` first; flip to `active` in the same commit as his first series.

As of 2026-07-31 there are two: `ibn-uthaymeen` (active) and `ibn-baz`
(coming_soon, no series yet).

Content went live 2026-07-15: 16 active series (1,719 lessons) across the
4 launch journeys, all synced from @ibnothaimeentv. Since 2026-07-29 the app
ships **audio only** — same 4 journeys, 17 series, 500 full lessons; see
"Audio-only publishes" below. This doc now describes how to add or resync
content. Prerequisite: a **YouTube Data API v3 key**
(create one at console.cloud.google.com → enable "YouTube Data API v3" →
credentials → API key; the free 10k units/day quota is far more than enough).

> **Availability notes (checked 2026-07-15):** the official channel has NO
> playlists for شرح رياض الصالحين or شرح ثلاثة الأصول (verified via playlist
> listing + channel search). The hadith journey therefore starts with
> الأربعين النووية ثم عمدة الأحكام, and the aqeedah journey starts with
> كتاب التوحيد. If those playlists ever appear, add seed files and slot them
> into the journeys. Also: several channel playlists are NOT in episode
> order — the pipeline sorts each playlist by the trailing episode number
> in the video titles (see `sortByEpisodeNumber` in `src/merge.ts`).

## Steps

1. `cd tools/ingest && copy .env.example .env` and paste the key into `YT_API_KEY`
   (or set it as an environment variable — the CLI loads `.env` itself).
2. **Discover the official playlists:**
   ```
   npm run discover:playlists          # lists every playlist on @ibnothaimeentv
   ```
   Long series may be split across multiple playlists — list them in playback
   order under `youtube_playlists:` in the matching `seed/series/*.yaml`.
3. **Sync:** `npm run sync:youtube -- --dry-run` to preview, then without
   `--dry-run`. Lesson lists land in `tools/ingest/data/series/*.json`.
4. **Spot-check** each series in the data files: ordering correct, no intro
   clips/duplicates (add offenders to `overrides.exclude_videos`), titles clean
   (tune `overrides.title_cleanup`).
5. Flip each verified series to `status: active` and each journey to
   `is_published: true`.
6. **Publish:** `npm run publish:catalog` — runs integrity checks, bumps the
   version, writes `dist/` and refreshes the app's bundled
   `app/assets/catalog/catalog.json`.
7. `flutter test` in `app/`, then run the app — real content, offline-first.

The weekly GitHub Actions workflow (`sync.yml`) repeats steps 3+6 automatically
once `YT_API_KEY` is added to the repo's Actions secrets.

## Audio series (Phase 2 — foundation MP3s)

Audio series stream from the foundation's own site (sounds.binothaimeen.net)
— TOS-free background playback, unlike YouTube. The site API needs no key:

1. Find the section id: the audio library tree lives at
   `https://shekhapi.binothaimeen.net/course/sections/audio_library/10`,
   children via `.../audio_library/children/{id}?pageSize=50`.
2. In the series seed set `media: audio` and list the section ids under
   `site_audio_sections:` (playback order; numbering restarts per section).
3. `npm run sync:site-audio` — pulls lessons (MP3 path, chaptered study
   text with timestamps, dates), probes each file for duration, sorts by
   the trailing episode number, and marks zero-byte/broken uploads
   `unavailable`. Then `npm run publish:catalog` as usual.

Known quirks (2026-07-16): the API's `certificate_url` field holds the MP3
path in three formats (rooted/unrooted/absolute); some files open with a
~1 MB ID3 cover-art tag (the duration probe reads past it); رياض الصالحين
lessons 66–69 are zero-byte uploads on the server (auto-marked unavailable).

### Companion audio editions («النسخة الصوتية»)

The YouTube videos are *clips* — the channel chopped the original lessons
into short segments (e.g. كتاب التوحيد: 239 clips vs 54 full audio lessons),
so lesson-level video↔audio matching is impossible. Instead, every video
series can declare a full audio edition as a separate series seed with
`companion_of: <video-slug>` (plus `media: audio` + `site_audio_sections`).
Effects:

- publish emits `companion_of` on the audio series and the computed reverse
  `companion_slug` on the video series (integrity: the target must be an
  active video series, one companion max).
- The app hides companion series from library browse and science counters;
  they're reached via the «الاستماع للنسخة الصوتية» banner on the video
  series (and the player's headphones button). Progress is per-edition.
- Chapter `body` texts are NOT exported to the app catalog (~10 MB across
  the library; the app only renders chapter titles + timestamps). They stay
  in `data/series/*.json` for a future transcript-reading feature.

All 16 video series have companion seeds (2026-07-17). For تفسير جزء عم the
audio side is 37 single-lesson per-surah sections listed in mushaf order —
the episode sort falls back to seed order when titles carry no numbers.

### The book being explained (`book_author_ar`)

The sheikh teaches *from* a matn he mostly did not write — زاد المستقنع is
الحجاوي's, الأربعون is النووي's — though a few (الأصول من علم الأصول, أصول في
التفسير) are his own. The optional `book_author_ar` seed field names the matn's
author, and the app shows «المؤلف» beside «الشارح».

**The foundation's API carries no author field.** Verified 2026-07-31, not assumed:

- `course/sections/{book_library,written_library,matn_library}/10` all return
  empty — the route accepts any `type` string, so a 200 there means nothing.
- `binothaimeen.net/sitemap.xml` holds exactly two URL patterns:
  `voice_library/lessonDetails` (34,444) and `Levels/lessonDetails` (552).
  There are no book pages on the site at all.
- Section objects: `id, type, title, description, certificate_url,
  confirm_subscribers, confirm_certificate, views, image_url,
  many_lessons_count, many_all_lessons_count, children_count,
  estimated_minutes`.
- Lesson objects: `id, title, type, objective, description, estimated_minutes,
  publish_date, certificate_url, image_url, confirm_subscribers,
  confirm_certificate, views, created_at, attachments`. `attachments` was empty
  on every lesson sampled — no PDF of the matn either.

Note `publish_date`, which `site.ts` does NOT read: it is real and varies per
lesson (رياض from 2011-10-14, كتاب التوحيد from 2008-11-24, incrementing daily),
unlike `created_at` which is 2022-04-05 for all 500. It is the foundation's
upload schedule — years after the sheikh died in 2001 — so it is a publication
date, not a teaching date, and the app deliberately shows neither.

So authors are hand-curated, and left empty rather than guessed — an omitted attribution is
recoverable, a wrong one in a da'wah app is not.

«نص الكتاب» (`/series/<slug>/book`) assembles the matn from the read-along
scripts already bundled, and links each passage to the moment it is explained.
It reads the two script kinds differently, which matters: on a `matn` script
the sections *are* the book, so the passage is the section's text; on a
`transcript` the sentences are the sheikh speaking and only the section title
is matn, so taking the sentences there would reprint the lecture as the book.
Coverage follows from that — full for رياض الصالحين (1,639 passages) and
الأربعون; the matn phrases for زاد المستقنع; headings only for كتاب التوحيد;
nothing for حلية، الأصول، الواسطية، عمدة الأحكام, where the button is hidden.

### Loudness levelling (`npm run analyze:loudness`)

The foundation's uploads span decades of recording gear and their levels wander
by **more than 8 dB within a single series** — رياض الصالحين runs −19.2 LUFS at
lesson 1 and −11.0 at lesson 95; كتاب الصلاة has −21.7 sitting between −16.3 and
−14.5. That mismatch, not the absolute level, is what makes a lesson feel
inaudible right after the previous one. Per-series correction cannot fix it.

`analyze:loudness` measures each lesson (EBU R128) and stores `loudness_lufs` in
`data/series/*.json`; publish turns that into `gain_db` per lesson via
`src/loudness.ts`. It samples three 60s windows rather than scanning end to end
— within ~0.3 dB of a full pass on speech (verified −16.4 vs −16.7) for a
twentieth of the bandwidth, which matters when the alternative is pulling ~10 GB
through the foundation's servers. Resumable: rerunning skips what's measured,
`--force` re-measures. Needs `ffmpeg` on PATH.

**What the app can actually do with it.** Attenuation works everywhere.
Boosting does not: iOS caps `AVPlayer.volume` at 1.0× and just_audio ships no
Darwin audio effects, so a positive `gain_db` is only realised on Android, via
`AndroidLoudnessEnhancer`. The target is therefore −16 LUFS — roughly the
library's middle — so loud lessons come down to meet the quiet ones instead of
the whole library being dragged to the quietest. Files also peak at ≈−2 dBFS,
leaving no headroom for a naive digital boost. True levelling on iPhone would
need a native AVAudioEngine path with a limiter; the `gain_db` field is already
in place for it.

### Lesson text & read-along (`npm run build:texts`)

The player can show the lesson's text with the sentence being spoken
highlighted. `build-texts` compiles that from the same scraped chapters, one
gzipped script per lesson in `app/assets/texts/<lessonId>.json.gz` (386 files,
~5 MiB). It is NOT part of `catalog.json` — ~10 MB of prose has no business in
a snapshot re-imported into drift on every version bump — but publish stamps a
`text_kind` on each lesson so the player knows whether to offer «النص» without
probing for the asset. Both sides call the same `classifyLesson`, so they
can't disagree; rerun both commands together.

What the lessons carry (2026-07-29):

| | lessons | |
|---|---|---|
| `transcript` — تفريغ نصي of the speech | 259 | زاد المستقنع, كتاب التوحيد, جزء عمّ, أصول التفسير |
| `matn` — the book text, not the speech | 127 | رياض الصالحين, الأربعون النووية |
| no text | 114 | حلية طالب العلم, الأصول من علم الأصول, الواسطية, عمدة الأحكام |

**Sentence times are estimated, not measured.** The site only timestamps
markers (`mat-parts`), so `text-align.ts` cuts each transcript at the markers
it can locate in the prose — a forward-constrained match, rejected unless the
implied rate lands in 3–20 chars/s, since the sheikh re-quotes the matn and a
naive search would drag the timeline backwards. Sentences are then spread
across each section by character count. The upshot: **exact at every section
boundary, drifting up to ~30s in between**, which the UI admits with
«مزامنة تقريبية» plus tap-to-seek and long-press-to-re-anchor. Two shapes feed
this: زاد المستقنع lessons hold one transcript blob plus matn markers, while
جزء عمّ / أصول التفسير / الحج / كتاب التوحيد arrive already segmented (each
chapter has its own body and timestamp) and skip matching entirely.

Matn lessons get no per-sentence times at all — the speech isn't in that text,
so the whole passage highlights on its marker.

Real numbers for كتاب الطهارة درس ١: 12 sections, all on real markers, 413
sentences, none out of order, last at 5436s of 5442s.

Forced alignment (wav2vec2/WhisperX over the 351 transcript hours) is the
upgrade path to true karaoke sync; it would fill in better `t` values with no
app change.

### Audio-only publishes (`--audio-only`)

`npm run publish:catalog -- --audio-only` ships the audio library alone —
what the app currently ships (catalog v8, 2026-07-29). The seeds don't
change; the flag only affects what the pipeline exports:

- video series are left out of `series[]` entirely;
- every journey item on a video series falls through to its companion
  (`sharh-zad-taharah` → `sharh-zad-taharah-audio`), so all four journeys
  survive intact. A video series in a journey with *no* companion fails the
  publish rather than silently emptying a stage;
- `companion_of`/`companion_slug` are exported null, which promotes the
  companions to browsable and hides the cross-edition banners;
- the «(صوتي)» title suffix is stripped — it's the only edition now.

Nothing is lost by it: the companions carry more hours than the clips they
replace (692.1h vs 478.7h; كتاب البيوع alone gains 32.3h). Only كتاب الجنائز
(−0.7h) and أصول في التفسير (−0.2h) come out marginally shorter.

To bring video back, publish again without the flag. The app's YouTube
player, PiP, and companion banners stay in the code, dormant — the catalog
is the only switch.

## Content QA notes

- Never rename a series `slug` after release — device progress keys off video
  IDs, but journeys/enrollments key off slugs.
- Removed/private videos are marked `unavailable` automatically, never deleted.
- To hide a lesson editorially, set its `status` to `"hidden"` directly in the
  data file — syncs preserve manual `hidden` status.
