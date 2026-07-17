# مسار طالب العلم

تطبيق تعليمي مجاني غير ربحي يجمع دروس فضيلة الشيخ محمد بن صالح العثيمين رحمه الله في مسارات تعليمية منظّمة لطالب العلم — من قناة الشيخ الرسمية على يوتيوب والموقع الرسمي [binothaimeen.net](https://binothaimeen.net).

A free, non-profit learning app organizing the lessons of Sheikh Muhammad ibn Salih al-Uthaymeen (رحمه الله) into structured learning journeys.

## Repository layout

| Path | Purpose |
| --- | --- |
| `app/` | Flutter app (Arabic-only, RTL-first, Android + iOS) |
| `tools/ingest/` | TypeScript ingestion pipeline (YouTube → DB → catalog snapshot) |
| `seed/` | Curation source of truth — YAML files defining sciences, series, and journeys |
| `supabase/migrations/` | Postgres schema (Supabase) |
| `docs/` | Decisions and content style guide |

## How content flows

```
YouTube Data API ──┐
                   ├─→ Supabase Postgres ─→ catalog.json.gz (Supabase Storage)
seed/*.yaml ───────┘                              │
                                                  ▼
                              Flutter app (bundled snapshot + version check)
```

- **Seeds own curation** (journeys, stages, ordering, overrides); **ingestion owns metadata** (titles, durations, thumbnails). Merge precedence: seeds > site > YouTube.
- The app ships with a bundled catalog snapshot and works fully offline (except video playback).
- Videos play through the official YouTube embedded player only (YouTube TOS).

## Development

```powershell
# Flutter app (Android needs Android Studio installed; Windows desktop works for UI preview)
cd app
flutter pub get
flutter run -d windows   # quick UI preview (video playback = mobile only)
flutter test

# Ingestion tool
cd tools/ingest
npm install
npm run validate:seeds
npm test
```

**Going live with real content:** see [docs/CURATION.md](docs/CURATION.md)
(one YouTube API key + ~30 minutes of playlist curation).
**Publishing to Google Play:** see [docs/RELEASE-CHECKLIST.md](docs/RELEASE-CHECKLIST.md).

## Attribution

جميع المواد العلمية من إنتاج ونشر مؤسسة الشيخ محمد بن صالح العثيمين الخيرية. هذا التطبيق جهد تطوعي مستقل لتيسير الوصول إلى علم الشيخ، وليس تطبيقًا رسميًا للمؤسسة.
