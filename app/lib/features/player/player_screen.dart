import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lesson_tile.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../series/series_providers.dart';
import '../settings/theme_mode_provider.dart';
import 'player_engine.dart';
import 'progress_tracker.dart';

/// The lesson player: official YouTube embed + local progress tracking.
/// Resumes from the saved position, marks completion at >=90%, and (with
/// autoplay on) rolls into the next lesson of the series.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.videoId, this.seriesSlug});

  final String videoId;
  final String? seriesSlug;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final LessonPlayerEngine _engine;
  late String _currentVideoId;
  ProgressTracker? _tracker;
  StreamSubscription<Duration>? _positionsSub;
  StreamSubscription<void>? _endedSub;

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _engine = ref.read(playerEngineFactoryProvider)();
    _positionsSub = _engine.positions.listen(_onPosition);
    _endedSub = _engine.ended.listen((_) => _onEnded());
    _startLesson(_currentVideoId, initial: true);
  }

  @override
  void dispose() {
    _tracker?.flush();
    _positionsSub?.cancel();
    _endedSub?.cancel();
    _engine.dispose();
    super.dispose();
  }

  SeriesDetail? get _series => widget.seriesSlug == null
      ? null
      : ref.read(seriesDetailProvider(widget.seriesSlug!)).value;

  LessonWithProgress? _lessonById(String videoId) {
    final lessons = _series?.lessons;
    if (lessons == null) return null;
    for (final lesson in lessons) {
      if (lesson.videoId == videoId) return lesson;
    }
    return null;
  }

  LessonWithProgress? _neighbor(int offset) {
    final lessons = _series?.lessons;
    final current = _lessonById(_currentVideoId);
    if (lessons == null || current == null) return null;
    final index = lessons.indexWhere((l) => l.videoId == _currentVideoId);
    var target = index + offset;
    while (target >= 0 && target < lessons.length) {
      if (lessons[target].status == LessonStatus.active) return lessons[target];
      target += offset > 0 ? 1 : -1;
    }
    return null;
  }

  Future<void> _startLesson(String videoId, {bool initial = false}) async {
    _tracker?.flush();

    final progressRepo = ref.read(progressRepositoryProvider);
    final saved = await progressRepo.getProgress(videoId);
    final catalogDuration = _lessonById(videoId)?.durationSeconds;

    final tracker = ProgressTracker(
      totalDuration: catalogDuration == null
          ? null
          : Duration(seconds: catalogDuration),
      persist: (position) => progressRepo.saveWatchPosition(
        videoId: videoId,
        watchedSeconds: position.inSeconds,
        durationSeconds: _tracker?.totalDuration?.inSeconds ?? catalogDuration,
      ),
      complete: (position) => progressRepo.markCompleted(
        videoId,
        durationSeconds: _tracker?.totalDuration?.inSeconds ?? catalogDuration,
      ),
    );
    _tracker = tracker;

    final resumeFrom =
        (saved != null && !saved.completed && saved.watchedSeconds > 30)
        ? Duration(seconds: saved.watchedSeconds)
        : Duration.zero;

    if (!initial || !mounted) {
      setState(() => _currentVideoId = videoId);
    }
    await _engine.load(videoId, start: resumeFrom);

    // Prefer the player-reported duration once metadata is available.
    final reported = await _engine.currentDuration();
    if (reported != null && identical(_tracker, tracker)) {
      tracker.totalDuration = reported;
    }
  }

  void _onPosition(Duration position) => _tracker?.onPosition(position);

  void _onEnded() {
    _tracker?.onEnded();
    final next = _neighbor(1);
    if (next == null) return;
    if (ref.read(autoplayProvider)) {
      _startLesson(next.videoId);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('انتهى الدرس'),
          action: SnackBarAction(
            label: 'الدرس التالي',
            onPressed: () => _startLesson(next.videoId),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detailAsync = widget.seriesSlug == null
        ? null
        : ref.watch(seriesDetailProvider(widget.seriesSlug!));
    final detail = detailAsync?.value;
    final lessons = detail?.lessons ?? const <LessonWithProgress>[];
    final current = _lessonById(_currentVideoId);
    final currentIndex = lessons.indexWhere(
      (l) => l.videoId == _currentVideoId,
    );
    final previous = _neighbor(-1);
    final next = _neighbor(1);

    // Catalog metadata may arrive after _startLesson ran in initState —
    // backfill the duration so the 90% completion rule can engage.
    final tracker = _tracker;
    if (tracker != null &&
        tracker.totalDuration == null &&
        current?.durationSeconds != null) {
      tracker.totalDuration = Duration(seconds: current!.durationSeconds!);
    }

    if (current != null && current.status != LessonStatus.active) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.link_off_rounded,
          title: 'هذا الدرس غير متاح حاليًا',
          message: 'ربما تغير مصدر المقطع. جرّب درسًا آخر من السلسلة.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: detail == null ? null : Text(detail.series.titleAr),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _engine.buildView(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (current != null) ...[
                  Text(current.titleAr, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'الدرس ${arabicDigits(currentIndex + 1)} من ${arabicDigits(lessons.length)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: previous == null
                              ? null
                              : () => _startLesson(previous.videoId),
                          icon: const Icon(Icons.skip_previous_rounded),
                          label: const Text('السابق'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: next == null
                              ? null
                              : () => _startLesson(next.videoId),
                          icon: const Icon(Icons.skip_next_rounded),
                          label: const Text('التالي'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (final lesson in lessons)
                  LessonTile(
                    index: lesson.position,
                    title: lesson.titleAr,
                    duration: lesson.durationSeconds == null
                        ? null
                        : Duration(seconds: lesson.durationSeconds!),
                    progress: lesson.progress,
                    isPlaying: lesson.videoId == _currentVideoId,
                    unavailable: lesson.status != LessonStatus.active,
                    onTap: lesson.videoId == _currentVideoId
                        ? null
                        : () => _startLesson(lesson.videoId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
