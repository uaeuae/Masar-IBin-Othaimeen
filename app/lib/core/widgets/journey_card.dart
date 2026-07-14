import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';
import '../formatters.dart';
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
    required this.scienceName,
    this.scienceSortOrder = 1,
    this.seriesPreview = '',
    this.enrolled = false,
    this.progress,
    this.onTap,
  });

  final String title;
  final JourneyLevel level;
  final int stageCount;
  final String scienceName;
  final int scienceSortOrder;
  final String seriesPreview;
  final bool enrolled;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final meta = '${stageCountLabel(stageCount)} · ${level.labelAr}';

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
