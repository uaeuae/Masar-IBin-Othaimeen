import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/app/app.dart';
import 'package:masar/data/catalog_repository.dart';
import 'package:masar/data/db/database.dart';
import 'package:masar/data/models/catalog.dart';
import 'package:masar/data/providers.dart';
import 'package:masar/features/player/audio_engine.dart';
import 'package:masar/features/player/player_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_audio_engine.dart';
import 'fake_engine.dart';
import 'test_db.dart';

typedef PumpedApp = ({
  AppDatabase db,
  FakeLessonPlayerEngine engine,
  FakeAudioLessonEngine audioEngine,
});

/// Serves the frozen fixture where the app expects its bundled catalog.
///
/// `rootBundle` does real file I/O, which deadlocks under the widget-test
/// FakeAsync clock — so anything that re-reads the bundle would hang a test
/// rather than be covered by one. Pull-to-refresh re-reads it, which is why
/// this exists.
class _FixtureBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != CatalogRepository.bundledCatalogAsset) {
      throw FlutterError('unexpected asset in a test: $key');
    }
    final bytes = utf8.encode(
      File('test/support/fixture_catalog.json').readAsStringSync(),
    );
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }
}

/// Scrolls the target into view if needed, then taps it and settles.
///
/// A lazy ListView never builds its off-screen children, so `ensureVisible`
/// alone fails with "No element" on anything below the fold — the widget does
/// not exist yet to be made visible. Scroll first when nothing matches.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: scrollables.first,
      );
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Defines a widget test that runs against the full app booted with an
/// in-memory database (pre-loaded with the bundled fixture catalog) and a
/// scriptable fake player engine.
///
/// The tree is unmounted and pumped once more INSIDE the test body: drift
/// stream teardown schedules zero-duration timers on unmount, and flushing
/// them here keeps the binding's pending-timer invariant green.
void testApp(
  String description,
  Future<void> Function(WidgetTester tester, PumpedApp app) body, {
  bool importCatalog = true,
  List<Override> overrides = const [],

  /// Coach marks are marked already-seen by default: they cover the screen on
  /// first launch, and every other test would be fighting an overlay. A test
  /// about onboarding sets this true.
  bool showCoachMarks = false,

  /// Runs after the catalog import but before the app is pumped, for state the
  /// very first build must already see — coach marks, for instance, decide
  /// what to point at on that build and never reconsider.
  Future<void> Function(AppDatabase db)? seed,
}) {
  testWidgets(description, (tester) async {
    SharedPreferences.setMockInitialValues(
      showCoachMarks
          ? {}
          : {
              'seen_coach_marks': ['home', 'player'],
            },
    );
    final prefs = await SharedPreferences.getInstance();
    final db = openTestDatabase();
    final engine = FakeLessonPlayerEngine();
    final audioEngine = FakeAudioLessonEngine();

    if (importCatalog) {
      // Frozen copy of the original hand-written fixture: tests must not
      // depend on the real (synced) catalog bundled in assets/.
      final raw = File('test/support/fixture_catalog.json').readAsStringSync();
      await CatalogRepository(db).importCatalog(
        CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    }

    if (seed != null) await seed(db);

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            assetBundleProvider.overrideWithValue(_FixtureBundle()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerEngineFactoryProvider.overrideWithValue(() => engine),
            audioEngineFactoryProvider.overrideWithValue(() => audioEngine),
            // The fixture is imported above, so the bootstrap has nothing left
            // to do. It reads through [_FixtureBundle] either way now, which is
            // what lets pull-to-refresh — which re-reads the bundle — be tested
            // at all rather than hang.
            catalogReadyProvider.overrideWith((ref) async {}),
            ...overrides,
          ],
          child: const MasarApp(),
        ),
      );
      await tester.pumpAndSettle();
      await body(tester, (db: db, engine: engine, audioEngine: audioEngine));
    } finally {
      // Unmount inside the body so drift's zero-duration stream-close timers
      // fire under our pumps, not after the binding's invariant check.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Deliberately NOT closing the in-memory db: drift's close() awaits
      // completions tied to FakeAsync timers and deadlocks widget tests.
      // Leaking it in a throwaway test process is harmless.
    }
  });
}
