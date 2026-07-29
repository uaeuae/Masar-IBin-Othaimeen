import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/catalog_repository.dart';
import 'package:masar/data/models/catalog.dart';
import 'package:masar/data/models/enums.dart';
import 'package:masar/features/player/lesson_text.dart';

import '../support/test_db.dart';

/// Guards the REAL bundled asset (refreshed by `npm run publish:catalog`):
/// whatever the pipeline produced must parse and import cleanly, or the app
/// would ship a broken first-run experience.
void main() {
  test('bundled catalog.json parses and imports into drift', () async {
    final raw = File('assets/catalog/catalog.json').readAsStringSync();
    final data = CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(data.journeys, isNotEmpty);
    expect(data.series, isNotEmpty);
    final lessonTotal = data.series.fold<int>(0, (n, s) => n + s.lessons.length);
    expect(lessonTotal, greaterThanOrEqualTo(data.series.length));

    final db = openTestDatabase();
    final repo = CatalogRepository(db);
    await repo.importCatalog(data);

    final journeys = await repo.watchJourneySummaries().first;
    expect(journeys.length, data.journeys.length);
    // Every published journey must resolve to at least one lesson.
    for (final journey in journeys) {
      expect(journey.lessonCount, greaterThan(0), reason: journey.slug);
    }
    await db.close();
  });

  test('every audio lesson carries a sane loudness correction', () async {
    final raw = File('assets/catalog/catalog.json').readAsStringSync();
    final data = CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    final audio = [
      for (final series in data.series)
        for (final lesson in series.lessons)
          if (lesson.media == LessonMedia.audio &&
              lesson.status == LessonStatus.active)
            lesson,
    ];
    expect(audio, isNotEmpty);

    final measured = audio.where((l) => l.gainDb != null).toList();
    // The whole library has been measured; a big regression here means
    // `analyze:loudness` was skipped before publishing.
    expect(measured.length / audio.length, greaterThan(0.95));
    for (final lesson in measured) {
      // Matches the clamp in tools/ingest/src/loudness.ts.
      expect(lesson.gainDb, inInclusiveRange(-12, 8), reason: lesson.titleAr);
    }
  });

  test('every lesson flagged with a text_kind has a readable script', () async {
    final raw = File('assets/catalog/catalog.json').readAsStringSync();
    final data = CatalogData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final flagged = [
      for (final series in data.series)
        for (final lesson in series.lessons)
          if (lesson.textKind != null) lesson,
    ];
    expect(flagged, isNotEmpty);

    for (final lesson in flagged) {
      final file = File(
        'assets/texts/${lesson.youtubeVideoId}.json.gz',
      );
      expect(file.existsSync(), isTrue, reason: lesson.youtubeVideoId);

      final text = LessonText.fromJson(
        jsonDecode(utf8.decode(gzip.decode(file.readAsBytesSync())))
            as Map<String, dynamic>,
      );
      expect(text.kind, lesson.textKind, reason: lesson.youtubeVideoId);
      expect(text.sections, isNotEmpty, reason: lesson.youtubeVideoId);

      // Estimated times must never run backwards or past the lesson — the
      // highlight would jump around or stall on the last sentence.
      var previous = -1;
      for (final sentence in text.sentences) {
        final t = sentence.t;
        if (t == null) continue;
        expect(t, greaterThanOrEqualTo(previous), reason: lesson.youtubeVideoId);
        previous = t;
      }
      final duration = lesson.durationSeconds;
      if (duration != null && previous >= 0) {
        expect(previous, lessThanOrEqualTo(duration), reason: lesson.youtubeVideoId);
      }
    }
  });
}
