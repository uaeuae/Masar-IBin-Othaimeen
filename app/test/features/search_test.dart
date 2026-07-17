import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_app.dart';

void main() {
  Future<void> openSearch(WidgetTester tester) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/search');
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump(const Duration(milliseconds: 300)); // debounce
    await tester.pumpAndSettle();
  }

  testApp('search finds lessons and series with grouped results', (
    tester,
    app,
  ) async {
    await openSearch(tester);
    await type(tester, 'الإخلاص');

    // Lesson hit from the riyad fixture series, grouped under دروس.
    expect(find.textContaining('دروس ·'), findsOneWidget);
    expect(find.textContaining('باب '), findsWidgets);

    await type(tester, 'رياض');
    expect(find.textContaining('سلاسل ·'), findsOneWidget);
  });

  testApp('search result opens the lesson player', (tester, app) async {
    await openSearch(tester);
    await type(tester, 'الإخلاص');

    await tapVisible(tester, find.textContaining('حديث إنما الأعمال'));
    // fx-riyd-01 is an audio lesson → audio player.
    expect(find.text('تشغيل صوتي · يعمل في الخلفية'), findsOneWidget);
    expect(app.audioEngine.loads, hasLength(1));
  });

  testApp('فتاوى and كتب scopes are marked coming soon', (tester, app) async {
    await openSearch(tester);
    await tapVisible(tester, find.text('فتاوى'));
    expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
    await tapVisible(tester, find.text('كتب'));
    expect(find.text('قريبًا إن شاء الله'), findsOneWidget);
  });

  testApp('library links the Phase 2–3 preview screens', (tester, app) async {
    await tapVisible(tester, find.text('المكتبة'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('أقسام قادمة'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('الفتاوى'));
    expect(find.text('نور على الدرب'), findsOneWidget);
    expect(find.textContaining('قريبًا إن شاء الله'), findsWidgets);

    final context = tester.element(find.text('نور على الدرب'));
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('المتون'));
    expect(find.textContaining('شاهد شرح هذا الموضع'), findsOneWidget);
  });
}
