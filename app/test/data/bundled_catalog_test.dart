import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/catalog_repository.dart';
import 'package:masar/data/models/catalog.dart';

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
}
