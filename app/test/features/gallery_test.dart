import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/app/theme.dart';
import 'package:masar/data/providers.dart';
import 'package:masar/features/gallery/gallery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpGallery(WidgetTester tester, Brightness brightness) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: buildTheme(brightness),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: GalleryScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'gallery renders all sections without layout errors ($brightness)',
      (tester) async {
        await pumpGallery(tester, brightness);

        await tester.scrollUntilVisible(
          find.text('هياكل التحميل'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('هياكل التحميل'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
