import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lesson_row.dart';
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../series/series_providers.dart';
import '../settings/theme_mode_provider.dart';
import 'pip_controller.dart';
import 'player_engine.dart';
import 'progress_tracker.dart';

/// The lesson player — always dark per the design. Official YouTube embed,
/// live position bar, auto-save badge, prev/play/next, autoplay-next card
/// with up-next preview, and the بقية الدروس list.
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

  /// Keeps the live video WebView alive when the layout swaps between the
  /// full screen and the chrome-less PiP arrangement.
  final GlobalKey _videoKey = GlobalKey();
  ProgressTracker? _tracker;
  StreamSubscription<Duration>? _positionsSub;
  StreamSubscription<void>? _endedSub;
  StreamSubscription<bool>? _playingSub;

  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _hasSavedOnce = false;

  /// Non-null while the user drags the seek bar (fraction 0–1); position
  /// stream updates must not fight the finger.
  double? _dragFraction;

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _engine = ref.read(playerEngineFactoryProvider)();
    _positionsSub = _engine.positions.listen(_onPosition);
    _endedSub = _engine.ended.listen((_) => _onEnded());
    _playingSub = _engine.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    PipController.inPip.addListener(_onPipChanged);
    PipController.setActive(true);
    _startLesson(_currentVideoId, initial: true);
  }

  void _onPipChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PipController.inPip.removeListener(_onPipChanged);
    PipController.setActive(false);
    _tracker?.flush();
    _positionsSub?.cancel();
    _endedSub?.cancel();
    _playingSub?.cancel();
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
      persist: (position) {
        if (mounted && !_hasSavedOnce) setState(() => _hasSavedOnce = true);
        progressRepo.saveWatchPosition(
          videoId: videoId,
          watchedSeconds: position.inSeconds,
          durationSeconds:
              _tracker?.totalDuration?.inSeconds ?? catalogDuration,
        );
      },
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
      setState(() {
        _currentVideoId = videoId;
        _position = resumeFrom;
        _hasSavedOnce = false;
      });
    } else {
      _position = resumeFrom;
    }
    await _engine.load(videoId, start: resumeFrom);

    final reported = await _engine.currentDuration();
    if (reported != null && identical(_tracker, tracker)) {
      tracker.totalDuration = reported;
    }
  }

  void _onPosition(Duration position) {
    _tracker?.onPosition(position);
    if (mounted && _dragFraction == null) {
      setState(() => _position = position);
    }
  }

  Future<void> _seekToFraction(double fraction, Duration total) async {
    final target = Duration(
      milliseconds: (total.inMilliseconds * fraction).round(),
    );
    setState(() {
      _position = target;
      _dragFraction = null;
    });
    await _engine.seekTo(target);
  }

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
    // The design specifies the player in dark, always.
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final autoplay = ref.watch(autoplayProvider);
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

    // Backfill duration from catalog metadata if the engine hasn't reported.
    final tracker = _tracker;
    if (tracker != null &&
        tracker.totalDuration == null &&
        current?.durationSeconds != null) {
      tracker.totalDuration = Duration(seconds: current!.durationSeconds!);
    }
    final total =
        tracker?.totalDuration ??
        (current?.durationSeconds == null
            ? null
            : Duration(seconds: current!.durationSeconds!));

    if (current != null && current.status != LessonStatus.active) {
      return Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.all(20), child: BackCircle()),
              const Expanded(
                child: EmptyState(
                  icon: Icons.link_off_rounded,
                  title: 'هذا الدرس غير متاح حاليًا',
                  message: 'ربما تغير مصدر المقطع. جرّب درسًا آخر من السلسلة.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // In a PiP window only the video surface fits — drop all chrome. The
    // GlobalKey reparents the live WebView instead of recreating it.
    if (PipController.inPip.value) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: KeyedSubtree(
              key: _videoKey,
              child: _engine.buildView(context),
            ),
          ),
        ),
      );
    }

    final remaining = [
      if (currentIndex >= 0)
        ...lessons
            .skip(currentIndex + 1)
            .where((l) => l.status == LessonStatus.active)
            .take(4),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          children: [
            // ── Top bar: back + breadcrumb ────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackCircle(),
                  if (detail != null && currentIndex >= 0)
                    Expanded(
                      child: Text(
                        '${detail.series.titleAr} · ${arabicDigits(currentIndex + 1)} / ${arabicDigits(lessons.length)}',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  if (detail?.series.companionSlug != null)
                    IconButton(
                      tooltip: 'الاستماع للنسخة الصوتية',
                      onPressed: () => context.pushReplacement(
                        '/series/${detail!.series.companionSlug}',
                      ),
                      icon: Icon(
                        Icons.headphones_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Video ────────────────────────────────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: KeyedSubtree(
                key: _videoKey,
                child: _engine.buildView(context),
              ),
            ),
            const SizedBox(height: 16),

            // ── Live position + auto-save badge ──────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Builder(
                      builder: (context) {
                        final seekable = total != null && total > Duration.zero;
                        final fraction = !seekable
                            ? 0.0
                            : (_position.inMilliseconds /
                                      total.inMilliseconds)
                                  .clamp(0.0, 1.0);
                        final shownFraction = _dragFraction ?? fraction;
                        final shownPosition = !seekable
                            ? _position
                            : Duration(
                                milliseconds:
                                    (total.inMilliseconds * shownFraction)
                                        .round(),
                              );
                        return Row(
                          children: [
                            Text(
                              clockLabelLtr(shownPosition),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: kMonoFont,
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  activeTrackColor: scheme.primary,
                                  inactiveTrackColor:
                                      scheme.surfaceContainerHighest,
                                  thumbColor: scheme.primary,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                ),
                                child: Slider(
                                  value: shownFraction,
                                  onChanged: !seekable
                                      ? null
                                      : (v) =>
                                            setState(() => _dragFraction = v),
                                  onChangeEnd: !seekable
                                      ? null
                                      : (v) => _seekToFraction(v, total),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              total == null ? '--:--' : clockLabelLtr(total),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontFamily: kMonoFont,
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_hasSavedOnce) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'حُفظ موضع التوقف تلقائيًا',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Title + breadcrumb ────────────────────────────────────
            if (current != null)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدرس ${arabicDigits(current.position)} — ${current.titleAr}',
                      style: serif(22, scheme.onSurface, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    if (detail != null)
                      Text(
                        detail.series.titleAr,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Controls ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SideControl(
                  label: 'السابق',
                  icon: Icons.skip_next_rounded,
                  enabled: previous != null,
                  onTap: previous == null
                      ? null
                      : () => _startLesson(previous.videoId),
                ),
                const SizedBox(width: 26),
                GestureDetector(
                  onTap: _engine.togglePlay,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 30,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 26),
                _SideControl(
                  label: 'التالي',
                  icon: Icons.skip_previous_rounded,
                  enabled: next != null,
                  onTap: next == null ? null : () => _startLesson(next.videoId),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Autoplay-next card ────────────────────────────────────
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.banner),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'التشغيل التلقائي للدرس التالي',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            next == null
                                ? 'هذا آخر دروس السلسلة'
                                : 'التالي: الدرس ${arabicDigits(next.position)} — ${next.titleAr}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: autoplay,
                      onChanged: (v) =>
                          ref.read(autoplayProvider.notifier).set(v),
                    ),
                  ],
                ),
              ),
            ),

            // ── بقية الدروس ───────────────────────────────────────────
            if (remaining.isNotEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بقية الدروس',
                      style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.banner),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (final (index, lesson) in remaining.indexed)
                            LessonRow(
                              title:
                                  'الدرس ${arabicDigits(lesson.position)} — ${lesson.titleAr}',
                              state: LessonRowState.upcoming,
                              duration: lesson.durationSeconds == null
                                  ? null
                                  : Duration(seconds: lesson.durationSeconds!),
                              monoClock: true,
                              showDivider: index != remaining.length - 1,
                              onTap: () => _startLesson(lesson.videoId),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SideControl extends StatelessWidget {
  const _SideControl({
    required this.label,
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
