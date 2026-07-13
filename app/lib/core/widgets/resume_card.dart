import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../formatters.dart';

/// Horizontal "متابعة المشاهدة" card on the home screen.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.lessonTitle,
    required this.seriesTitle,
    required this.videoId,
    required this.progress,
    this.remaining,
    this.onTap,
  });

  final String lessonTitle;
  final String seriesTitle;
  final String videoId;

  /// 0.0–1.0
  final double progress;
  final Duration? remaining;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: 300,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.tile - 4),
                  child: SizedBox(
                    width: 104,
                    height: 66,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              'https://i.ytimg.com/vi/$videoId/mqdefault.jpg',
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => ColoredBox(
                            color: scheme.primaryContainer,
                            child: Icon(
                              Icons.play_circle_rounded,
                              color: scheme.primary,
                              size: 30,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seriesTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lessonTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (remaining != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'متبقي ${durationLabel(remaining!)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
