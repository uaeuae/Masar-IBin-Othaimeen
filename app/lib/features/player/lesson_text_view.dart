import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../data/models/enums.dart';
import 'lesson_text.dart';

/// How long auto-scroll stands down after the reader scrolls by hand.
const _manualScrollGrace = Duration(seconds: 4);

/// The read-along panel: the lesson's text with the sentence being spoken
/// highlighted, taking the artwork card's place in the audio player.
///
/// Sentence times on a transcript are *estimated* between the markers the
/// foundation timestamps — exact at every section start, drifting a little in
/// between. Hence «مزامنة تقريبية» on screen, tap-to-seek, and long-press to
/// re-anchor when the estimate has slipped. Matn text carries no per-sentence
/// time at all (the speech isn't in it), so there the whole passage lights up.
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

  bool get _autoScrollAllowed {
    final last = _lastManualScroll;
    return last == null || DateTime.now().difference(last) > _manualScrollGrace;
  }

  void _scrollTo(int index) {
    if (index < 0 || !_autoScrollAllowed || !mounted) return;
    final context = _keys[index]?.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.35,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Far off-screen after a seek, so the row isn't built yet: jump to roughly
    // the right place, then let the next frame land it precisely.
    if (!_controller.hasClients) return;
    final total = math.max(widget.text.sentences.length - 1, 1);
    final estimate = _controller.position.maxScrollExtent * (index / total);
    _controller.jumpTo(
      estimate.clamp(0.0, _controller.position.maxScrollExtent),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settled = _keys[index]?.currentContext;
      if (settled != null && mounted) {
        Scrollable.ensureVisible(settled, alignment: 0.35);
      }
    });
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
        final highlighted = isMatn
            ? sectionIndex == currentSection
            : i == _current;
        final key = _keys.putIfAbsent(i, GlobalKey.new);
        rows.add(
          _SentenceRow(
            key: key,
            sentence: sentence,
            highlighted: highlighted,
            onTap: () {
              final t = sentence.t ?? sentence.sectionStart;
              if (t != null) widget.onSeek(Duration(seconds: t));
            },
            onLongPress: isMatn ? null : () => _resync(sentence),
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
                    : widget.text.isMeasured
                    ? Icons.graphic_eq_rounded
                    : Icons.subject_rounded,
                size: 13,
                color: masar.textFaint,
              ),
              const SizedBox(width: 6),
              Text(
                isMatn
                    ? 'نص المتن'
                    : widget.text.isMeasured
                    ? 'المس جملة للانتقال'
                    : 'مزامنة تقريبية · المس جملة للانتقال',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: masar.textFaint,
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
    required this.onTap,
    this.onLongPress,
  });

  final TextSentence sentence;
  final bool highlighted;
  final VoidCallback onTap;
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
