import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'db/database.dart';
import 'models/catalog.dart';
import 'models/enums.dart';
import 'view_models.dart';

/// The offline-first heart of the app: imports catalog snapshots into drift
/// and answers every catalog+progress read the screens need.
///
/// Import rules:
/// - catalog tables are replaced wholesale, in one transaction
/// - user tables (lesson_progress, journey_enrollments) are NEVER touched
class CatalogRepository {
  CatalogRepository(this.db, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AppDatabase db;
  final AssetBundle _bundle;

  static const bundledCatalogAsset = 'assets/catalog/catalog.json';

  // ── Bootstrap & import ────────────────────────────────────────────────

  Future<int> currentVersion() async {
    final row = await db.select(db.catalogInfo).getSingleOrNull();
    return row?.version ?? 0;
  }

  /// Called at startup: guarantees a usable catalog with zero network, and
  /// upgrades in place when an app update ships a newer bundled snapshot.
  /// User tables (progress, enrollments) survive imports untouched.
  Future<void> ensureLoaded() async {
    final raw = await _bundle.loadString(bundledCatalogAsset);
    final data = CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    if (data.version <= await currentVersion()) return;
    await importCatalog(data);
  }

  Future<void> importCatalog(CatalogData data) {
    return db.transaction(() async {
      await db.delete(db.journeyItems).go();
      await db.delete(db.journeyStages).go();
      await db.delete(db.journeys).go();
      await db.delete(db.lessons).go();
      await db.delete(db.seriesEntries).go();
      await db.delete(db.sciences).go();

      await db.batch((batch) {
        batch.insertAll(db.sciences, [
          for (final s in data.sciences)
            SciencesCompanion.insert(
              slug: s.slug,
              nameAr: s.nameAr,
              descriptionAr: Value(s.descriptionAr),
              icon: Value(s.icon),
              sortOrder: Value(s.sortOrder),
            ),
        ]);
        batch.insertAll(db.seriesEntries, [
          for (final s in data.series)
            SeriesEntriesCompanion.insert(
              slug: s.slug,
              scienceSlug: s.science,
              titleAr: s.titleAr,
              descriptionAr: Value(s.descriptionAr),
              thumbnailUrl: Value(s.thumbnailUrl),
              level: Value(s.level?.name),
              mediaType: Value(s.media.name),
            ),
        ]);
        batch.insertAll(db.lessons, [
          for (final s in data.series)
            for (final l in s.lessons)
              LessonsCompanion.insert(
                videoId: l.youtubeVideoId,
                seriesSlug: s.slug,
                position: l.position,
                titleAr: l.titleAr,
                durationSeconds: Value(l.durationSeconds),
                status: Value(l.status.name),
                mediaType: Value(l.media.name),
                audioUrl: Value(l.audioUrl),
                chaptersJson: Value(
                  l.chapters.isEmpty
                      ? null
                      : jsonEncode([
                          for (final c in l.chapters)
                            {
                              'start_seconds': c.startSeconds,
                              'title': c.title,
                              'body': c.body,
                            },
                        ]),
                ),
              ),
        ]);
        batch.insertAll(db.journeys, [
          for (final j in data.journeys)
            JourneysCompanion.insert(
              slug: j.slug,
              titleAr: j.titleAr,
              descriptionAr: Value(j.descriptionAr),
              level: j.level.name,
              scienceSlug: Value(j.science),
              coverUrl: Value(j.coverUrl),
              sortOrder: Value(j.sortOrder),
            ),
        ]);
        batch.insertAll(db.journeyStages, [
          for (final j in data.journeys)
            for (final (stageIndex, stage) in j.stages.indexed)
              JourneyStagesCompanion.insert(
                journeySlug: j.slug,
                position: stageIndex + 1,
                titleAr: stage.titleAr,
                descriptionAr: Value(stage.descriptionAr),
              ),
        ]);
        batch.insertAll(db.journeyItems, [
          for (final j in data.journeys)
            for (final (stageIndex, stage) in j.stages.indexed)
              for (final (itemIndex, item) in stage.items.indexed)
                JourneyItemsCompanion.insert(
                  journeySlug: j.slug,
                  stagePosition: stageIndex + 1,
                  position: itemIndex + 1,
                  seriesSlug: item.series,
                ),
        ]);
      });

      await db
          .into(db.catalogInfo)
          .insertOnConflictUpdate(
            CatalogInfoCompanion(
              id: const Value(1),
              version: Value(data.version),
              generatedAt: Value(data.generatedAt),
            ),
          );
    });
  }

  // ── Journey queries ───────────────────────────────────────────────────

  static const _journeySummarySql = '''
    SELECT j.slug, j.title_ar, j.description_ar, j.level, j.science_slug, j.cover_url,
      (SELECT COUNT(*) FROM journey_stages st WHERE st.journey_slug = j.slug) AS stage_count,
      (SELECT COUNT(*) FROM lessons l
         JOIN journey_items i ON l.series_slug = i.series_slug
        WHERE i.journey_slug = j.slug AND l.status = 'active') AS lesson_count,
      (SELECT COUNT(*) FROM lessons l
         JOIN journey_items i ON l.series_slug = i.series_slug
         JOIN lesson_progress p ON p.video_id = l.video_id AND p.completed = 1
        WHERE i.journey_slug = j.slug AND l.status = 'active') AS completed_count,
      (SELECT COALESCE(SUM(l.duration_seconds), 0) FROM lessons l
         JOIN journey_items i ON l.series_slug = i.series_slug
        WHERE i.journey_slug = j.slug AND l.status = 'active') AS total_duration,
      EXISTS(SELECT 1 FROM journey_enrollments e WHERE e.journey_slug = j.slug) AS enrolled
    FROM journeys j
  ''';

  JourneySummary _summaryFromRow(QueryRow row, {String seriesPreview = ''}) =>
      JourneySummary(
        slug: row.read<String>('slug'),
        titleAr: row.read<String>('title_ar'),
        descriptionAr: row.readNullable<String>('description_ar'),
        level: JourneyLevel.fromJson(row.read<String>('level')),
        scienceSlug: row.readNullable<String>('science_slug'),
        coverUrl: row.readNullable<String>('cover_url'),
        stageCount: row.read<int>('stage_count'),
        lessonCount: row.read<int>('lesson_count'),
        completedCount: row.read<int>('completed_count'),
        totalDurationSeconds: row.read<int>('total_duration'),
        enrolled: row.read<int>('enrolled') != 0,
        seriesPreview: seriesPreview,
      );

  /// journey slug → "ثلاثة الأصول ← القواعد الأربع ← ..." (stage order).
  Future<Map<String, String>> _seriesPreviews() async {
    final rows = await db.customSelect('''
      SELECT i.journey_slug, s.title_ar FROM journey_items i
      JOIN series s ON s.slug = i.series_slug
      ORDER BY i.journey_slug, i.stage_position, i.position
    ''').get();
    final titlesByJourney = <String, List<String>>{};
    for (final row in rows) {
      titlesByJourney
          .putIfAbsent(row.read<String>('journey_slug'), () => [])
          .add(row.read<String>('title_ar'));
    }
    return titlesByJourney.map(
      (slug, titles) => MapEntry(slug, titles.join(' ← ')),
    );
  }

  Set<ResultSetImplementation> get _journeyReads => {
    db.journeys,
    db.journeyStages,
    db.journeyItems,
    db.lessons,
    db.lessonProgress,
    db.journeyEnrollments,
  };

  Stream<List<JourneySummary>> watchJourneySummaries() {
    return db
        .customSelect(
          '$_journeySummarySql ORDER BY j.sort_order, j.slug',
          readsFrom: _journeyReads,
        )
        .watch()
        .asyncMap((rows) async {
          final previews = await _seriesPreviews();
          return [
            for (final row in rows)
              _summaryFromRow(
                row,
                seriesPreview: previews[row.read<String>('slug')] ?? '',
              ),
          ];
        });
  }

  Stream<List<JourneySummary>> watchEnrolledJourneys() {
    return db
        .customSelect(
          '$_journeySummarySql '
          'JOIN journey_enrollments e ON e.journey_slug = j.slug '
          'ORDER BY e.last_activity_at DESC',
          readsFrom: _journeyReads,
        )
        .watch()
        .asyncMap((rows) async {
          final previews = await _seriesPreviews();
          return [
            for (final row in rows)
              _summaryFromRow(
                row,
                seriesPreview: previews[row.read<String>('slug')] ?? '',
              ),
          ];
        });
  }

  Stream<JourneyDetail?> watchJourneyDetail(String slug) {
    final itemsQuery = db.customSelect(
      '''
      SELECT i.stage_position, i.position, s.slug, s.title_ar, s.description_ar, s.thumbnail_url, s.science_slug, s.level, s.media_type,
        (SELECT COUNT(*) FROM lessons l WHERE l.series_slug = s.slug AND l.status = 'active') AS lesson_count,
        (SELECT COALESCE(SUM(l.duration_seconds), 0) FROM lessons l
          WHERE l.series_slug = s.slug AND l.status = 'active') AS total_duration,
        (SELECT COUNT(*) FROM lessons l
           JOIN lesson_progress p ON p.video_id = l.video_id AND p.completed = 1
          WHERE l.series_slug = s.slug AND l.status = 'active') AS completed_count
      FROM journey_items i
      JOIN series s ON s.slug = i.series_slug
      WHERE i.journey_slug = ?
      ORDER BY i.stage_position, i.position
      ''',
      variables: [Variable.withString(slug)],
      // The summary/stages are re-fetched inside asyncMap, so every table
      // they read must be listed here — notably journey_enrollments, or the
      // detail screen would never react to enrolling.
      readsFrom: {
        db.journeyItems,
        db.seriesEntries,
        db.lessons,
        db.lessonProgress,
        db.journeys,
        db.journeyStages,
        db.journeyEnrollments,
      },
    );

    return itemsQuery.watch().asyncMap((itemRows) async {
      final summaryRow = await db
          .customSelect(
            '$_journeySummarySql WHERE j.slug = ?',
            variables: [Variable.withString(slug)],
          )
          .getSingleOrNull();
      if (summaryRow == null) return null;

      final stageRows =
          await (db.select(db.journeyStages)
                ..where((s) => s.journeySlug.equals(slug))
                ..orderBy([(s) => OrderingTerm.asc(s.position)]))
              .get();

      final seriesByStage = <int, List<SeriesWithProgress>>{};
      for (final row in itemRows) {
        seriesByStage
            .putIfAbsent(row.read<int>('stage_position'), () => [])
            .add(
              SeriesWithProgress(
                slug: row.read<String>('slug'),
                titleAr: row.read<String>('title_ar'),
                descriptionAr: row.readNullable<String>('description_ar'),
                thumbnailUrl: row.readNullable<String>('thumbnail_url'),
                scienceSlug: row.read<String>('science_slug'),
                lessonCount: row.read<int>('lesson_count'),
                completedCount: row.read<int>('completed_count'),
                totalDurationSeconds: row.read<int>('total_duration'),
                level: _levelOrNull(row.readNullable<String>('level')),
                media: LessonMedia.fromJson(row.read<String>('media_type')),
              ),
            );
      }

      return JourneyDetail(
        summary: _summaryFromRow(summaryRow),
        stages: [
          for (final stage in stageRows)
            StageDetail(
              position: stage.position,
              titleAr: stage.titleAr,
              descriptionAr: stage.descriptionAr,
              series: seriesByStage[stage.position] ?? const [],
            ),
        ],
      );
    });
  }

  // ── Series & lesson queries ───────────────────────────────────────────

  Stream<SeriesDetail?> watchSeriesDetail(String slug) {
    final lessonsQuery = db.customSelect(
      '''
      SELECT l.video_id, l.position, l.title_ar, l.duration_seconds, l.status,
        l.media_type, l.audio_url, l.chapters_json,
        COALESCE(p.watched_seconds, 0) AS watched_seconds,
        COALESCE(p.completed, 0) AS completed
      FROM lessons l
      LEFT JOIN lesson_progress p ON p.video_id = l.video_id
      WHERE l.series_slug = ? AND l.status != 'hidden'
      ORDER BY l.position
      ''',
      variables: [Variable.withString(slug)],
      readsFrom: {db.lessons, db.lessonProgress},
    );

    return lessonsQuery.watch().asyncMap((lessonRows) async {
      final seriesRow = await (db.select(
        db.seriesEntries,
      )..where((s) => s.slug.equals(slug))).getSingleOrNull();
      if (seriesRow == null) return null;

      final lessons = [
        for (final row in lessonRows)
          LessonWithProgress(
            videoId: row.read<String>('video_id'),
            position: row.read<int>('position'),
            titleAr: row.read<String>('title_ar'),
            durationSeconds: row.readNullable<int>('duration_seconds'),
            status: LessonStatus.fromJson(row.read<String>('status')),
            watchedSeconds: row.read<int>('watched_seconds'),
            completed: row.read<int>('completed') != 0,
            media: LessonMedia.fromJson(row.read<String>('media_type')),
            audioUrl: row.readNullable<String>('audio_url'),
            chapters: _chaptersFromJson(
              row.readNullable<String>('chapters_json'),
            ),
          ),
      ];

      final active = lessons
          .where((l) => l.status == LessonStatus.active)
          .toList();
      return SeriesDetail(
        series: SeriesWithProgress(
          slug: seriesRow.slug,
          titleAr: seriesRow.titleAr,
          descriptionAr: seriesRow.descriptionAr,
          thumbnailUrl: seriesRow.thumbnailUrl,
          scienceSlug: seriesRow.scienceSlug,
          lessonCount: active.length,
          completedCount: active.where((l) => l.completed).length,
          totalDurationSeconds: active.fold(
            0,
            (sum, l) => sum + (l.durationSeconds ?? 0),
          ),
          level: _levelOrNull(seriesRow.level),
          media: LessonMedia.fromJson(seriesRow.mediaType),
        ),
        lessons: lessons,
      );
    });
  }

  Stream<List<ContinueWatchingItem>> watchContinueWatching({int limit = 10}) {
    return db
        .customSelect(
          '''
          SELECT l.video_id, l.title_ar, l.duration_seconds, l.series_slug, l.position,
            s.title_ar AS series_title, p.watched_seconds, p.last_watched_at
          FROM lesson_progress p
          JOIN lessons l ON l.video_id = p.video_id AND l.status = 'active'
          JOIN series s ON s.slug = l.series_slug
          WHERE p.completed = 0 AND p.watched_seconds >= 30
          ORDER BY p.last_watched_at DESC
          LIMIT $limit
          ''',
          readsFrom: {db.lessonProgress, db.lessons, db.seriesEntries},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              ContinueWatchingItem(
                videoId: row.read<String>('video_id'),
                titleAr: row.read<String>('title_ar'),
                position: row.read<int>('position'),
                seriesSlug: row.read<String>('series_slug'),
                seriesTitleAr: row.read<String>('series_title'),
                watchedSeconds: row.read<int>('watched_seconds'),
                durationSeconds: row.readNullable<int>('duration_seconds'),
                lastWatchedAt: DateTime.fromMillisecondsSinceEpoch(
                  row.read<int>('last_watched_at') * 1000,
                ),
              ),
          ],
        );
  }

  // ── Library queries ───────────────────────────────────────────────────

  Stream<List<ScienceSummary>> watchSciences() {
    return db
        .customSelect(
          '''
          SELECT sc.slug, sc.name_ar, sc.description_ar, sc.icon, sc.sort_order,
            (SELECT COUNT(*) FROM series s WHERE s.science_slug = sc.slug) AS series_count,
            (SELECT COUNT(*) FROM lessons l
               JOIN series s ON s.slug = l.series_slug
              WHERE s.science_slug = sc.slug AND l.status = 'active') AS lesson_count
          FROM sciences sc
          ORDER BY sc.sort_order
          ''',
          readsFrom: {db.sciences, db.seriesEntries, db.lessons},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              ScienceSummary(
                slug: row.read<String>('slug'),
                nameAr: row.read<String>('name_ar'),
                sortOrder: row.read<int>('sort_order'),
                lessonCount: row.read<int>('lesson_count'),
                descriptionAr: row.readNullable<String>('description_ar'),
                icon: row.readNullable<String>('icon'),
                seriesCount: row.read<int>('series_count'),
              ),
          ],
        );
  }

  Stream<List<SeriesWithProgress>> watchSeriesByScience(String scienceSlug) {
    return db
        .customSelect(
          '''
          SELECT s.slug, s.title_ar, s.description_ar, s.thumbnail_url, s.science_slug, s.level, s.media_type,
            (SELECT COUNT(*) FROM lessons l WHERE l.series_slug = s.slug AND l.status = 'active') AS lesson_count,
            (SELECT COALESCE(SUM(l.duration_seconds), 0) FROM lessons l
              WHERE l.series_slug = s.slug AND l.status = 'active') AS total_duration,
            (SELECT COUNT(*) FROM lessons l
               JOIN lesson_progress p ON p.video_id = l.video_id AND p.completed = 1
              WHERE l.series_slug = s.slug AND l.status = 'active') AS completed_count
          FROM series s
          WHERE s.science_slug = ?
          ORDER BY s.title_ar
          ''',
          variables: [Variable.withString(scienceSlug)],
          readsFrom: {db.seriesEntries, db.lessons, db.lessonProgress},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              SeriesWithProgress(
                slug: row.read<String>('slug'),
                titleAr: row.read<String>('title_ar'),
                descriptionAr: row.readNullable<String>('description_ar'),
                thumbnailUrl: row.readNullable<String>('thumbnail_url'),
                scienceSlug: row.read<String>('science_slug'),
                lessonCount: row.read<int>('lesson_count'),
                completedCount: row.read<int>('completed_count'),
                totalDurationSeconds: row.read<int>('total_duration'),
                level: _levelOrNull(row.readNullable<String>('level')),
                media: LessonMedia.fromJson(row.read<String>('media_type')),
              ),
          ],
        );
  }
}

JourneyLevel? _levelOrNull(String? value) =>
    value == null ? null : JourneyLevel.fromJson(value);

List<CatalogChapter> _chaptersFromJson(String? json) {
  if (json == null || json.isEmpty) return const [];
  final raw = jsonDecode(json) as List<dynamic>;
  return [
    for (final entry in raw.cast<Map<String, dynamic>>())
      CatalogChapter(
        startSeconds: entry['start_seconds'] as int?,
        title: entry['title'] as String? ?? '',
        body: entry['body'] as String? ?? '',
      ),
  ];
}
