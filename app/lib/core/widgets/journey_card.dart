import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';
import '../formatters.dart';
import 'level_badge.dart';
import 'scholar_avatar.dart';
import 'science_glyph.dart';

/// Journey card per the design's المسارات list: glyph + title row with an
/// optional "ملتحق" badge, the stage-sequence teaser line, then either a
/// progress bar + meta (enrolled) or just the meta line.
class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.title,
    required this.level,
    required this.stageCount,
    this.totalDurationSeconds = 0,
    required this.scienceName,
    this.scienceSortOrder = 1,
    this.seriesPreview = '',
    this.scholars = const [],
    this.enrolled = false,
    this.progress,
    this.onTap,
  });

  final String title;
  final JourneyLevel level;
  final int stageCount;

  /// Total listening time across the journey — the same figure the library
  /// shows on a series, which is what people actually plan around.
  final int totalDurationSeconds;
  final String scienceName;
  final int scienceSortOrder;
  final String seriesPreview;

  /// Whose شرح the journey is built from. Load-bearing rather than decorative:
  /// «مسار العقيدة» exists for more than one scholar, so without this the list
  /// shows two identical cards.
  final List<ScholarInfo> scholars;
  final bool enrolled;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // The level moved out of this line and onto a badge; what belongs here is
    // the commitment: how many stages, and how many hours.
    final meta = [
      stageCountLabel(stageCount),
      if (totalDurationSeconds > 0)
        durationLabel(Duration(seconds: totalDurationSeconds)),
    ].join(' · ');

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ScienceGlyph(
                    nameAr: scienceName,
                    sortOrder: scienceSortOrder,
                    size: 38,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (enrolled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: Text(
                        'ملتحق',
                        style: TextStyle(
                          fontFamily: kUiFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (scholars.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: scholars.length == 1
                      ? ScholarLine(scholar: scholars.single, avatarSize: 20)
                      // Mixed مسار: overlapping roundels then «بشرح فلان وفلان»,
                      // as the design draws it (4c).
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StackedScholarAvatars(scholars: scholars),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'بشرح ${scholars.map((s) => s.nameAr).join(' و')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
              if (seriesPreview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  seriesPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // The level is a tag now, not a filter — every journey is listed
              // and says which level it suits.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: LevelBadge(level: level, compact: true),
              ),
              const SizedBox(height: 8),
              if (enrolled && progress != null)
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: LinearProgressIndicator(
                          value: progress!.clamp(0.0, 1.0),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      meta,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  meta,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
