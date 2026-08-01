import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../settings/theme_mode_provider.dart';
import 'audio_engine.dart';
import 'progress_tracker.dart';

/// What is playing, for anyone who wants to show or control it.
@immutable
class PlaybackState {
  const PlaybackState({
    this.lessonId,
    this.seriesSlug,
    this.lessonTitle = '',
    this.seriesTitle = '',
    this.position = Duration.zero,
    this.total,
    this.playing = false,
    this.speed = 1.0,
    this.offline = false,
    this.sleepMinutes,
    this.savedOnce = false,
  });

  final String? lessonId;
  final String? seriesSlug;
  final String lessonTitle;
  final String seriesTitle;
  final Duration position;
  final Duration? total;
  final bool playing;
  final double speed;
  final bool offline;
  final int? sleepMinutes;

  /// The player shows «حُفظ موضعك» once the first position lands.
  final bool savedOnce;

  bool get hasLesson => lessonId != null;

  PlaybackState copyWith({
    String? lessonId,
    String? seriesSlug,
    String? lessonTitle,
    String? seriesTitle,
    Duration? position,
    Duration? total,
    bool? playing,
    double? speed,
    bool? offline,
    int? sleepMinutes,
    bool? savedOnce,
    bool clearSleep = false,
    bool clearTotal = false,
  }) => PlaybackState(
    lessonId: lessonId ?? this.lessonId,
    seriesSlug: seriesSlug ?? this.seriesSlug,
    lessonTitle: lessonTitle ?? this.lessonTitle,
    seriesTitle: seriesTitle ?? this.seriesTitle,
    position: position ?? this.position,
    total: clearTotal ? null : (total ?? this.total),
    playing: playing ?? this.playing,
    speed: speed ?? this.speed,
    offline: offline ?? this.offline,
    sleepMinutes: clearSleep ? null : (sleepMinutes ?? this.sleepMinutes),
    savedOnce: savedOnce ?? this.savedOnce,
  );
}

/// Owns the audio engine for the life of the app, not the life of a screen.
///
/// The player screen used to create and dispose the engine itself, so leaving
/// it stopped the lesson — you could not look up the next book, or read the
/// series description, without losing your place in what you were listening to.
/// Playback belongs to the app: the screen is one view onto it, the mini player
/// is another, and the lock-screen controls a third.
///
/// Nothing here touches widgets, so a lesson keeps playing while every screen
/// in the app comes and goes.
class PlaybackController extends Notifier<PlaybackState> {
  AudioLessonEngine? _engine;
  ProgressTracker? _tracker;
  StreamSubscription<Duration>? _positions;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<void>? _ended;
  Timer? _sleepTimer;

  /// Set by the player screen so «التالي» and autoplay can find the next
  /// lesson without the controller depending on series providers.
  LessonWithProgress? Function(String lessonId, int offset)? neighbourLookup;

  /// Set before teardown so the final flush can still write the listener's
  /// position to the database without touching provider state — Riverpod
  /// forbids that during disposal, and the flush is the one thing that must
  /// not be skipped.
  bool _disposed = false;

  @override
  PlaybackState build() {
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    return const PlaybackState();
  }

  AudioLessonEngine get _live {
    final existing = _engine;
    if (existing != null) return existing;
    final created = ref.read(audioEngineFactoryProvider)();
    _engine = created;
    _positions = created.positions.listen(_onPosition);
    _playingSub = created.playing.listen((playing) {
      if (!_disposed) state = state.copyWith(playing: playing);
    });
    _ended = created.ended.listen((_) => _onEnded());
    return created;
  }

  void _teardown() {
    _tracker?.flush();
    _sleepTimer?.cancel();
    _positions?.cancel();
    _playingSub?.cancel();
    _ended?.cancel();
    _engine?.dispose();
    _engine = null;
  }

  /// Loads [lesson] and starts it. Safe to call for the lesson already playing
  /// — it is a no-op then, so reopening the player does not restart the audio.
  Future<void> play(
    LessonWithProgress lesson, {
    required String seriesSlug,
    required String seriesTitle,
    int? startAtSeconds,
  }) async {
    final url = lesson.audioUrl;
    if (url == null) return;
    if (lesson.videoId == state.lessonId && startAtSeconds == null) return;

    _tracker?.flush();

    final progress = ref.read(progressRepositoryProvider);
    final saved = await progress.getProgress(lesson.videoId);
    final catalogDuration = lesson.durationSeconds;
    final id = lesson.videoId;

    final tracker = ProgressTracker(
      totalDuration: catalogDuration == null
          ? null
          : Duration(seconds: catalogDuration),
      persist: (position) {
        if (!_disposed && !state.savedOnce) {
          state = state.copyWith(savedOnce: true);
        }
        progress.saveWatchPosition(
          videoId: id,
          watchedSeconds: position.inSeconds,
          durationSeconds:
              _tracker?.totalDuration?.inSeconds ?? catalogDuration,
        );
      },
      complete: (position) => progress.markCompleted(
        id,
        durationSeconds: _tracker?.totalDuration?.inSeconds ?? catalogDuration,
        watchedSeconds: position.inSeconds,
      ),
    );
    _tracker = tracker;

    final start = startAtSeconds != null
        ? Duration(seconds: startAtSeconds)
        : resumePositionFor(
            watchedSeconds: saved?.watchedSeconds ?? 0,
            completed: saved?.completed ?? false,
            totalSeconds: catalogDuration ?? saved?.durationSeconds,
          );

    final localPath = await ref.read(downloadRepositoryProvider).localPathFor(id);

    state = state.copyWith(
      lessonId: id,
      seriesSlug: seriesSlug,
      seriesTitle: seriesTitle,
      lessonTitle:
          'الدرس ${arabicDigits(lesson.position)} — ${lesson.titleAr}',
      position: start,
      total: catalogDuration == null
          ? null
          : Duration(seconds: catalogDuration),
      offline: localPath != null,
      savedOnce: false,
    );

    await _live.load(
      id: id,
      url: localPath ?? url,
      title: state.lessonTitle,
      album: seriesTitle.isEmpty ? 'مسار' : seriesTitle,
      start: start,
      isLocalFile: localPath != null,
    );
    if (state.speed != 1.0) await _live.setSpeed(state.speed);
    await _applyGain(lesson);

    final reported = await _live.currentDuration();
    if (reported != null && identical(_tracker, tracker)) {
      tracker.totalDuration = reported;
      state = state.copyWith(total: reported);
    }
  }

  Future<void> _applyGain(LessonWithProgress lesson) async {
    final normalize = ref.read(normalizeVolumeProvider);
    await _live.setGainDb(normalize ? (lesson.gainDb ?? 0) : 0);
  }

  void _onPosition(Duration position) {
    if (_disposed) return;
    _tracker?.onPosition(position);
    state = state.copyWith(position: position);
  }

  void _onEnded() {
    if (_disposed) return;
    _tracker?.onEnded();
    final id = state.lessonId;
    final next = id == null ? null : neighbourLookup?.call(id, 1);
    if (next == null || !ref.read(autoplayProvider)) return;
    final slug = state.seriesSlug;
    if (slug == null) return;
    play(next, seriesSlug: slug, seriesTitle: state.seriesTitle);
  }

  Future<void> toggle() => _live.togglePlay();

  Future<void> seekTo(Duration position) async {
    state = state.copyWith(position: position);
    await _live.seekTo(position);
  }

  /// Nudges by [seconds], clamped so a tap near either end cannot seek past it.
  Future<void> skipBy(int seconds) async {
    final total = state.total;
    var target = state.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (total != null && target > total) target = total;
    await seekTo(target);
  }

  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _live.setSpeed(speed);
  }

  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    if (minutes == null) {
      state = state.copyWith(clearSleep: true);
      return;
    }
    state = state.copyWith(sleepMinutes: minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      if (state.playing) await _live.togglePlay();
      state = state.copyWith(clearSleep: true);
    });
  }

  /// Ends playback and clears the mini player.
  Future<void> stop() async {
    _tracker?.flush();
    _tracker = null;
    _sleepTimer?.cancel();
    if (state.playing) await _live.togglePlay();
    state = const PlaybackState();
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
