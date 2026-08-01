import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masar/data/progress_repository.dart';

import '../support/pump_app.dart';

/// Removing a lesson from «متابعة الاستماع» — and the promise that removing it
/// from a list is not the same as throwing away where you stopped.
void main() {
  Future<void> listenTo(
    WidgetTester tester,
    PumpedApp app,
    String videoId, {
    int seconds = 400,
  }) async {
    await ProgressRepository(app.db).saveWatchPosition(
      videoId: videoId,
      watchedSeconds: seconds,
      durationSeconds: 2580,
    );
    await tester.pumpAndSettle();
  }

  testApp('the last lesson listened to appears, with who taught it', (
    tester,
    app,
  ) async {
    await listenTo(tester, app, 'fx-riyd-01');

    expect(find.text('متابعة المشاهدة'), findsOneWidget);
    expect(find.textContaining('الدرس ١'), findsWidgets);
    // Design 4a folds the attribution into the lesson line, using the شهرة —
    // the full name would ellipsize the lesson away.
    expect(find.textContaining('ابن عثيمين · الدرس'), findsOneWidget);
  });

  testApp('swiping asks first, and cancelling keeps the card', (
    tester,
    app,
  ) async {
    await listenTo(tester, app, 'fx-riyd-01');

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('إزالة من المتابعة؟'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsOneWidget);
  });

  testApp('confirming removes the card but keeps the saved position', (
    tester,
    app,
  ) async {
    await listenTo(tester, app, 'fx-riyd-01');

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة'));
    await tester.pumpAndSettle();

    expect(find.text('متابعة المشاهدة'), findsNothing);

    // The whole point of a flag rather than a delete.
    final progress = await ProgressRepository(app.db).getProgress('fx-riyd-01');
    expect(progress?.watchedSeconds, 400);
    expect(progress?.dismissed, isTrue);
  });

  testApp('the next lesson takes its place once one is removed', (
    tester,
    app,
  ) async {
    await listenTo(tester, app, 'fx-riyd-02', seconds: 100);
    await listenTo(tester, app, 'fx-riyd-01', seconds: 400);
    expect(find.textContaining('باب الإخلاص'), findsWidgets);

    await tester.drag(find.byType(Dismissible), const Offset(400, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إزالة'));
    await tester.pumpAndSettle();

    // Still a continue section — now showing the older lesson.
    expect(find.text('متابعة المشاهدة'), findsOneWidget);
  });

  testApp('listening again brings a removed lesson back', (tester, app) async {
    final progress = ProgressRepository(app.db);
    await listenTo(tester, app, 'fx-riyd-01');
    await progress.dismissFromContinue('fx-riyd-01');
    await tester.pumpAndSettle();
    expect(find.text('متابعة المشاهدة'), findsNothing);

    await listenTo(tester, app, 'fx-riyd-01', seconds: 500);

    expect(find.text('متابعة المشاهدة'), findsOneWidget);
  });
}
