import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/models/enums.dart';
import 'lesson_text.dart';

/// How long auto-scroll stands down after the reader scrolls by hand.
const _manualScrollGrace = Duration(seconds: 4);

/// Frames [_LessonTextViewState._scrollTo] may spend closing in on a row that
/// is too far off-screen to have been built. Bounded so a target that can never
/// be reached — a script shorter than the position it is asked for — cannot
/// spin a jump on every frame.
const _maxScrollAttempts = 8;

/// How near, in rows, the estimate has to get before [_scrollTo] stops
/// estimating and walks the rest a viewport at a time.
const _stepWithin = 6;

/// The read-along panel: the lesson's text with the sentence being spoken
/// highlighted, taking the artwork card's place in the audio player.
///
/// Three modes, because the timing behind a lesson comes in three strengths:
///
/// - **transcript, synced** — each sentence was placed inside bounds the
///   aligner could verify. The spoken sentence is highlighted, the view follows
///   it, a tap seeks to it, and a long-press re-anchors a drifted estimate.
/// - **transcript, not synced** — the text is right and the times are not, so
///   the panel becomes a reading page: no highlight, no auto-scroll, no seeking.
///   Showing a confident highlight that is minutes out is worse than showing
///   none, and that is what shipped.
/// - **matn** — the speech is not in this text at all, so there is nothing to
///   time below section level; the whole passage between two of the
///   foundation's own markers lights up, which is exact.
class LessonTextView extends StatefulWidget {
  const LessonTextView({
    super.key,
    required this.text,
    required this.position,
    required this.onSeek,
    required this.height,
  });

  final LessonText text;
  final Duration position;
  final ValueChanged<Duration> onSeek;
  final double height;

  @override
  State<LessonTextView> createState() => _LessonTextViewState();
}

class _LessonTextViewState extends State<LessonTextView> {
  final _controller = ScrollController();
  final _keys = <int, GlobalKey>{};

  /// Correction the reader applied via long-press, for when the estimate has
  /// drifted. Session-only, and dropped when the lesson changes.
  Duration _syncOffset = Duration.zero;
  DateTime? _lastManualScroll;
  int _current = -1;

  @override
  void initState() {
    super.initState();
    _current = _indexNow();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(_current));
  }

  @override
  void didUpdateWidget(LessonTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text.lessonId != widget.text.lessonId) {
      _syncOffset = Duration.zero;
      _keys.clear();
    }
    final next = _indexNow();
    if (next != _current) {
      setState(() => _current = next);
      _scrollTo(next);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexNow() => widget.text.indexAt(widget.position - _syncOffset);

  /// Whether this lesson's times are good enough to point at a sentence with.
  ///
  /// Matn text never claimed per-sentence timing — the speech is not in it, so
  /// it lights the whole passage its markers bound, and those markers are the
  /// foundation's own. A transcript claims to know each sentence, and cannot
  /// always back it; see [LessonText.synced].
  bool get _canFollow =>
      widget.text.kind == LessonTextKind.matn || widget.text.synced;

  bool get _autoScrollAllowed {
    final last = _lastManualScroll;
    return last == null || DateTime.now().difference(last) > _manualScrollGrace;
  }

  /// Brings sentence [index] into view, closing in on it over several frames if
  /// it is too far away to have been built yet.
  ///
  /// Landing it in one jump is not possible. A lazy `ListView` derives
  /// `maxScrollExtent` from the children it has actually laid out, so while
  /// only the opening rows exist the extent is a guess — and a lesson opens on
  /// its shortest sentences (البسملة, a greeting) before any real exposition,
  /// which makes that guess a large underestimate. One jump computed from it
  /// lands nowhere near the target, the target row therefore still is not
  /// built, and the old single retry gave up there.
  ///
  /// That was invisible for a seek inside the text, where the destination is
  /// already on screen, and broke exactly one case: **resuming**. Reopening a
  /// lesson an hour in left the panel at the top of the script with nothing
  /// highlighted, until the next sentence came round and moved it again.
  ///
  /// Each pass re-reads the extent, which is a better estimate every time more
  /// rows have been measured, so this converges instead of guessing twice.
  void _scrollTo(int index, {int attempt = 0}) {
    if (index < 0 || !_canFollow || !_autoScrollAllowed || !mounted) return;
    final context = _keys[index]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.35,
        // Instant once we are converging on a distant row: an animation per
        // pass would race the next one and crawl there.
        duration: attempt == 0
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!_controller.hasClients || attempt >= _maxScrollAttempts) return;
    final position = _controller.position;
    final nearest = _nearestBuilt(index);

    final double target;
    if (nearest == null || (nearest - index).abs() > _stepWithin) {
      // Far away, and the only thing to steer by is the list's own extent.
      // `index / length` assumes every row is the same height, which sentences
      // are not, so this lands in the neighbourhood rather than on the row.
      final total = math.max(widget.text.sentences.length - 1, 1);
      target = position.maxScrollExtent * (index / total);
    } else {
      // In the neighbourhood: close the rest on foot. A viewport's worth at a
      // time builds the rows in between, and those heights are the only thing
      // that can say where the target actually is — the estimate above cannot,
      // which is why it used to stop a few sentences short and leave nothing
      // highlighted on screen.
      target =
          position.pixels +
          (index > nearest
              ? position.viewportDimension
              : -position.viewportDimension);
    }

    _controller.jumpTo(target.clamp(0.0, position.maxScrollExtent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Abandoned if playback has since moved on — the newer target owns the
      // view, and two converging loops would fight over it.
      if (mounted && _current == index) _scrollTo(index, attempt: attempt + 1);
    });
  }

  /// The built row closest to [index], or null while none is.
  ///
  /// Only on-screen rows have a context, so this is also the answer to "how
  /// far is the view from where it should be", in rows.
  int? _nearestBuilt(int index) {
    int? nearest;
    for (final entry in _keys.entries) {
      if (entry.value.currentContext == null) continue;
      if (nearest == null || (entry.key - index).abs() < (nearest - index).abs()) {
        nearest = entry.key;
      }
    }
    return nearest;
  }

  void _resync(TextSentence sentence) {
    final t = sentence.t ?? sentence.sectionStart;
    if (t == null) return;
    setState(() {
      _syncOffset = widget.position - Duration(seconds: t);
      _current = _indexNow();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تمت المزامنة من هذا الموضع'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);
    final isMatn = widget.text.kind == LessonTextKind.matn;
    final currentSection = widget.text.sectionOf(_current);

    var index = 0;
    final rows = <Widget>[];
    for (final (sectionIndex, section) in widget.text.sections.indexed) {
      if (section.title.trim().isNotEmpty) {
        rows.add(_SectionHeader(section: section));
      }
      for (final sentence in section.sentences) {
        final i = index++;
        // Unsynced: nothing is highlighted, and nothing is tappable either. A
        // tap seeks to the sentence's own timestamp, so offering it would be
        // the same untruth as the highlight — pointing at a moment we cannot
        // vouch for. Long-press re-anchors against the estimate, which is
        // meaningless when there is no estimate worth correcting.
        final highlighted = !_canFollow
            ? false
            : isMatn
            ? sectionIndex == currentSection
            : i == _current;
        final key = _keys.putIfAbsent(i, GlobalKey.new);
        rows.add(
          _SentenceRow(
            key: key,
            sentence: sentence,
            highlighted: highlighted,
            onTap: !_canFollow
                ? null
                : () {
                    final t = sentence.t ?? sentence.sectionStart;
                    if (t != null) widget.onSeek(Duration(seconds: t));
                  },
            onLongPress: (isMatn || !_canFollow)
                ? null
                : () => _resync(sentence),
          ),
        );
      }
    }

    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isMatn
                    ? Icons.menu_book_rounded
                    : _canFollow
                    ? Icons.graphic_eq_rounded
                    : Icons.subject_rounded,
                size: 13,
                color: masar.textFaint,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  isMatn
                      ? 'نص المتن'
                      : _canFollow
                      ? 'المس جملة للانتقال'
                      // Says the text is here to read, not that the sync is
                      // merely rough — «تقريبية» invited the reader to trust a
                      // highlight that could be minutes out.
                      : 'لا توجد مزامنة لهذا الدرس — النص للقراءة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: masar.textFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Only a real drag stands auto-scroll down — our own
                // animations must not silence it.
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _lastManualScroll = DateTime.now();
                }
                return false;
              },
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    scheme.onSurface,
                    scheme.onSurface,
                    Colors.transparent,
                  ],
                  stops: const [0, 0.06, 0.9, 1],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: ListView(
                  controller: _controller,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: rows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final TextSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 14, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.start != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 3),
              child: Text(
                clockLabelLtr(Duration(seconds: section.start!)),
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: kMonoFont,
                  fontSize: 10.5,
                  color: scheme.primary,
                ),
              ),
            ),
          Expanded(
            child: Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 13,
                color: scheme.primary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceRow extends StatelessWidget {
  const _SentenceRow({
    super.key,
    required this.sentence,
    required this.highlighted,
    this.onTap,
    this.onLongPress,
  });

  final TextSentence sentence;
  final bool highlighted;

  /// Null on an unsynced lesson: the row is text to read, not a seek target.
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final masar = masarColorsOf(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          sentence.text,
          style: serif(
            16,
            highlighted ? scheme.onSurface : masar.textMuted,
            height: 1.9,
          ),
        ),
      ),
    );
  }
}
