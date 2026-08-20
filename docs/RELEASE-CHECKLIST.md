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
      (currently the placeholder `app.masar.talib`)
- [ ] Signing: create an upload keystore, wire `key.properties`
      (https://docs.flutter.dev/deployment/android#signing-the-app)

## Store listing
- [ ] Play Console developer account ($25 one-time)
- [ ] Listing (Arabic): title «مسار طالب العلم», short + full description, screenshots
- [ ] **Data safety form**: no data collected; declare only what's true.
      If Sentry is added later, declare crash diagnostics then.
- [ ] Content rating questionnaire (education/religion, no UGC)
- [x] Privacy policy URL — **live at
      <https://aalkendi90.github.io/masar-privacy/>** (GitHub Pages on the
      `aalkendi90/masar-privacy` repo, a copy of `docs/privacy/index.html`;
      when the policy changes, update `docs/privacy-policy.md`,
      `docs/privacy/index.html`, and that repo's `index.html` together).
      Optional later: enable Pages on this repo (Settings → Pages → `main`,
      folder `/docs`; needs repo **admin**) and switch the stores to
      `https://uaeuae.github.io/Masar-IBin-Othaimeen/privacy/`

## Final verification on a clean device
- [ ] `flutter build appbundle --release`, install via internal testing track
- [ ] First run in **airplane mode**: bundled catalog renders, journeys browsable
- [ ] Play a lesson, background/kill the app, reopen → resumes at position
- [ ] Device language Arabic: all screens RTL, no clipped text
- [ ] Dark theme pass

## iOS beta (TestFlight) — the current test path (user's phone is an iPhone)
- [ ] Apple Developer Program enrollment ($99/yr, developer.apple.com, 1–2 days)
- [ ] Follow the numbered setup steps at the top of `codemagic.yaml`
      (App Store Connect API key → Codemagic integration named
      `masar-asc-key` → register bundle id `app.masar.talib` → create the
      App Store Connect app → run the ios-testflight workflow)
- [ ] Add yourself as internal tester; install via the TestFlight app

## iOS App Store (production release)
Prereq: TestFlight pipeline already ships every push to main (codemagic.yaml);
promoting to the store is metadata + review, no new build machinery.
- [ ] Privacy policy hosted (see Store listing above) and linked in
      App Store Connect → App Privacy
- [ ] App Privacy questionnaire: **Data Not Collected** (matches the policy;
      revisit if Sentry ships later)
- [ ] Version: bump `app/pubspec.yaml` to `1.0.0+N` (N > last TestFlight
      build number)
- [ ] Listing (Arabic primary): name «مسار طالب العلم», subtitle, description,
      keywords, support URL (the GitHub repo works), copyright line naming the
      foundations as content owners
- [ ] Screenshots: 6.7"/6.9" iPhone required; iPad screenshots too unless the
      target is restricted to iPhone-only in Xcode (Info.plist currently
      declares iPad orientations)
- [ ] Age rating questionnaire (education/religion, no UGC → 4+)
- [ ] App Store Connect → select the TestFlight build → Add for Review →
      Submit (first review typically 1–3 days)
- [ ] After approval: release manually or automatically; verify the store
      listing renders RTL text correctly

## Later (Phase 2)
- Sentry crash reporting (then update data-safety form)
- Supabase project: apply `supabase/migrations/`, upload `dist/` snapshots,
  point the app's meta.json check at storage (currently bundled-asset only)
