import 'package:flutter_test/flutter_test.dart';
import 'package:masar/features/player/progress_tracker.dart';

void main() {
  late List<Duration> persisted;
  late List<Duration> completed;

  ProgressTracker makeTracker({Duration? total}) {
    persisted = [];
    completed = [];
    return ProgressTracker(
      totalDuration: total,
      persist: persisted.add,
      complete: completed.add,
    );
  }

  test('persists only every 5 seconds of playback distance', () {
    final tracker = makeTracker(total: const Duration(minutes: 60));

    tracker.onPosition(const Duration(seconds: 2));
    expect(persisted, isEmpty);

    tracker.onPosition(const Duration(seconds: 5));
    expect(persisted, [const Duration(seconds: 5)]);

    tracker.onPosition(const Duration(seconds: 8));
    expect(persisted, hasLength(1));

    tracker.onPosition(const Duration(seconds: 11));
    expect(persisted, hasLength(2));
  });

  test('seeking backwards still persists (absolute distance)', () {
    final tracker = makeTracker(total: const Duration(minutes: 60));
    tracker.onPosition(const Duration(minutes: 30));
    tracker.onPosition(const Duration(minutes: 10));
    expect(persisted, [
      const Duration(minutes: 30),
      const Duration(minutes: 10),
    ]);
  });

  test('completes exactly once at 90%', () {
    final tracker = makeTracker(total: const Duration(seconds: 1000));

    tracker.onPosition(const Duration(seconds: 899));
    expect(completed, isEmpty);

    tracker.onPosition(const Duration(seconds: 900));
    expect(completed, [const Duration(seconds: 900)]);
    expect(tracker.completedFired, isTrue);

    tracker.onPosition(const Duration(seconds: 950));
    expect(completed, hasLength(1));
  });

  test('no completion without a known duration', () {
    final tracker = makeTracker();
    tracker.onPosition(const Duration(hours: 2));
    expect(completed, isEmpty);
  });

  test('onEnded completes regardless of fraction', () {
    final tracker = makeTracker(total: const Duration(seconds: 1000));
    tracker.onPosition(const Duration(seconds: 100));
    tracker.onEnded();
    expect(completed, [const Duration(seconds: 100)]);
    tracker.onEnded();
    expect(completed, hasLength(1));
  });

  test('flush persists the latest position unless completed', () {
    final tracker = makeTracker(total: const Duration(seconds: 1000));
    tracker.onPosition(const Duration(seconds: 7));
    persisted.clear();

    tracker.onPosition(const Duration(seconds: 9));
    tracker.flush();
    expect(persisted, [const Duration(seconds: 9)]);

    tracker.onPosition(const Duration(seconds: 900)); // completes
    persisted.clear();
    tracker.flush();
    expect(persisted, isEmpty);
  });
}
