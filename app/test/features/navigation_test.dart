import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testApp('tabs switch between home, journeys, and library', (
    tester,
    app,
  ) async {
    await tester.tap(find.text('المسارات'));
    await tester.pumpAndSettle();
    expect(find.text('المسارات التعليمية'), findsOneWidget);
    expect(find.text('كل العلوم'), findsOneWidget);

    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    expect(find.text('العقيدة'), findsOneWidget);
    expect(find.text('سلسلتان'), findsWidgets); // aqeedah has 2 series
  });

  testApp('level filter narrows the journeys list', (tester, app) async {
    await tester.tap(find.text('المسارات'));
    await tester.pumpAndSettle();

    // Lazy list: only assert on what's above the fold before filtering.
    expect(find.text('مسار العقيدة'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'متوسط'));
    await tester.pumpAndSettle();
    expect(find.text('مسار الفقه'), findsOneWidget);
    expect(find.text('مسار العقيدة'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'متقدم'));
    await tester.pumpAndSettle();
    expect(find.text('لا مسارات تطابق التصفية'), findsOneWidget);
  });

  testApp('journey detail shows stages and enrolling updates home', (
    tester,
    app,
  ) async {
    await tapVisible(tester, find.text('مسار العقيدة'));

    expect(find.textContaining('المرحلة الأولى'), findsOneWidget);
    expect(find.textContaining('المرحلة الثانية'), findsOneWidget);
    expect(find.text('شرح ثلاثة الأصول'), findsOneWidget);

    await tapVisible(tester, find.text('ابدأ المسار'));
    expect(find.text('ابدأ المسار'), findsNothing);
    expect(find.text('٪٠'), findsOneWidget);

    // pageBack() searches for an English "Back" tooltip; ours is Arabic.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Home keeps its scroll offset; the new section header is at the top.
    await tester.scrollUntilVisible(
      find.text('مساراتي'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('مساراتي'), findsOneWidget);
  });

  testApp('series detail lists lessons and opens the player route', (
    tester,
    app,
  ) async {
    await tapVisible(tester, find.text('مسار العقيدة'));
    await tapVisible(tester, find.text('شرح ثلاثة الأصول'));

    expect(find.text('ابدأ المشاهدة'), findsOneWidget);
    expect(
      find.textContaining('٨ دروس'),
      findsOneWidget,
    ); // part of the meta line
    expect(find.textContaining('المسائل الأربع'), findsOneWidget);

    await tapVisible(tester, find.text('ابدأ المشاهدة'));
    expect(find.text('الدرس ١ من ٨'), findsOneWidget);
    expect(find.text('التالي'), findsOneWidget);
  });

  testApp('unavailable lesson is flagged in series detail', (
    tester,
    app,
  ) async {
    await tester.tap(find.text('المكتبة'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('العقيدة'));
    await tapVisible(tester, find.text('شرح العقيدة الواسطية'));

    await tester.scrollUntilVisible(
      find.text('هذا الدرس غير متاح حاليًا'),
      300,
    );
    expect(find.text('هذا الدرس غير متاح حاليًا'), findsOneWidget);
  });
}
