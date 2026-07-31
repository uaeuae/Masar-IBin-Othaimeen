import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/core/widgets/level_badge.dart';
import 'package:masar/core/widgets/masar_nav_bar.dart';
import 'package:masar/core/widgets/segmented_control.dart';
import 'package:masar/data/models/enums.dart';
import 'package:masar/features/journeys/journeys_screen.dart';
import 'package:masar/features/library/library_screen.dart';

import '../support/pump_app.dart';

Finder navItem(String label) =>
    find.descendant(of: find.byType(MasarNavBar), matching: find.text(label));

Finder segmentedOption(String label) => find.descendant(
  of: find.byType(SegmentedControl<JourneyLevel>),
  matching: find.text(label),
);

Finder inJourneys(Finder finder) =>
    find.descendant(of: find.byType(JourneysScreen), matching: finder);

void main() {
  testApp('tabs switch between home, journeys, and library', (
    tester,
    app,
  ) async {
    await tester.tap(navItem('المسارات'));
    await tester.pumpAndSettle();
    expect(inJourneys(find.text('المسارات')), findsOneWidget); // page title
    expect(inJourneys(find.text('الكل')), findsOneWidget); // science chips

    await tester.tap(navItem('المكتبة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تصفّح جميع سلاسل الشيخ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('الفهرس كامل متاح دون اتصال'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(LibraryScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('الفهرس كامل متاح دون اتصال'), findsOneWidget);
  });

  testApp('journeys are all listed, each tagged with its level and hours', (
    tester,
    app,
  ) async {
    await tester.tap(navItem('المسارات'));
    await tester.pumpAndSettle();

    // No level filter any more: hiding three of four journeys behind a
    // segmented control cost more than it saved.
    expect(inJourneys(find.byType(SegmentedControl<JourneyLevel>)), findsNothing);
    expect(inJourneys(find.text('مسار العقيدة')), findsOneWidget);
    expect(inJourneys(find.text('مسار الفقه')), findsOneWidget);

    // The level is a tag on the card instead, and each says how long it is.
    expect(inJourneys(find.byType(LevelBadge)), findsWidgets);
    expect(inJourneys(find.textContaining('ساعة')), findsWidgets);
  });

  testApp('journey detail CTA enrolls and opens the player', (
    tester,
    app,
  ) async {
    await tapVisible(tester, find.text('مسار العقيدة'));

    // Green header + timeline with the first stage as the current one.
    expect(find.textContaining('مرحلتان'), findsWidgets);
    expect(find.text('شرح ثلاثة الأصول'), findsOneWidget);
    expect(find.textContaining('ابدأ المسار — الدرس'), findsOneWidget);

    await tapVisible(tester, find.textContaining('ابدأ المسار — الدرس'));

    // CTA enrolls and resumes straight into lesson 1.
    expect(app.engine.loads.single.$1, 'fx-usul-01');
    final enrolled = await app.db.select(app.db.journeyEnrollments).get();
    expect(enrolled.single.journeySlug, 'masar-alaqeedah');
  });

  testApp('series detail lists lessons and opens the player', (
    tester,
    app,
  ) async {
    await tapVisible(tester, find.text('مسار العقيدة'));
    await tapVisible(tester, find.text('شرح ثلاثة الأصول'));

    expect(find.textContaining('٨ دروس'), findsOneWidget);
    expect(
      find.textContaining('ابدأ — الدرس'),
      findsOneWidget,
    ); // resume banner
    // The lesson list sits below «عن الكتاب»; a lazy ListView has not built it
    // until it is scrolled to.
    await tester.scrollUntilVisible(
      find.textContaining('المسائل الأربع'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('المسائل الأربع'), findsOneWidget);

    await tapVisible(tester, find.textContaining('ابدأ — الدرس'));
    expect(find.textContaining('١ / ٨'), findsOneWidget); // player breadcrumb
    expect(find.text('التالي'), findsOneWidget);
  });

  testApp('unavailable lesson is flagged in series detail', (
    tester,
    app,
  ) async {
    await tester.tap(navItem('المكتبة'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('العقيدة'));
    await tapVisible(tester, find.text('شرح العقيدة الواسطية'));

    await tester.scrollUntilVisible(
      find.textContaining('غير متاح حاليًا'),
      300,
    );
    expect(find.textContaining('غير متاح حاليًا'), findsOneWidget);
  });
}
