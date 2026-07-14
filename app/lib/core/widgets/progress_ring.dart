import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../formatters.dart';

/// Circular progress ring — the design's مساراتي row uses a 52px ring with
/// the percent bold inside. Track is the green tint (light) / dark border.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 52,
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

  /// Renders "٣٣٪" in the center.
  final bool showLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final clamped = progress.clamp(0.0, 1.0);
    final complete = clamped >= 1.0;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          trackColor: isDark
              ? scheme.surfaceContainerHighest
              : scheme.primaryContainer,
          color: scheme.primary,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: complete && child == null && !showLabel
              ? Icon(
                  Icons.check_rounded,
                  size: size * 0.45,
                  color: scheme.primary,
                )
              : showLabel
              ? Text(
                  percentLabel(clamped),
                  style: TextStyle(
                    fontSize: size * 0.23,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
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
