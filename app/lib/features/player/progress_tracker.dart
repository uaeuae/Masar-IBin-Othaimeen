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
