import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// One step of a coach-mark sequence: a real widget to point at, and what to
/// say about it.
class CoachMark {
  const CoachMark({
    required this.key,
    required this.title,
    required this.body,
  });

  /// Attached to the actual control, so the mark can never point somewhere the
  /// feature no longer is — unlike a slideshow, which drifts silently.
  final GlobalKey key;
  final String title;
  final String body;
}

/// Runs a sequence of coach marks over the current screen.
///
/// Hand-rolled rather than a package: it is a scrim with a hole in it and a
/// caption, and the app has no other use for the dependency.
Future<void> showCoachMarks(
  BuildContext context,
  List<CoachMark> marks,
) async {
  final visible = <CoachMark>[];
  for (final mark in marks) {
    // Skip anything not on screen: a mark pointing at nothing would darken the
    // display and explain a control the reader cannot see.
    final box = mark.key.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) visible.add(mark);
  }
  if (visible.isEmpty || !context.mounted) return;

  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => _CoachMarkOverlay(marks: visible),
    ),
  );
}

class _CoachMarkOverlay extends StatefulWidget {
  const _CoachMarkOverlay({required this.marks});

  final List<CoachMark> marks;

  @override
  State<_CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<_CoachMarkOverlay> {
  int _index = 0;

  void _next() {
    if (_index + 1 >= widget.marks.length) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index++);
    }
  }

  Rect? _targetRect() {
    final box = widget.marks[_index].key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final mark = widget.marks[_index];
    final size = MediaQuery.sizeOf(context);
    final rect = _targetRect();
    if (rect == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _next());
      return const SizedBox.shrink();
    }

    final hole = rect.inflate(8);
    // Caption goes under the target unless that would run off the bottom.
    final below = hole.bottom + 190 < size.height;
    final captionTop = below ? hole.bottom + 14 : null;
    final captionBottom = below ? null : size.height - hole.top + 14;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _next,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ScrimWithHole(hole: hole)),
            ),
            Positioned(
              top: captionTop,
              bottom: captionBottom,
              left: 20,
              right: 20,
              child: _Caption(
                mark: mark,
                step: _index + 1,
                total: widget.marks.length,
                onNext: _next,
                onSkip: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Darkens everything except a rounded window over the target.
class _ScrimWithHole extends CustomPainter {
  const _ScrimWithHole({required this.hole});

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()..addRect(Offset.zero & size);
    final window = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, scrim, window),
      Paint()..color = const Color(0xCC0B120E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFD9B26A),
    );
  }

  @override
  bool shouldRepaint(_ScrimWithHole oldDelegate) => oldDelegate.hole != hole;
}

class _Caption extends StatelessWidget {
  const _Caption({
    required this.mark,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final CoachMark mark;
  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mark.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            mark.body,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$step / $total',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: kMonoFont,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onSkip, child: const Text('تخطٍ')),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onNext,
                child: Text(step == total ? 'تم' : 'التالي'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
