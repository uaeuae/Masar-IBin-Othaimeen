import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/pump_app.dart';

void main() {
  testApp('app boots to the home tab, laid out RTL in Arabic', (
    tester,
    app,
  ) async {
    expect(find.text('مسار ابن عثيمين'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget); // bottom nav
    expect(find.text('ابدأ رحلتك'), findsOneWidget); // fresh user section

    final context = tester.element(find.text('مسار ابن عثيمين'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
  });

  testApp('home suggests journeys from the catalog', (tester, app) async {
    expect(find.text('مسار العقيدة'), findsOneWidget);
    expect(find.text('مسار الفقه'), findsOneWidget);
    expect(find.text('مسار الحديث'), findsOneWidget);
  });
}
