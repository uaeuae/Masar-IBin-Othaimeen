import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/features/series/book_about_card.dart';

import '../support/pump_app.dart';

/// «عن الكتاب» — the series screen should say what the book is before the
/// reader commits to a 90-minute lesson.
void main() {
  Future<void> openSeries(WidgetTester tester, String slug) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/series/$slug');
    await tester.pumpAndSettle();
  }

  testApp('the book card names the sheikh, the size, and the source', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-riyad-alsalihin');

    expect(find.byType(BookAboutCard), findsOneWidget);
    expect(find.text('عن الكتاب'), findsOneWidget);
    expect(find.text('الشيخ محمد بن صالح العثيمين'), findsOneWidget);
    expect(find.textContaining('مؤسسة'), findsWidgets);
    expect(find.textContaining('دروس'), findsWidgets);
  });

  testApp('a series with no transcript says so up front', (tester, app) async {
    // sharh-thalathat-alusul carries no text_kind on any lesson in the fixture.
    await openSeries(tester, 'sharh-thalathat-alusul');

    expect(find.text('لا يتوفر نص مقروء لهذه السلسلة'), findsOneWidget);
    expect(
      find.text('المؤسسة لم تنشر تفريغًا نصيًا لهذه الدروس.'),
      findsOneWidget,
    );
  });

  testApp('a series that has a transcript says that instead', (
    tester,
    app,
  ) async {
    await openSeries(tester, 'sharh-riyad-alsalihin');
    expect(find.text('يتوفر نص مقروء مع الصوت'), findsOneWidget);
    expect(find.text('لا يتوفر نص مقروء لهذه السلسلة'), findsNothing);
  });
}
