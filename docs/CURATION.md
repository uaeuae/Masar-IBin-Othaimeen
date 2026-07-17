# Content Curation Guide

Content went live 2026-07-15: 16 active series (1,719 lessons) across the
4 launch journeys, all synced from @ibnothaimeentv. This doc now describes
how to add or resync content. Prerequisite: a **YouTube Data API v3 key**
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

## Content QA notes

- Never rename a series `slug` after release — device progress keys off video
  IDs, but journeys/enrollments key off slugs.
- Removed/private videos are marked `unavailable` automatically, never deleted.
- To hide a lesson editorially, set its `status` to `"hidden"` directly in the
  data file — syncs preserve manual `hidden` status.
