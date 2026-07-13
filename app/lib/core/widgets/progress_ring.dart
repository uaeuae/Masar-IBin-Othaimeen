import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatters.dart';

/// Circular progress indicator used wherever journey/series progress appears.
/// Progress is the emotional core of the app — rings should feel rewarding.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 5,
    this.showLabel = false,
    this.child,
  }) : assert(
         child == null || !showLabel,
         'Pass either showLabel or a child, not both',
       );

  /// 0.0 → 1.0
  final double progress;
  final double size;
  final double strokeWidth;

  /// Renders "٪٦٥" in the center.
  final bool showLabel;

  /// Custom center content (e.g. a lesson index).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);
    final complete = clamped >= 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          trackColor: scheme.surfaceContainerHighest,
          color: complete ? scheme.primary : scheme.primary,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: complete && child == null && !showLabel
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.5,
                  color: scheme.primary,
                )
              : showLabel
              ? Text(
                  percentLabel(clamped),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}
