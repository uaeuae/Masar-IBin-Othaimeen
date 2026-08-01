import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:masar/data/progress_repository.dart';

import 'package:masar/features/player/progress_tracker.dart';

import '../support/pump_app.dart';

/// Completion is a *fraction* of the lesson, which does not survive a library
/// whose lessons range from 1 minute to 110.
///
/// Ibn Baz's شرح كتاب التوحيد has a median lesson of 10 minutes — 64 of its 75
/// are under 15 — where every other series in the app sits between 87 and 97.
/// At 90%, a 10-minute lesson is "finished" after 9 minutes: one ordinary
/// sitting. Marking it complete then overwrote the saved position with the full
/// duration and refused to resume, so reopening restarted from zero and the
/// last minute was unreachable.
void main() {
  testApp('a short lesson finished early still resumes where it stopped', (
    tester,
    app,
  ) async {
    // 9 of 10 minutes — past the 90% mark, so the tracker calls it complete.
    await ProgressRepository(app.db).markCompleted(
      'baz-tawhid-01',
      durationSeconds: 600,
      watchedSeconds: 520,
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(
      context,
    ).push('/player/baz-tawhid-01?series=baz-sharh-kitab-altawhid');
    await tester.pumpAndSettle();

    // A minute of audio is still unheard; dropping the listener at zero throws
    // it away.
    expect(app.audioEngine.loads.last.$3, const Duration(seconds: 520));
  });

  testApp('a lesson heard to the end starts over, as it should', (
    tester,
    app,
  ) async {
    await ProgressRepository(app.db).markCompleted(
      'baz-tawhid-01',
      durationSeconds: 600,
      watchedSeconds: 595,
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Navigator).first);
    GoRouter.of(
      context,
    ).push('/player/baz-tawhid-01?series=baz-sharh-kitab-altawhid');
    await tester.pumpAndSettle();

    expect(app.audioEngine.loads.last.$3, Duration.zero);
  });


  group('resumePositionFor', () {
    // The rule in isolation, across the length range this library actually has.
    test('an unfinished lesson always resumes', () {
      expect(
        resumePositionFor(watchedSeconds: 400, completed: false, totalSeconds: 5400),
        const Duration(seconds: 400),
      );
    });

    test('a barely-started lesson does not', () {
      // Under half a minute is a mis-tap, not a place to come back to.
      expect(
        resumePositionFor(watchedSeconds: 12, completed: false, totalSeconds: 600),
        Duration.zero,
      );
    });

    test('90% of a long lecture still has nine minutes left, so it resumes', () {
      expect(
        resumePositionFor(watchedSeconds: 4860, completed: true, totalSeconds: 5400),
        const Duration(seconds: 4860),
      );
    });

    test('90% of a ten-minute lesson has one minute left, so it resumes too', () {
      // The reported bug: this used to return zero, so the last minute was
      // unreachable and the lesson restarted forever.
      expect(
        resumePositionFor(watchedSeconds: 520, completed: true, totalSeconds: 600),
        const Duration(seconds: 520),
      );
    });

    test('a lesson heard to the end starts over', () {
      expect(
        resumePositionFor(watchedSeconds: 597, completed: true, totalSeconds: 600),
        Duration.zero,
      );
    });

    test('a completed lesson of unknown length starts over', () {
      // No duration means no way to tell how much is left; starting over is the
      // safe reading, since the alternative strands the listener at the end.
      expect(
        resumePositionFor(watchedSeconds: 500, completed: true, totalSeconds: null),
        Duration.zero,
      );
    });
  });
}
