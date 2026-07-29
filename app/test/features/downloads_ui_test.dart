import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/db/database.dart';
import 'package:masar/data/download_repository.dart';
import 'package:masar/data/providers.dart';

import '../support/pump_app.dart';

/// The download *controls*. The transfer itself is covered end to end against a
/// real server in `test/data/download_test.dart`; driving one through the
/// widget tree would deadlock, because drift and real socket I/O inside
/// `runAsync` fight the FakeAsync zone widget tests run in. So these seed the
/// state a finished download leaves behind and assert the UI reflects it.
void main() {
  late Directory tempDir;
  var allowNetwork = true;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('masar-dl-ui-');
    allowNetwork = true;
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  List<Override> overrides() => [
    downloadsDirectoryProvider.overrideWithValue(() async => tempDir),
    downloadAllowedProvider.overrideWithValue(() async => allowNetwork),
  ];

  Future<void> openSeries(WidgetTester tester) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/series/sharh-riyad-alsalihin');
    await tester.pumpAndSettle();
  }

  Future<void> seedDownload(AppDatabase db, String videoId) async {
    File(
      '${tempDir.path}${Platform.pathSeparator}'
      '${DownloadRepository.fileNameFor(videoId)}',
    ).writeAsBytesSync(List<int>.filled(4096, 3));
    await db
        .into(db.downloads)
        .insertOnConflictUpdate(
          DownloadsCompanion.insert(
            videoId: videoId,
            seriesSlug: 'sharh-riyad-alsalihin',
            fileName: DownloadRepository.fileNameFor(videoId),
            state: const Value('done'),
            receivedBytes: const Value(4096),
            totalBytes: const Value(4096),
            requestedAt: DateTime.now(),
          ),
        );
  }

  testApp(
    'the series screen offers a download for the whole series',
    overrides: overrides(),
    (tester, app) async {
      await openSeries(tester);
      expect(find.text('تنزيل السلسلة للاستماع دون اتصال'), findsOneWidget);
      expect(find.byIcon(Icons.download_outlined), findsWidgets);
    },
  );

  testApp(
    'a downloaded lesson shows as stored, and the series bar counts it',
    overrides: overrides(),
    (tester, app) async {
      await seedDownload(app.db, 'fx-riyd-01');
      await openSeries(tester);

      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);
      expect(find.textContaining('تنزيل الباقي'), findsOneWidget);
    },
  );

  testApp(
    'a fully downloaded series says so and offers deletion',
    overrides: overrides(),
    (tester, app) async {
      final lessons = await app.db.select(app.db.lessons).get();
      for (final lesson in lessons.where(
        (l) => l.seriesSlug == 'sharh-riyad-alsalihin' && l.status == 'active',
      )) {
        await seedDownload(app.db, lesson.videoId);
      }
      await openSeries(tester);

      expect(find.text('السلسلة كاملة على جهازك'), findsOneWidget);
      expect(find.text('حذف'), findsOneWidget);
    },
  );

  testApp(
    'blocked by Wi-Fi policy, the user is told rather than left waiting',
    overrides: overrides(),
    (tester, app) async {
      allowNetwork = false;
      await openSeries(tester);

      await tapVisible(tester, find.text('تنزيل'));
      await tester.pump();

      expect(
        find.textContaining('التنزيل متوقف على شبكة Wi-Fi'),
        findsOneWidget,
      );
    },
  );

  testApp(
    'the downloads screen lists what is stored, grouped by series',
    overrides: overrides(),
    (tester, app) async {
      await seedDownload(app.db, 'fx-riyd-01');
      await seedDownload(app.db, 'fx-riyd-02');

      final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
      GoRouter.of(context).push('/downloads');
      await tester.pumpAndSettle();

      expect(find.textContaining('يشغل'), findsOneWidget);
      expect(find.text('شرح رياض الصالحين'), findsOneWidget);
      expect(find.text('حذف جميع التنزيلات'), findsOneWidget);
    },
  );

  testApp(
    'the downloads screen is empty-stated before anything is stored',
    overrides: overrides(),
    (tester, app) async {
      final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
      GoRouter.of(context).push('/downloads');
      await tester.pumpAndSettle();

      expect(find.text('لا توجد تنزيلات'), findsOneWidget);
      expect(find.text('لا توجد دروس منزّلة بعد.'), findsOneWidget);
    },
  );
}
