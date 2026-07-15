import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Scrolls the target into view if needed, then taps it and settles.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
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
}) {
  testWidgets(description, (tester) async {
    SharedPreferences.setMockInitialValues({});
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

    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(prefs),
            playerEngineFactoryProvider.overrideWithValue(() => engine),
            audioEngineFactoryProvider.overrideWithValue(() => audioEngine),
            // The fixture is imported above; the real bootstrap would load
            // the bundled asset (real I/O — deadlocks under FakeAsync) and
            // overwrite the fixture with the production catalog.
            catalogReadyProvider.overrideWith((ref) async {}),
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
