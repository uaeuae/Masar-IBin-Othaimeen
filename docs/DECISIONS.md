# Architecture Decisions

Short log of load-bearing decisions. Full plan history lives with the repo owner.

1. **Supabase + catalog snapshot** — Postgres is the source of truth; the pipeline compiles a gzipped `catalog.json` published to Supabase Storage. The app bundles a snapshot in the APK, checks a tiny `meta.json` on launch, and downloads only on version change. Offline-first, ~zero egress, survives free-tier pauses.
2. **Seeds-as-curation** — journeys/stages/ordering live in `seed/*.yaml`, validated in CI. No admin UI. Merge precedence: seeds > site > YouTube.
3. **No auth in MVP** — progress is device-local (drift/SQLite) with `updated_at`/`synced_at` columns so Phase 2 anonymous-auth sync is additive. No login wall.
4. **YouTube TOS compliance** — playback exclusively via the official embedded player (`youtube_player_iframe`). No downloading/ripping, no background YouTube audio. Phase 2 audio uses binothaimeen.net-hosted files only.
5. **MVP ingests YouTube only** — the binothaimeen.net site adapter is an enrichment layer behind an interface, deferred past MVP. Raw responses get snapshotted so parser breakage is loud.
6. **Arabic-only, RTL-first** — `supportedLocales: [ar]`, `EdgeInsetsDirectional` everywhere, bundled IBM Plex Sans Arabic, dark mode from day one.
7. **App identity** — Dart package `masar`, Android applicationId `app.othaimeen.masar` (placeholder — finalize before the first Play upload; it cannot be changed after).
