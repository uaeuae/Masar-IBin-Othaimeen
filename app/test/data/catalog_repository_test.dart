import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle, ByteData;
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/catalog_repository.dart';
import 'package:masar/data/db/database.dart';
import 'package:masar/data/models/catalog.dart';
import 'package:masar/data/models/enums.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/test_db.dart';

CatalogData loadFixture() {
  final raw = File('test/support/fixture_catalog.json').readAsStringSync();
  return CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Serves one JSON string for any asset key — a stand-in bundled catalog.
class _JsonBundle extends AssetBundle {
  _JsonBundle(this.json);

  final String json;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(json)));

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser,
  ) => loadString(key).then(parser);
}

void main() {
  late AppDatabase db;
  late CatalogRepository catalog;
  late ProgressRepository progress;

  setUp(() {
    db = openTestDatabase();
    catalog = CatalogRepository(db);
    progress = ProgressRepository(db);
  });

  tearDown(() => db.close());

  test('fixture catalog parses, imports, and round-trips', () async {
    final data = loadFixture();
    expect(data.version, 1);
    expect(data.sciences, hasLength(6));
    expect(data.series, hasLength(4));
    expect(data.journeys, hasLength(3));

    await catalog.importCatalog(data);
    expect(await catalog.currentVersion(), 1);

    final summaries = await catalog.watchJourneySummaries().first;
    expect(summaries, hasLength(3));

    final aqeedah = summaries.firstWhere((j) => j.slug == 'masar-alaqeedah');
    expect(aqeedah.level, JourneyLevel.beginner);
    expect(aqeedah.stageCount, 2);
    // 8 lessons in thalathat-alusul + 5 active in alwasitiyah (1 unavailable).
    expect(aqeedah.lessonCount, 13);
    expect(aqeedah.completedCount, 0);
    expect(aqeedah.enrolled, isFalse);
  });

  test('ensureLoaded imports newer bundled versions, skips older', () async {
    await catalog.importCatalog(loadFixture());
    expect(await catalog.currentVersion(), 1);

    // Same version → no reimport (would be wasted work on every launch).
    await CatalogRepository(
      db,
      bundle: _JsonBundle(jsonEncode(loadFixture().toJson())),
    ).ensureLoaded();
    expect(await catalog.currentVersion(), 1);

    // Newer bundled snapshot (an app update) → upgraded in place, progress kept.
    await progress.markCompleted('fx-usul-01', durationSeconds: 2700);
    final v2 = loadFixture().copyWith(version: 2);
    await CatalogRepository(
      db,
      bundle: _JsonBundle(jsonEncode(v2.toJson())),
    ).ensureLoaded();
    expect(await catalog.currentVersion(), 2);
    expect((await progress.getProgress('fx-usul-01'))?.completed, isTrue);
  });

  test('journey progress derives from lesson_progress', () async {
    await catalog.importCatalog(loadFixture());

    await progress.markCompleted('fx-usul-01', durationSeconds: 2700);
    await progress.markCompleted('fx-usul-02', durationSeconds: 3120);

    final summaries = await catalog.watchJourneySummaries().first;
    final aqeedah = summaries.firstWhere((j) => j.slug == 'masar-alaqeedah');
    expect(aqeedah.completedCount, 2);
    expect(aqeedah.progress, closeTo(2 / 13, 0.001));
  });

  test(
    'journey detail assembles stages in order with per-series progress',
    () async {
      await catalog.importCatalog(loadFixture());
      await progress.markCompleted('fx-usul-01');

      final detail = (await catalog
          .watchJourneyDetail('masar-alaqeedah')
          .first)!;
      expect(detail.stages, hasLength(2));
      expect(detail.stages.first.titleAr, contains('الأصول'));
      expect(detail.stages.first.series.single.completedCount, 1);
      expect(detail.stages.first.series.single.lessonCount, 8);
      expect(detail.currentStagePosition, 1);
      expect(detail.summary.enrolled, isFalse);

      expect(await catalog.watchJourneyDetail('no-such-journey').first, isNull);
    },
  );

  test('series detail lists lessons with progress and resume target', () async {
    await catalog.importCatalog(loadFixture());
    await progress.markCompleted('fx-zad-01', durationSeconds: 3600);
    await progress.saveWatchPosition(
      videoId: 'fx-zad-02',
      watchedSeconds: 600,
      durationSeconds: 3480,
    );

    final detail = (await catalog
        .watchSeriesDetail('sharh-zad-almustaqni')
        .first)!;
    expect(detail.lessons, hasLength(10));
    expect(detail.series.completedCount, 1);
    expect(detail.lessons[1].watchedSeconds, 600);
    expect(detail.resumeTarget?.videoId, 'fx-zad-02');
  });

  test('unavailable lessons are listed but excluded from counts', () async {
    await catalog.importCatalog(loadFixture());

    final detail = (await catalog
        .watchSeriesDetail('sharh-alwasitiyah')
        .first)!;
    expect(detail.lessons, hasLength(6));
    expect(detail.series.lessonCount, 5);
    expect(detail.lessons.last.status, LessonStatus.unavailable);
  });

  test(
    'continue watching orders by recency, needs >=30s, skips completed',
    () async {
      await catalog.importCatalog(loadFixture());
      final t0 = DateTime(2026, 7, 1, 10);
      var callCount = 0;
      final clocked = ProgressRepository(
        db,
        clock: () => t0.add(Duration(minutes: callCount++)),
      );

      await clocked.saveWatchPosition(
        videoId: 'fx-riyd-01',
        watchedSeconds: 600,
        durationSeconds: 2580,
      );
      await clocked.saveWatchPosition(
        videoId: 'fx-zad-01',
        watchedSeconds: 900,
        durationSeconds: 3600,
      );
      await clocked.saveWatchPosition(
        videoId: 'fx-usul-01',
        watchedSeconds: 10,
        durationSeconds: 2700,
      ); // too short
      await clocked.markCompleted('fx-wast-01'); // completed → excluded

      final items = await catalog.watchContinueWatching().first;
      expect(items.map((i) => i.videoId), ['fx-zad-01', 'fx-riyd-01']);
      expect(items.first.seriesTitleAr, 'شرح زاد المستقنع');
      expect(items.first.progress, closeTo(900 / 3600, 0.001));
    },
  );

  test('re-import preserves progress and enrollments', () async {
    final data = loadFixture();
    await catalog.importCatalog(data);
    await progress.markCompleted('fx-usul-01');
    await progress.enroll('masar-alaqeedah');

    await catalog.importCatalog(
      CatalogData(
        version: 2,
        sciences: data.sciences,
        series: data.series,
        journeys: data.journeys,
      ),
    );

    expect(await catalog.currentVersion(), 2);
    final summaries = await catalog.watchJourneySummaries().first;
    final aqeedah = summaries.firstWhere((j) => j.slug == 'masar-alaqeedah');
    expect(aqeedah.completedCount, 1);
    expect(aqeedah.enrolled, isTrue);
  });

  test('saveWatchPosition never un-completes a lesson', () async {
    await catalog.importCatalog(loadFixture());
    await progress.markCompleted('fx-usul-01', durationSeconds: 2700);
    await progress.saveWatchPosition(
      videoId: 'fx-usul-01',
      watchedSeconds: 120,
      durationSeconds: 2700,
    );

    final detail = (await catalog
        .watchSeriesDetail('sharh-thalathat-alusul')
        .first)!;
    expect(detail.lessons.first.completed, isTrue);
    expect(detail.lessons.first.watchedSeconds, 120);
  });

  test('sciences and series-by-science power the library', () async {
    await catalog.importCatalog(loadFixture());

    final sciences = await catalog.watchSciences().first;
    expect(sciences, hasLength(6));
    expect(sciences.first.slug, 'aqeedah'); // sort_order 1
    expect(sciences.firstWhere((s) => s.slug == 'aqeedah').seriesCount, 2);
    expect(sciences.firstWhere((s) => s.slug == 'tafsir').seriesCount, 0);

    final fiqhSeries = await catalog.watchSeriesByScience('fiqh').first;
    expect(fiqhSeries.single.slug, 'sharh-zad-almustaqni');
    expect(fiqhSeries.single.totalDurationSeconds, greaterThan(0));
  });

  test('enrolled journeys stream reflects enrollment', () async {
    await catalog.importCatalog(loadFixture());
    expect(await catalog.watchEnrolledJourneys().first, isEmpty);

    await progress.enroll('masar-alfiqh');
    final enrolled = await catalog.watchEnrolledJourneys().first;
    expect(enrolled.single.slug, 'masar-alfiqh');
  });
}
