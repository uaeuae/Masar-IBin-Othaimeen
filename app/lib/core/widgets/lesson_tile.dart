import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';
import 'progress_ring.dart';

/// One lesson row inside a series. The leading indicator tells the story:
/// filled check = completed, partial ring = in progress, numbered circle = not started.
class LessonTile extends StatelessWidget {
  const LessonTile({
    super.key,
    required this.index,
    required this.title,
    this.duration,
    this.progress = 0,
    this.isPlaying = false,
    this.unavailable = false,
    this.onTap,
  });

  /// 1-based position within the series.
  final int index;
  final String title;
  final Duration? duration;

  /// 0.0–1.0; >= 1.0 renders as completed.
  final double progress;
  final bool isPlaying;
  final bool unavailable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completed = progress >= 1.0;
    final started = progress > 0 && !completed;

    final Widget leading;
    if (unavailable) {
      leading = _circle(
        background: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.link_off_rounded,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
      );
    } else if (completed) {
      leading = _circle(
        background: scheme.primary,
        child: Icon(Icons.check_rounded, size: 22, color: scheme.onPrimary),
      );
    } else if (started) {
      leading = ProgressRing(
        progress: progress,
        size: 40,
        strokeWidth: 3.5,
        child: Text(arabicDigits(index), style: theme.textTheme.labelMedium),
      );
    } else {
      leading = _circle(
        background: Colors.transparent,
        border: Border.all(color: scheme.outlineVariant, width: 1.5),
        child: Text(arabicDigits(index), style: theme.textTheme.labelMedium),
      );
    }

    final subtitleParts = <String>[
      if (unavailable)
        'هذا الدرس غير متاح حاليًا'
      else if (duration != null)
        durationLabel(duration!),
    ];

    return Material(
      color: isPlaying
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        onTap: unavailable ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Opacity(opacity: unavailable ? 0.6 : 1, child: leading),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: unavailable
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        fontWeight: isPlaying
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPlaying) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.graphic_eq_rounded, color: scheme.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle({
    required Color background,
    Border? border,
    required Widget child,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
