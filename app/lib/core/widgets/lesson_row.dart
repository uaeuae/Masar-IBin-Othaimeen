import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

enum LessonRowState { completed, current, upcoming, unavailable }

/// One lesson row inside the series-detail group card, per the design:
/// completed = green check circle + strikethrough, current = tinted row with
/// play ring and an inline progress bar, upcoming = hollow circle.
class LessonRow extends StatelessWidget {
  const LessonRow({
    super.key,
    required this.title,
    required this.state,
    this.duration,
    this.progress = 0,
    this.showDivider = true,
    this.onTap,
  });

  final String title;
  final LessonRowState state;
  final Duration? duration;

  /// In-lesson progress 0–1 (rendered only for [LessonRowState.current]).
  final double progress;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    final Widget leading = switch (state) {
      LessonRowState.completed => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: masar.heroGreen,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.check_rounded, size: 15, color: masar.onHero),
      ),
      LessonRowState.current => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: scheme.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.play_arrow_rounded, size: 13, color: scheme.primary),
      ),
      LessonRowState.upcoming => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: masar.timelineInactive, width: 1.5),
        ),
      ),
      LessonRowState.unavailable => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.link_off_rounded, size: 14, color: masar.textMuted),
      ),
    };

    final titleStyle = switch (state) {
      LessonRowState.completed => theme.textTheme.bodyMedium?.copyWith(
        color: masar.textMuted,
        decoration: TextDecoration.lineThrough,
        decorationColor: masar.textMuted,
      ),
      LessonRowState.current => theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      LessonRowState.upcoming => theme.textTheme.bodyMedium,
      LessonRowState.unavailable => theme.textTheme.bodyMedium?.copyWith(
        color: masar.textMuted,
      ),
    };

    return Material(
      color: state == LessonRowState.current
          ? scheme.surfaceContainerHigh
          : Colors.transparent,
      child: InkWell(
        onTap: state == LessonRowState.unavailable ? null : onTap,
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
            vertical: 13,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state == LessonRowState.unavailable
                          ? '$title — غير متاح حاليًا'
                          : title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      clockLabel(duration!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: state == LessonRowState.current
                            ? scheme.onSurfaceVariant
                            : masar.textFaint,
                      ),
                    ),
                  ],
                ],
              ),
              if (state == LessonRowState.current && progress > 0) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 38),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: masar.highlightTrack,
                    ),
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
