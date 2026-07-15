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

## Content QA notes

- Never rename a series `slug` after release — device progress keys off video
  IDs, but journeys/enrollments key off slugs.
- Removed/private videos are marked `unavailable` automatically, never deleted.
- To hide a lesson editorially, set its `status` to `"hidden"` directly in the
  data file — syncs preserve manual `hidden` status.
