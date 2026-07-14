import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/pump_app.dart';

void main() {
  Future<void> openFirstUsulLesson(WidgetTester tester) async {
    await tapVisible(tester, find.text('مسار العقيدة'));
    await tapVisible(tester, find.text('شرح ثلاثة الأصول'));
    await tapVisible(tester, find.textContaining('ابدأ — الدرس'));
  }

  testApp('player resumes from the saved position', (tester, app) async {
    await ProgressRepository(app.db).saveWatchPosition(
      videoId: 'fx-usul-01',
      watchedSeconds: 600,
      durationSeconds: 2700,
    );
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('مسار العقيدة'));
    await tapVisible(tester, find.text('شرح ثلاثة الأصول'));
    await tapVisible(tester, find.textContaining('استئناف — الدرس'));

    expect(app.engine.loads, [('fx-usul-01', const Duration(seconds: 600))]);
    expect(find.textContaining('١ / ٨'), findsOneWidget);
  });

  testApp('positions persist throttled and 90% completes the lesson', (
    tester,
    app,
  ) async {
    app.engine.durationToReport = const Duration(seconds: 2700);
    await openFirstUsulLesson(tester);

    final progress = ProgressRepository(app.db);

    app.engine.positionsController.add(const Duration(seconds: 42));
    await tester.pumpAndSettle();
    expect((await progress.getProgress('fx-usul-01'))?.watchedSeconds, 42);
    expect(find.text('حُفظ موضع التوقف تلقائيًا'), findsOneWidget);

    app.engine.positionsController.add(const Duration(seconds: 44));
    await tester.pumpAndSettle();
    expect((await progress.getProgress('fx-usul-01'))?.watchedSeconds, 42);

    app.engine.positionsController.add(const Duration(seconds: 2430));
    await tester.pumpAndSettle();
    final row = await progress.getProgress('fx-usul-01');
    expect(row?.completed, isTrue);
  });

  testApp('ended lesson with autoplay rolls into the next one', (
    tester,
    app,
  ) async {
    await openFirstUsulLesson(tester);
    expect(app.engine.loads.single.$1, 'fx-usul-01');

    app.engine.endedController.add(null);
    await tester.pumpAndSettle();

    expect(app.engine.loads.last.$1, 'fx-usul-02');
    final row = await ProgressRepository(app.db).getProgress('fx-usul-01');
    expect(row?.completed, isTrue);
    expect(find.textContaining('٢ / ٨'), findsOneWidget);
  });

  testApp('next/previous controls move within the series', (tester, app) async {
    await openFirstUsulLesson(tester);

    await tapVisible(tester, find.text('التالي'));
    expect(app.engine.loads.last.$1, 'fx-usul-02');

    await tapVisible(tester, find.text('السابق'));
    expect(app.engine.loads.last.$1, 'fx-usul-01');
  });

  testApp('unavailable lesson shows a message instead of the player', (
    tester,
    app,
  ) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(context).push('/player/fx-wast-06?series=sharh-alwasitiyah');
    await tester.pumpAndSettle();

    expect(find.text('هذا الدرس غير متاح حاليًا'), findsOneWidget);
  });
}
