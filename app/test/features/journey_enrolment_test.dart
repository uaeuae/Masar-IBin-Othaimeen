import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/catalog_repository.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/pump_app.dart';

/// «مساراتي» should hold the مسارات you are actually working through.
///
/// It used to hold only the ones you had found and tapped «التحق» on. A reader
/// who reached a lesson from the library, from search, or from the resume card
/// could listen through a whole book and still see «مساراتي» showing someone
/// else's مسار — which is exactly what happened with ابن باز's شرح كتاب
/// التوحيد, made harder to spot because ابن عثيمين has a مسار of the same name
/// starting with a series of the same name.
void main() {
  testApp('listening to a lesson enrols in the مسار that teaches it', (
    tester,
    app,
  ) async {
    final catalog = CatalogRepository(app.db);
    expect(await catalog.watchEnrolledJourneys().first, isEmpty);

    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(
      context,
    ).push('/player/baz-tawhid-01?series=baz-sharh-kitab-altawhid');
    await tester.pumpAndSettle();

    final enrolled = await catalog.watchEnrolledJourneys().first;
    expect(enrolled.map((j) => j.slug), contains('masar-alaqeedah-binbaz'));
  });

  testApp('a مسار removed from الرئيسية stays removed', (tester, app) async {
    final progress = ProgressRepository(app.db);
    final catalog = CatalogRepository(app.db);

    await progress.enrolInJourneysOf('baz-sharh-kitab-altawhid');
    await progress.leaveJourney('masar-alaqeedah-binbaz');
    Future<List<String>> shown() async =>
        (await catalog.watchEnrolledJourneys().first)
            .map((j) => j.slug)
            .toList();
    expect(await shown(), isNot(contains('masar-alaqeedah-binbaz')));

    // The whole point of the flag: playing another lesson must not drag it
    // back, or the remove button would be undone by the next thing you listen
    // to.
    await progress.enrolInJourneysOf('baz-sharh-kitab-altawhid');
    expect(await shown(), isNot(contains('masar-alaqeedah-binbaz')));
  });

  testApp('rejoining brings it back with its progress intact', (
    tester,
    app,
  ) async {
    final progress = ProgressRepository(app.db);
    final catalog = CatalogRepository(app.db);

    await progress.markCompleted('baz-tawhid-01', durationSeconds: 600);
    await progress.enrolInJourneysOf('baz-sharh-kitab-altawhid');
    await progress.leaveJourney('masar-alaqeedah-binbaz');
    await progress.enroll('masar-alaqeedah-binbaz');

    final enrolled = await catalog.watchEnrolledJourneys().first;
    final journey = enrolled.firstWhere(
      (j) => j.slug == 'masar-alaqeedah-binbaz',
    );
    // Leaving hid the مسار; it never touched a single lesson's progress.
    expect(journey.completedCount, 1);
  });

  testApp('swiping a مسار off الرئيسية asks first', (tester, app) async {
    await ProgressRepository(app.db).enrolInJourneysOf('baz-sharh-kitab-altawhid');
    await tester.pumpAndSettle();

    expect(find.text('مساراتي'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('journey-masar-alaqeedah-binbaz')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('إزالة المسار من الرئيسية؟'), findsOneWidget);
    // Says what survives, because the fear with this button is losing months
    // of listening.
    expect(find.textContaining('يبقى تقدمك في دروسه'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.text('مساراتي'), findsOneWidget);
  });

  testApp('the journeys tab filters by شيخ', (tester, app) async {
    await tester.tap(find.text('المسارات'));
    await tester.pumpAndSettle();

    // The fixture carries «مسار العقيدة» twice, once per scholar.
    expect(find.text('مسار العقيدة'), findsWidgets);

    await tester.tap(find.text('ابن باز').last);
    await tester.pumpAndSettle();

    // Ibn Uthaymeen's مسار الفقه must be gone once the filter is on ابن باز.
    expect(find.text('مسار الفقه'), findsNothing);
  });
}
