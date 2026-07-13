import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

/// Series row used in journey stages and the library.
class SeriesTile extends StatelessWidget {
  const SeriesTile({
    super.key,
    required this.title,
    required this.lessonCount,
    required this.completedCount,
    this.totalDuration,
    this.onTap,
  });

  final String title;
  final int lessonCount;
  final int completedCount;
  final Duration? totalDuration;
  final VoidCallback? onTap;

  double get _progress => lessonCount == 0 ? 0 : completedCount / lessonCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final started = completedCount > 0;

    final meta = [
      lessonCountLabel(lessonCount),
      if (totalDuration != null && totalDuration! > Duration.zero)
        durationLabel(totalDuration!),
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      meta,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (started) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 5,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            percentLabel(_progress),
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
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
