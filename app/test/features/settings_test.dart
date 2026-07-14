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

    // First switch is autoplay (on by default), second is the daily reminder.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('autoplay_next'), isFalse);
  });

  testApp('attribution and version footer are present', (tester, app) async {
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Masar v1.0.0'), 300);
    expect(
      find.textContaining('مؤسسة الشيخ محمد بن صالح العثيمين الخيرية'),
      findsOneWidget,
    );
  });
}
