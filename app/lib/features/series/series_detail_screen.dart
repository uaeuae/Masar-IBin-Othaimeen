import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/lesson_tile.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';
import 'series_providers.dart';

class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(seriesDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            Skeleton(height: 28, width: 240),
            SizedBox(height: AppSpacing.lg),
            Skeleton(height: 56, width: double.infinity),
            SizedBox(height: AppSpacing.sm),
            Skeleton(height: 56, width: double.infinity),
          ],
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل السلسلة',
        ),
        data: (detail) {
          if (detail == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'السلسلة غير موجودة',
            );
          }
          return _SeriesDetailBody(detail: detail);
        },
      ),
    );
  }
}

class _SeriesDetailBody extends StatelessWidget {
  const _SeriesDetailBody({required this.detail});

  final SeriesDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final series = detail.series;
    final resume = detail.resumeTarget;
    final started =
        series.completedCount > 0 ||
        detail.lessons.any((l) => l.watchedSeconds > 0);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(series.titleAr, style: theme.textTheme.headlineSmall),
        if (series.descriptionAr != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            series.descriptionAr!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text(
          [
            lessonCountLabel(series.lessonCount),
            if (series.totalDurationSeconds > 0)
              durationLabel(Duration(seconds: series.totalDurationSeconds)),
          ].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (series.completedCount > 0) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: series.progress,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                percentLabel(series.progress),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (resume != null)
          FilledButton.icon(
            onPressed: () =>
                context.push('/player/${resume.videoId}?series=${series.slug}'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(started ? 'استئناف' : 'ابدأ المشاهدة'),
          ),
        const SizedBox(height: AppSpacing.lg),
        for (final lesson in detail.lessons)
          LessonTile(
            index: lesson.position,
            title: lesson.titleAr,
            duration: lesson.durationSeconds == null
                ? null
                : Duration(seconds: lesson.durationSeconds!),
            progress: lesson.progress,
            unavailable: lesson.status != LessonStatus.active,
            onTap: () =>
                context.push('/player/${lesson.videoId}?series=${series.slug}'),
          ),
      ],
    );
  }
}
