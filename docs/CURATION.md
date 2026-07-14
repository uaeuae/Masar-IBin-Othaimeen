# Content Curation Guide (M6 — go-live checklist)

The 4 launch journeys are seeded but unpublished. Going live with real content
takes ~30 minutes and one prerequisite: a **YouTube Data API v3 key**
(create one at console.cloud.google.com → enable "YouTube Data API v3" →
credentials → API key; the free 10k units/day quota is far more than enough).

## Steps

1. `cd tools/ingest && copy .env.example .env` and paste the key into `YT_API_KEY`
   (or set it as an environment variable).
2. **Discover the official playlists:**
   ```
   npm run discover:playlists          # lists every playlist on @ibnothaimeentv
   ```
   Pick the playlist IDs for: شرح ثلاثة الأصول، شرح العقيدة الواسطية،
   الشرح الممتع على زاد المستقنع، شرح رياض الصالحين، تفسير جزء عمّ.
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
