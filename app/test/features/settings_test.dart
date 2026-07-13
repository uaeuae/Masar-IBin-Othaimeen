import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_app.dart';

void main() {
  testApp('settings switches theme to dark and persists it', (
    tester,
    app,
  ) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);

    await tester.tap(find.text('داكن'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('الإعدادات'));
    expect(Theme.of(context).brightness, Brightness.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testApp('autoplay toggle persists', (tester, app) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('autoplay_next'), isFalse);
  });
}
