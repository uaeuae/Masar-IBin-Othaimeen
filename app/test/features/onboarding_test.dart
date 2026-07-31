import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/pump_app.dart';

/// First-run coach marks: shown once, pointing at the real controls.
void main() {
  testApp('a first-time reader is shown the coach marks', showCoachMarks: true, (
    tester,
    app,
  ) async {
    await tester.pumpAndSettle();

    expect(find.text('اختر مستواك'), findsOneWidget);
    expect(find.text('تخطٍ'), findsOneWidget);
  });

  testApp(
    'the marks cover the resume card when there is one, then stop',
    showCoachMarks: true,
    // Seeded before the first build: the sequence decides what to point at
    // then, so progress arriving later would not be included.
    seed: (db) => ProgressRepository(db).saveWatchPosition(
      videoId: 'fx-riyd-01',
      watchedSeconds: 400,
      durationSeconds: 2580,
    ),
    (tester, app) async {
      await tester.pumpAndSettle();

      expect(find.text('اختر مستواك'), findsOneWidget);
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(find.text('تابع من حيث توقفت'), findsOneWidget);
      await tester.tap(find.text('تم'));
      await tester.pumpAndSettle();

      expect(find.text('تابع من حيث توقفت'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('seen_coach_marks'), contains('home'));
    },
  );

  testApp('«تخطٍ» ends the sequence and it is not shown again',
      showCoachMarks: true, (tester, app) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text('تخطٍ'));
    await tester.pumpAndSettle();

    expect(find.text('اختر مستواك'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('seen_coach_marks'), contains('home'));
  });

  testApp('a returning reader sees no coach marks', (tester, app) async {
    await tester.pumpAndSettle();
    expect(find.text('اختر مستواك'), findsNothing);
    expect(find.text('تخطٍ'), findsNothing);
  });
}
