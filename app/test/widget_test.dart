import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testApp('app boots to the home tab, laid out RTL in Arabic', (
    tester,
    app,
  ) async {
    expect(find.text('أهلًا بك يا طالب العلم'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget); // bottom nav
    expect(find.text('ابدأ رحلتك'), findsOneWidget); // fresh user section

    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
  });

  testApp('home suggests beginner journeys with their series preview', (
    tester,
    app,
  ) async {
    // Default level is مبتدئ → the two beginner fixture journeys.
    expect(find.text('مسار العقيدة'), findsOneWidget);
    expect(find.text('مسار الحديث'), findsOneWidget);
    expect(find.text('مسار الفقه'), findsNothing); // intermediate
    expect(
      find.textContaining('شرح ثلاثة الأصول ←'),
      findsOneWidget,
    ); // sequence teaser
  });
}
