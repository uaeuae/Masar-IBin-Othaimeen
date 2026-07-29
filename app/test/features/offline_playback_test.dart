import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/db/database.dart';
import 'package:masar/data/download_repository.dart';
import 'package:masar/data/providers.dart';
import 'package:masar/features/settings/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_app.dart';

/// The player's half of the offline feature: prefer the file on disk, and level
/// the lesson against the rest of the library.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('masar-offline-');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  List<Override> overrides() => [
    downloadsDirectoryProvider.overrideWithValue(() async => tempDir),
  ];

  Future<void> openLesson(WidgetTester tester, String id) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/player/$id?series=sharh-riyad-alsalihin');
    await tester.pumpAndSettle();
  }

  /// Puts a finished download on disk for [videoId], the way the manager would.
  Future<void> seedDownload(AppDatabase db, String videoId) async {
    final file = File(
      '${tempDir.path}${Platform.pathSeparator}'
      '${DownloadRepository.fileNameFor(videoId)}',
    );
    file.writeAsBytesSync(List<int>.filled(2048, 7));
    await db
        .into(db.downloads)
        .insertOnConflictUpdate(
          DownloadsCompanion.insert(
            videoId: videoId,
            seriesSlug: 'sharh-riyad-alsalihin',
            fileName: DownloadRepository.fileNameFor(videoId),
            state: const Value('done'),
            receivedBytes: const Value(2048),
            requestedAt: DateTime.now(),
          ),
        );
  }

  testApp('an undownloaded lesson streams from the network', overrides: overrides(), (
    tester,
    app,
  ) async {
    await openLesson(tester, 'fx-riyd-01');
    expect(app.audioEngine.lastLoadWasLocal, isFalse);
    expect(app.audioEngine.loads.single.$2, startsWith('http'));
  });

  testApp('offline copies are preferred and shown as such', overrides: overrides(), (
    tester,
    app,
  ) async {
    await seedDownload(app.db, 'fx-riyd-01');
    await openLesson(tester, 'fx-riyd-01');

    expect(app.audioEngine.lastLoadWasLocal, isTrue);
    expect(app.audioEngine.loads.single.$2, contains(tempDir.path));
    expect(find.text('تشغيل من التنزيلات'), findsOneWidget);
  });

  testApp(
    'each lesson is levelled by its measured gain',
    overrides: overrides(),
    (tester, app) async {
      await openLesson(tester, 'fx-riyd-01');
      expect(app.audioEngine.gains, [-3.5]);
    },
  );

  testApp(
    'turning normalisation off plays the file untouched',
    overrides: overrides(),
    (tester, app) async {
      SharedPreferences.setMockInitialValues({'normalize_volume': false});
      final prefs = await SharedPreferences.getInstance();
      // The already-built app holds the old prefs, so drive the notifier the
      // way the settings screen does.
      final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
      final container = ProviderScope.containerOf(context);
      container.read(normalizeVolumeProvider.notifier).set(false);
      expect(prefs.getBool('normalize_volume'), isFalse);

      await openLesson(tester, 'fx-riyd-01');
      expect(app.audioEngine.gains, [0.0]);
    },
  );
}
