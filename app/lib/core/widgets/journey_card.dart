import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';
import '../formatters.dart';
import 'level_badge.dart';

/// Card presenting a learning journey (مسار) in lists and on the home screen.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.title,
    required this.level,
    required this.stageCount,
    required this.lessonCount,
    this.description,
    this.progress,
    this.coverUrl,
    this.onTap,
  });

  final String title;
  final JourneyLevel level;
  final int stageCount;
  final int lessonCount;
  final String? description;

  /// null = not enrolled; 0.0–1.0 shows a progress footer.
  final double? progress;
  final String? coverUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 21 / 9,
              child: coverUrl != null
                  ? CachedNetworkImage(imageUrl: coverUrl!, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: AlignmentDirectional.topStart,
                          end: AlignmentDirectional.bottomEnd,
                          colors: [
                            scheme.primaryContainer,
                            scheme.primaryContainer.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: Align(
                        alignment: const AlignmentDirectional(0.9, 1.6),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 72,
                          color: scheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      LevelBadge(level: level),
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${stageCountLabel(stageCount)} · ${lessonCountLabel(lessonCount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress!.clamp(0.0, 1.0),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          percentLabel(progress!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
