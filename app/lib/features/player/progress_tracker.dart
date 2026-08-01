/// Where reopening a lesson should start.
///
/// «Completed» does not mean «heard to the end»: [ProgressTracker] calls a
/// lesson finished at [ProgressTracker.completionFraction] of its length, and
/// that fraction is a very different amount of audio depending on the lesson.
/// This library spans 1 minute to 110 — on a 90-minute lecture 90% leaves nine
/// minutes unheard, while on the 10-minute median of شرح كتاب التوحيد بشرح ابن
/// باز it leaves one, and a single ordinary sitting is enough to finish it.
///
/// So completion alone must not send the listener back to zero, or a lesson
/// they stopped a minute short becomes unfinishable: it restarts every time,
/// and the tail is unreachable. Start over only once there is nothing
/// meaningful left to hear.
Duration resumePositionFor({
  required int watchedSeconds,
  required bool completed,
  int? totalSeconds,
  Duration minimumToResume = const Duration(seconds: 30),
  Duration finishedWithin = const Duration(seconds: 60),
}) {
  final at = Duration(seconds: watchedSeconds);
  if (at <= minimumToResume) return Duration.zero;
  if (!completed) return at;
  if (totalSeconds == null) return Duration.zero;
  final remaining = Duration(seconds: totalSeconds) - at;
  return remaining > finishedWithin ? at : Duration.zero;
}

/// Pure progress logic for the lesson player — position stream in,
/// throttled persistence and a one-shot completion signal out.
///
/// Rules:
/// - persist every [persistEvery] of *playback* distance (deterministic in tests)
/// - complete once at >= [completionFraction] of the total duration
/// - flush() persists the latest position immediately (pause/dispose)
class ProgressTracker {
  ProgressTracker({
    required this.persist,
    required this.complete,
    this.totalDuration,
    this.persistEvery = const Duration(seconds: 5),
    this.completionFraction = 0.9,
  });

  final void Function(Duration position) persist;
  final void Function(Duration position) complete;

  /// Set/updated when player metadata arrives; null disables completion.
  Duration? totalDuration;
  final Duration persistEvery;
  final double completionFraction;

  Duration _latest = Duration.zero;
  Duration _lastPersisted = Duration.zero;
  bool _completed = false;

  bool get completedFired => _completed;

  void onPosition(Duration position) {
    _latest = position;

    final total = totalDuration;
    if (!_completed &&
        total != null &&
        total > Duration.zero &&
        position.inMilliseconds >= total.inMilliseconds * completionFraction) {
      _completed = true;
      complete(position);
      return;
    }

    if ((position - _lastPersisted).abs() >= persistEvery) {
      _lastPersisted = position;
      persist(position);
    }
  }

  /// Mark completed regardless of fraction (e.g. the player reported "ended").
  void onEnded() {
    if (_completed) return;
    _completed = true;
    complete(_latest);
  }

  void flush() {
    if (_completed || _latest <= Duration.zero) return;
    _lastPersisted = _latest;
    persist(_latest);
  }
}
