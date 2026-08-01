import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_app.dart';

void main() {
  testApp('the home button that opens settings looks like settings', (
    tester,
    app,
  ) async {
    // It shipped as a clock, which promised something the tap does not do.
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.byIcon(Icons.access_time_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testApp('settings switches theme to dark and persists it', (
    tester,
    app,
  ) async {
    await tester.tap(find.byIcon(Icons.settings_rounded));
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
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    // First switch is autoplay (on by default), second is the daily reminder.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('autoplay_next'), isFalse);
  });

  testApp('attribution and version footer are present', (tester, app) async {
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();

    // Version comes from one constant now, so the footer cannot drift from
    // what a bug report claims.
    await tester.scrollUntilVisible(find.textContaining('Masar v'), 300);
    expect(
      find.textContaining('مؤسسة الشيخ محمد بن صالح العثيمين الخيرية'),
      findsOneWidget,
    );
  });
}
