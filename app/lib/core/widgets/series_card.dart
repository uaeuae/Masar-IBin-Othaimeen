import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/view_models.dart';
import '../formatters.dart';
import 'level_badge.dart';
import 'scholar_avatar.dart';

/// White card: Amiri title + level badge, an attribution row, «X حلقة · Y ساعة»,
/// and progress once started.
///
/// The attribution row is the design's 3b card anatomy. It disambiguates —
/// «شرح كتاب التوحيد» is taught by more than one scholar — but it earns its
/// place even with one, because an unattributed card reads as though the app
/// itself were the author.
class SeriesCard extends StatelessWidget {
  const SeriesCard({
    super.key,
    required this.series,
    this.scholar,
    this.scienceNameAr,
  });

  final SeriesWithProgress series;

  /// Omitted on a scholar's own profile, where repeating his name on every
  /// card says nothing; that screen passes [scienceNameAr] instead.
  final ScholarInfo? scholar;
  final String? scienceNameAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.push('/series/${series.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      series.titleAr,
                      style: serif(19, scheme.onSurface),
                    ),
                  ),
                  if (series.level != null) ...[
                    const SizedBox(width: 10),
                    LevelBadge(level: series.level!, compact: true),
                  ],
                ],
              ),
              if (scholar != null) ...[
                const SizedBox(height: 8),
                ScholarLine(scholar: scholar!),
              ],
              const SizedBox(height: 8),
              Text(
                [
                  if (scienceNameAr != null) scienceNameAr!,
                  episodeCountLabel(series.lessonCount),
                  if (series.totalDurationSeconds > 0)
                    durationLabel(
                      Duration(seconds: series.totalDurationSeconds),
                    ),
                ].join(' · '),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (series.started) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: LinearProgressIndicator(
                          value: series.progress,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${arabicDigits(series.completedCount)} / ${arabicDigits(series.lessonCount)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
