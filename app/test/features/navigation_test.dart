import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testApp('level segmented control filters the journeys list', (
    tester,
    app,
  ) async {
    await tester.tap(navItem('المسارات'));
    await tester.pumpAndSettle();

    // Default مبتدئ → beginner journeys only.
    expect(inJourneys(find.text('مسار العقيدة')), findsOneWidget);
    expect(inJourneys(find.text('مسار الفقه')), findsNothing);

    await tester.tap(segmentedOption('متوسط'));
    await tester.pumpAndSettle();
    expect(inJourneys(find.text('مسار الفقه')), findsOneWidget);
    expect(inJourneys(find.text('مسار العقيدة')), findsNothing);

    await tester.tap(segmentedOption('متقدم'));
    await tester.pumpAndSettle();
    expect(inJourneys(find.text('لا مسارات تطابق التصفية')), findsOneWidget);
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
