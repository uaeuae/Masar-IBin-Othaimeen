import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/app/app.dart';

void main() {
  testWidgets('app boots into the gallery, laid out RTL', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasarApp()));
    await tester.pump();

    expect(find.text('معرض المكونات'), findsOneWidget);

    final context = tester.element(find.text('معرض المكونات'));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context).languageCode, 'ar');
  });

  testWidgets('theme toggle cycles system → light → dark', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasarApp()));
    await tester.pump();

    BuildContext context() => tester.element(find.text('معرض المكونات'));
    expect(Theme.of(context()).brightness, Brightness.light);

    // system → light
    await tester.tap(find.byIcon(Icons.brightness_auto_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350)); // theme lerp animation
    expect(Theme.of(context()).brightness, Brightness.light);

    // light → dark
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(Theme.of(context()).brightness, Brightness.dark);
  });

  testWidgets('gallery scrolls through all sections without layout errors', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MasarApp()));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('هياكل التحميل'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('هياكل التحميل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
