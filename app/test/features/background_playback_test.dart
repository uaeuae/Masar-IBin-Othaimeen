import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/features/player/mini_player.dart';

import '../support/pump_app.dart';

/// A lesson keeps playing while the reader looks at something else.
///
/// The player screen used to own the audio engine and dispose it on the way
/// out, so pressing back stopped the lesson — you could not check the next
/// book, or read a series description, without losing your place. Playback now
/// belongs to the app; the screen is one view onto it and the mini player is
/// another.
void main() {
  Future<void> openLesson(WidgetTester tester) async {
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(
      context,
    ).push('/player/fx-riyd-01?series=sharh-riyad-alsalihin');
    await tester.pumpAndSettle();
  }

  testApp('leaving the player does not stop the lesson', (tester, app) async {
    await tester.pumpAndSettle();
    await openLesson(tester);
    expect(app.audioEngine.loads, isNotEmpty);

    // Back out to the library, the way a reader would to look something up.
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    expect(
      app.audioEngine.disposed,
      isFalse,
      reason: 'popping the screen must not tear down the engine',
    );
    // Still named on the strip above the tabs, so it is reachable and pausable.
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.textContaining('الدرس ١'), findsWidgets);
  });

  testApp('the mini player appears once something is playing, and pauses it', (
    tester,
    app,
  ) async {
    await tester.pumpAndSettle();
    // Nothing playing yet — the strip must not take up room.
    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);

    await openLesson(tester);
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    // The real engine reports playing; the fake only does when told.
    app.audioEngine.playingController.add(true);
    await tester.pumpAndSettle();

    // Back on the tabs, the lesson is named and pausable.
    expect(find.textContaining('الدرس ١'), findsWidgets);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();
    expect(app.audioEngine.togglePlayCalls, greaterThan(0));
  });

  testApp('closing the mini player ends playback and clears it', (
    tester,
    app,
  ) async {
    await tester.pumpAndSettle();
    await openLesson(tester);
    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testApp('reopening the same lesson does not restart it', (tester, app) async {
    await tester.pumpAndSettle();
    await openLesson(tester);
    final loadsAfterFirst = app.audioEngine.loads.length;

    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(context).pop();
    await tester.pumpAndSettle();
    await openLesson(tester);

    // Coming back to a lesson already playing must not seek it to the start —
    // that is the same lost-place complaint from the other direction.
    expect(app.audioEngine.loads.length, loadsAfterFirst);
  });
}
