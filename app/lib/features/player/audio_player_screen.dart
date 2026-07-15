import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/science_glyph.dart';
import '../../data/models/catalog.dart' show CatalogChapter;
import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../series/series_providers.dart';
import '../settings/theme_mode_provider.dart';
import 'audio_engine.dart';
import 'progress_tracker.dart';

const _speeds = [1.0, 1.25, 1.5, 2.0];

/// The audio lesson player (design 1n) — foundation-hosted MP3s, always dark,
/// background playback, speed control, sleep timer, up-next, and the lesson's
/// chapter index with tap-to-seek.
class AudioPlayerScreen extends ConsumerStatefulWidget {
  const AudioPlayerScreen({
    super.key,
    required this.lessonId,
    required this.seriesSlug,
  });

  final String lessonId;
  final String seriesSlug;

  @override
  ConsumerState<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends ConsumerState<AudioPlayerScreen> {
  late final AudioLessonEngine _engine;
  late String _currentId;
  ProgressTracker? _tracker;
  StreamSubscription<Duration>? _positionsSub;
  StreamSubscription<void>? _endedSub;
  StreamSubscription<bool>? _playingSub;
  Timer? _sleepTimer;

  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _hasSavedOnce = false;
  double? _dragFraction;
  double _speed = 1.0;
  int? _sleepMinutes;

  @override
  void initState() {
    super.initState();
    _currentId = widget.lessonId;
    _engine = ref.read(audioEngineFactoryProvider)();
    _positionsSub = _engine.positions.listen(_onPosition);
    _endedSub = _engine.ended.listen((_) => _onEnded());
    _playingSub = _engine.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    // The series detail may not be loaded yet on a cold deep-link; wait for
    // the first value before starting.
    Future.microtask(() async {
      await ref.read(seriesDetailProvider(widget.seriesSlug).future);
      if (mounted) await _startLesson(_currentId, initial: true);
    });
  }

  @override
  void dispose() {
    _tracker?.flush();
    _sleepTimer?.cancel();
    _positionsSub?.cancel();
    _endedSub?.cancel();
    _playingSub?.cancel();
    _engine.dispose();
    super.dispose();
  }

  SeriesDetail? get _series =>
      ref.read(seriesDetailProvider(widget.seriesSlug)).value;

  LessonWithProgress? _lessonById(String id) {
    final lessons = _series?.lessons;
    if (lessons == null) return null;
    for (final lesson in lessons) {
      if (lesson.videoId == id) return lesson;
    }
    return null;
  }

  LessonWithProgress? _neighbor(int offset) {
    final lessons = _series?.lessons;
    if (lessons == null) return null;
    final index = lessons.indexWhere((l) => l.videoId == _currentId);
    if (index == -1) return null;
    var target = index + offset;
    while (target >= 0 && target < lessons.length) {
      final candidate = lessons[target];
      if (candidate.status == LessonStatus.active &&
          candidate.audioUrl != null) {
        return candidate;
      }
      target += offset > 0 ? 1 : -1;
    }
    return null;
  }

  Future<void> _startLesson(String id, {bool initial = false}) async {
    _tracker?.flush();

    final lesson = _lessonById(id);
    final audioUrl = lesson?.audioUrl;
    if (lesson == null || audioUrl == null) return;

    final progressRepo = ref.read(progressRepositoryProvider);
    final saved = await progressRepo.getProgress(id);
    final catalogDuration = lesson.durationSeconds;

    final tracker = ProgressTracker(
      totalDuration: catalogDuration == null
          ? null
          : Duration(seconds: catalogDuration),
      persist: (position) {
        if (mounted && !_hasSavedOnce) setState(() => _hasSavedOnce = true);
        progressRepo.saveWatchPosition(
          videoId: id,
          watchedSeconds: position.inSeconds,
          durationSeconds:
              _tracker?.totalDuration?.inSeconds ?? catalogDuration,
        );
      },
      complete: (position) => progressRepo.markCompleted(
        id,
        durationSeconds: _tracker?.totalDuration?.inSeconds ?? catalogDuration,
      ),
    );
    _tracker = tracker;

    final resumeFrom =
        (saved != null && !saved.completed && saved.watchedSeconds > 30)
        ? Duration(seconds: saved.watchedSeconds)
        : Duration.zero;

    if (mounted) {
      setState(() {
        _currentId = id;
        _position = resumeFrom;
        _hasSavedOnce = false;
      });
    }

    await _engine.load(
      id: id,
      url: audioUrl,
      title: 'الدرس ${arabicDigits(lesson.position)} — ${lesson.titleAr}',
      album: _series?.series.titleAr ?? 'مسار',
      start: resumeFrom,
    );
    if (_speed != 1.0) await _engine.setSpeed(_speed);

    final reported = await _engine.currentDuration();
    if (reported != null && identical(_tracker, tracker)) {
      tracker.totalDuration = reported;
      if (mounted) setState(() {});
    }
  }

  void _onPosition(Duration position) {
    _tracker?.onPosition(position);
    if (mounted && _dragFraction == null) {
      setState(() => _position = position);
    }
  }

  void _onEnded() {
    _tracker?.onEnded();
    final next = _neighbor(1);
    if (next == null) return;
    if (ref.read(autoplayProvider)) {
      _startLesson(next.videoId);
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

  void _cycleSpeed() {
    final index = _speeds.indexOf(_speed);
    final next = _speeds[(index + 1) % _speeds.length];
    setState(() => _speed = next);
    _engine.setSpeed(next);
  }

  String get _speedLabel {
    final text = _speed == _speed.roundToDouble()
        ? _speed.toStringAsFixed(0)
        : _speed.toString().replaceAll('.', '٫');
    return '${arabicDigits(text)}×';
  }

  void _pickSleepTimer() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'مؤقت النوم',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            for (final minutes in [null, 15, 30, 60])
              ListTile(
                title: Text(
                  minutes == null
                      ? 'بدون مؤقت'
                      : 'إيقاف بعد ${arabicDigits(minutes)} دقيقة',
                ),
                trailing: _sleepMinutes == minutes
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _setSleepTimer(minutes);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    setState(() => _sleepMinutes = minutes);
    if (minutes != null) {
      _sleepTimer = Timer(Duration(minutes: minutes), () async {
        if (_isPlaying) await _engine.togglePlay();
        if (mounted) setState(() => _sleepMinutes = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Like the video player, the design specifies this screen dark, always.
    return Theme(
      data: buildTheme(Brightness.dark),
      child: Builder(builder: (context) => _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    final detailAsync = ref.watch(seriesDetailProvider(widget.seriesSlug));
    final detail = detailAsync.value;
    final current = _lessonById(_currentId);
    final next = _neighbor(1);
    final previous = _neighbor(-1);

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

    if (detail != null &&
        current != null &&
        (current.status != LessonStatus.active || current.audioUrl == null)) {
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
                  message: 'الملف الصوتي غير متوفر في موقع المؤسسة.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final seriesTitle = detail?.series.titleAr ?? '';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Design 1n: linear-gradient(180deg, #142019 0%, #0F1613 60%).
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.6],
            colors: [Color(0xFF142019), Color(0xFF0F1613)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackCircle(),
                  Text(
                    'تشغيل صوتي · يعمل في الخلفية',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  _RoundIconButton(
                    icon: _sleepMinutes == null
                        ? Icons.bedtime_outlined
                        : Icons.bedtime,
                    highlighted: _sleepMinutes != null,
                    onTap: _pickSleepTimer,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Artwork card ─────────────────────────────────────────
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [masar.heroGreen, const Color(0xFF17492F)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x73000000),
                        blurRadius: 50,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: masar.gold.withValues(alpha: 0.55),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          ScienceGlyph.initialOf(seriesTitle),
                          style: serif(34, masar.onHero, height: 1),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        seriesTitle,
                        style: serif(
                          18,
                          masar.onHero.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ────────────────────────────────────────────────
              if (current != null) ...[
                Text(
                  'الدرس ${arabicDigits(current.position)} — ${current.titleAr}',
                  textAlign: TextAlign.center,
                  style: serif(24, scheme.onSurface, height: 1.4),
                ),
                const SizedBox(height: 5),
                Text(
                  '$seriesTitle · صوتيات المؤسسة',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ── Seek bar ─────────────────────────────────────────────
              Directionality(
                textDirection: TextDirection.ltr,
                child: Builder(
                  builder: (context) {
                    final seekable = total != null && total > Duration.zero;
                    final fraction = !seekable
                        ? 0.0
                        : (_position.inMilliseconds / total.inMilliseconds)
                              .clamp(0.0, 1.0);
                    final shownFraction = _dragFraction ?? fraction;
                    final shownPosition = !seekable
                        ? _position
                        : Duration(
                            milliseconds:
                                (total.inMilliseconds * shownFraction).round(),
                          );
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            activeTrackColor: scheme.primary,
                            inactiveTrackColor: scheme.surfaceContainerHighest,
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
                                : (v) => setState(() => _dragFraction = v),
                            onChangeEnd: !seekable
                                ? null
                                : (v) => _seekToFraction(v, total),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                clockLabelLtr(shownPosition),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: kMonoFont,
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                total == null ? '--:--' : clockLabelLtr(total),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: kMonoFont,
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_hasSavedOnce) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, size: 13, color: scheme.primary),
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
              const SizedBox(height: 12),

              // ── Controls: speed / prev-play-next / chapters ──────────
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _cycleSpeed,
                      child: Text(
                        _speedLabel,
                        style: TextStyle(
                          fontFamily: kMonoFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _SkipButton(
                          forward: false,
                          enabled: previous != null,
                          onTap: previous == null
                              ? null
                              : () => _startLesson(previous.videoId),
                        ),
                        const SizedBox(width: 22),
                        GestureDetector(
                          onTap: _engine.togglePlay,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 32,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 22),
                        _SkipButton(
                          forward: true,
                          enabled: next != null,
                          onTap: next == null
                              ? null
                              : () => _startLesson(next.videoId),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 19,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Up next ──────────────────────────────────────────────
              if (next != null)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.banner),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _startLesson(next.videoId),
                          child: Text(
                            'التالي: الدرس ${arabicDigits(next.position)} — ${next.titleAr}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      if (next.durationSeconds != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          clockLabelLtr(
                            Duration(seconds: next.durationSeconds!),
                          ),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: kMonoFont,
                            fontSize: 11,
                            color: masar.textFaint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // ── Chapter index (tap to seek) ──────────────────────────
              if (current != null && current.chapters.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'فهرس الدرس',
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
                      for (final (index, chapter)
                          in current.chapters.indexed) ...[
                        _ChapterRow(
                          chapter: chapter,
                          showDivider: index != current.chapters.length - 1,
                          onTap: chapter.startSeconds == null
                              ? null
                              : () => _engine.seekTo(
                                  Duration(seconds: chapter.startSeconds!),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.forward,
    required this.enabled,
    this.onTap,
  });

  final bool forward;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          // RTL: "next" advances the series, drawn as skip_previous shape.
          forward ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
          size: 26,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.showDivider,
    this.onTap,
  });

  final CatalogChapter chapter;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: showDivider
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.dividerTheme.color!),
                  ),
                )
              : null,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16,
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chapter.startSeconds != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 12,
                    top: 2,
                  ),
                  child: Text(
                    clockLabelLtr(Duration(seconds: chapter.startSeconds!)),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: kMonoFont,
                      fontSize: 11,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  chapter.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    height: 1.6,
                    color: onTap == null
                        ? masar.textMuted
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
