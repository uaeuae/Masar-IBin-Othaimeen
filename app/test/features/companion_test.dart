import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/pump_app.dart';

/// The fixture pairs sharh-alwasitiyah (video) with sharh-riyad-alsalihin
/// (audio) as its «النسخة الصوتية».
void main() {
  void pushRoute(WidgetTester tester, String location) {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push(location);
  }

  testApp('video series links to its audio edition and back', (
    tester,
    app,
  ) async {
    pushRoute(tester, '/series/sharh-alwasitiyah');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('الاستماع للنسخة الصوتية'));
    expect(find.text('شرح رياض الصالحين'), findsOneWidget);

    await tapVisible(tester, find.text('مشاهدة النسخة المرئية'));
    expect(find.text('شرح العقيدة الواسطية'), findsOneWidget);
  });

  testApp('video player top bar offers the audio edition', (
    tester,
    app,
  ) async {
    pushRoute(tester, '/player/fx-wast-01?series=sharh-alwasitiyah');
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byTooltip('الاستماع للنسخة الصوتية'));
    expect(find.text('شرح رياض الصالحين'), findsOneWidget);
  });
}
