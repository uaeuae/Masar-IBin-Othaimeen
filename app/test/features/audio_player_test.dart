import 'package:flutter/material.dart';
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

  /// The transport row sits below the fold, and a lazy ListView does not build
  /// off-screen children -- so the icon has to be scrolled into existence
  /// before it can be found, let alone tapped.
  Future<void> tapControl(WidgetTester tester, IconData icon) async {
    await tester.scrollUntilVisible(
      find.byIcon(icon),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(icon));
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

  testApp('the 10-second buttons nudge playback both ways', (tester, app) async {
    app.audioEngine.durationToReport = const Duration(seconds: 2580);
    await openFirstRiyadLesson(tester);

    app.audioEngine.positionsController.add(const Duration(seconds: 100));
    await tester.pumpAndSettle();

    await tapControl(tester, Icons.forward_10_rounded);
    expect(app.audioEngine.seeks.last, const Duration(seconds: 110));

    app.audioEngine.positionsController.add(const Duration(seconds: 110));
    await tester.pumpAndSettle();
    await tapControl(tester, Icons.replay_10_rounded);
    expect(app.audioEngine.seeks.last, const Duration(seconds: 100));
  });

  testApp('a nudge near either end clamps instead of seeking past it', (
    tester,
    app,
  ) async {
    app.audioEngine.durationToReport = const Duration(seconds: 2580);
    await openFirstRiyadLesson(tester);

    // At 3s, back 10 must land on 0 rather than a negative position.
    app.audioEngine.positionsController.add(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tapControl(tester, Icons.replay_10_rounded);
    expect(app.audioEngine.seeks.last, Duration.zero);

    // And 4s from the end, forward 10 stops at the end.
    app.audioEngine.positionsController.add(const Duration(seconds: 2576));
    await tester.pumpAndSettle();
    await tapControl(tester, Icons.forward_10_rounded);
    expect(app.audioEngine.seeks.last, const Duration(seconds: 2580));
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
