import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/pump_app.dart';

void main() {
  Future<void> openFirstRiyadLesson(WidgetTester tester) async {
    final context = tester.element(find.text('أهلًا بك يا طالب العلم'));
    GoRouter.of(
      context,
    ).push('/player/fx-riyd-01?series=sharh-riyad-alsalihin');
    await tester.pumpAndSettle();
  }

  testApp('audio lesson opens the audio player, not the video player', (
    tester,
    app,
  ) async {
    await openFirstRiyadLesson(tester);

    expect(find.text('تشغيل صوتي · يعمل في الخلفية'), findsOneWidget);
    expect(app.audioEngine.loads, hasLength(1));
    expect(app.audioEngine.loads.single.$1, 'fx-riyd-01');
    expect(app.audioEngine.loads.single.$2, contains('.mp3'));
    // The video engine must stay untouched.
    expect(app.engine.loads, isEmpty);
  });

  testApp('chapter index renders and tapping a chapter seeks', (
    tester,
    app,
  ) async {
    await openFirstRiyadLesson(tester);

    // The chapter index sits below the fold of the lazy ListView.
    await tester.scrollUntilVisible(
      find.text('فهرس الدرس'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('الحديث الأول'));
    expect(app.audioEngine.seeks, contains(const Duration(seconds: 489)));
  });

  testApp('audio positions persist and resume like video lessons', (
    tester,
    app,
  ) async {
    app.audioEngine.durationToReport = const Duration(seconds: 2700);
    await openFirstRiyadLesson(tester);

    app.audioEngine.positionsController.add(const Duration(seconds: 120));
    await tester.pumpAndSettle();

    final progress = ProgressRepository(app.db);
    expect(
      (await progress.getProgress('fx-riyd-01'))?.watchedSeconds,
      120,
    );
    expect(find.text('حُفظ موضع التوقف تلقائيًا'), findsOneWidget);
  });

  testApp('speed control cycles playback rates', (tester, app) async {
    await openFirstRiyadLesson(tester);

    await tapVisible(tester, find.text('١×'));
    expect(app.audioEngine.speeds, [1.25]);
    expect(find.text('١٫٢٥×'), findsOneWidget);
  });

  testApp('ended audio lesson with autoplay rolls into the next one', (
    tester,
    app,
  ) async {
    await openFirstRiyadLesson(tester);
    expect(app.audioEngine.loads.single.$1, 'fx-riyd-01');

    app.audioEngine.endedController.add(null);
    await tester.pumpAndSettle();

    expect(app.audioEngine.loads.last.$1, 'fx-riyd-02');
    final row = await ProgressRepository(app.db).getProgress('fx-riyd-01');
    expect(row?.completed, isTrue);
  });
}
