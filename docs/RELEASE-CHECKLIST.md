# Release Checklist (Google Play, first internal-testing build)

## One-time machine setup
- [ ] Install **Android Studio** (brings the Android SDK + emulator + a compatible JDK).
      After install: `flutter doctor` must show a green Android toolchain,
      then `flutter doctor --android-licenses`.
- [ ] Optional but recommended: add `C:\src\flutter\bin` to PATH.

## Content (see docs/CURATION.md)
- [ ] YouTube Data API key created; `YT_API_KEY` set locally and as a GitHub Actions secret
- [ ] Official playlist IDs filled in `seed/series/*.yaml` (`npm run discover:playlists`)
- [ ] `npm run sync:youtube` + spot-check + series `active` + journeys `is_published: true`
- [ ] `npm run publish:catalog` (refreshes the bundled app asset)

## App identity (decide once, cannot change after first Play upload)
- [ ] Final `applicationId` in `app/android/app/build.gradle.kts`
      (currently the placeholder `app.othaimeen.masar`)
- [ ] Signing: create an upload keystore, wire `key.properties`
      (https://docs.flutter.dev/deployment/android#signing-the-app)

## Store listing
- [ ] Play Console developer account ($25 one-time)
- [ ] Listing (Arabic): title «مسار ابن عثيمين», short + full description, screenshots
- [ ] **Data safety form**: no data collected; declare only what's true.
      If Sentry is added later, declare crash diagnostics then.
- [ ] Content rating questionnaire (education/religion, no UGC)
- [ ] Privacy policy URL — host `docs/privacy-policy.md` (e.g. GitHub Pages) and link it

## Etiquette / goodwill (recommended before launch)
- [ ] Email مؤسسة الشيخ محمد بن صالح العثيمين الخيرية: non-profit intent,
      official-embed-only playback, prominent attribution, offer to comply
      with any request (contact via binothaimeen.net)

## Final verification on a clean device
- [ ] `flutter build appbundle --release`, install via internal testing track
- [ ] First run in **airplane mode**: bundled catalog renders, journeys browsable
- [ ] Play a lesson, background/kill the app, reopen → resumes at position
- [ ] Device language Arabic: all screens RTL, no clipped text
- [ ] Dark theme pass

## Later (Phase 2)
- Sentry crash reporting (then update data-safety form)
- Supabase project: apply `supabase/migrations/`, upload `dist/` snapshots,
  point the app's meta.json check at storage (currently bundled-asset only)
- iOS: Apple Developer account + macOS CI lane + TestFlight
