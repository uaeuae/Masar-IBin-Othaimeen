import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/series_tile.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/stage_timeline.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';
import 'journeys_providers.dart';

class JourneyDetailScreen extends ConsumerWidget {
  const JourneyDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(journeyDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            Skeleton(height: 32, width: 220),
            SizedBox(height: AppSpacing.md),
            Skeleton(height: 16, width: double.infinity),
            SizedBox(height: AppSpacing.xl),
            Skeleton(height: 120, width: double.infinity),
          ],
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل المسار',
        ),
        data: (detail) {
          if (detail == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'المسار غير موجود',
            );
          }
          return _JourneyDetailBody(detail: detail);
        },
      ),
    );
  }
}

class _JourneyDetailBody extends ConsumerWidget {
  const _JourneyDetailBody({required this.detail});

  final JourneyDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = detail.summary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                summary.titleAr,
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            LevelBadge(level: summary.level),
          ],
        ),
        if (summary.descriptionAr != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            summary.descriptionAr!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${stageCountLabel(summary.stageCount)} · ${lessonCountLabel(summary.lessonCount)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (summary.enrolled) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: summary.progress,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                percentLabel(summary.progress),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ] else
          FilledButton.icon(
            onPressed: () async {
              await ref.read(progressRepositoryProvider).enroll(summary.slug);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الالتحاق بالمسار — وفقك الله'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.flag_rounded),
            label: const Text('ابدأ المسار'),
          ),
        const SizedBox(height: AppSpacing.xl),
        for (final (index, stage) in detail.stages.indexed)
          StageTimelineNode(
            index: stage.position,
            title: stage.titleAr,
            description: stage.descriptionAr,
            isLast: index == detail.stages.length - 1,
            state: stage.isDone
                ? StageState.done
                : stage.position == detail.currentStagePosition
                ? StageState.current
                : StageState.upcoming,
            child: Column(
              children: [
                for (final series in stage.series)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SeriesTile(
                      title: series.titleAr,
                      lessonCount: series.lessonCount,
                      completedCount: series.completedCount,
                      totalDuration: Duration(
                        seconds: series.totalDurationSeconds,
                      ),
                      onTap: () => context.push('/series/${series.slug}'),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
