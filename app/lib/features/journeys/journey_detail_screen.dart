import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/level_badge.dart';
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
      body: detailAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Skeleton(height: 200, width: double.infinity),
          ),
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
    final masar = masarColorsOf(context);
    final summary = detail.summary;
    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Green gradient header carries the journey identity ─────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: masar.headerGradient,
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackCircle(style: BackCircleStyle.onHero),
                  LevelBadge(level: summary.level, onHero: true),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                summary.titleAr,
                style: serif(30, masar.onHero, height: 1.2),
              ),
              if (summary.descriptionAr != null) ...[
                const SizedBox(height: 8),
                Text(
                  summary.descriptionAr!,
                  style: TextStyle(
                    fontFamily: kUiFont,
                    fontSize: 13,
                    height: 1.7,
                    color: masar.onHeroDim,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                [
                  stageCountLabel(summary.stageCount),
                  lessonCountLabel(summary.lessonCount),
                  if (summary.totalDurationSeconds > 0)
                    durationLabel(
                      Duration(seconds: summary.totalDurationSeconds),
                    ),
                ].join(' · '),
                style: TextStyle(
                  fontFamily: kUiFont,
                  fontSize: 12,
                  color: masar.onHeroDim,
                ),
              ),
            ],
          ),
        ),

        // ── Stage timeline ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              for (final (index, stage) in detail.stages.indexed)
                StageTimelineNode(
                  index: stage.position,
                  isLast: index == detail.stages.length - 1,
                  state: stage.isDone
                      ? StageState.done
                      : stage.position == detail.currentStagePosition
                      ? StageState.current
                      : StageState.upcoming,
                  child: _StageContent(
                    detail: detail,
                    stage: stage,
                    state: stage.isDone
                        ? StageState.done
                        : stage.position == detail.currentStagePosition
                        ? StageState.current
                        : StageState.upcoming,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StageContent extends ConsumerWidget {
  const _StageContent({
    required this.detail,
    required this.stage,
    required this.state,
  });

  final JourneyDetail detail;
  final StageDetail stage;
  final StageState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    // The design shows one series per stage; support several by stacking.
    switch (state) {
      case StageState.done:
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final series in stage.series) ...[
                GestureDetector(
                  onTap: () => context.push('/series/${series.slug}'),
                  child: Text(
                    series.titleAr,
                    style: serif(18, scheme.onSurface),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'مكتملة — ${arabicDigits(series.completedCount)} من ${lessonCountLabel(series.lessonCount)} ✓',
                  style: TextStyle(
                    fontFamily: kUiFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
        );

      case StageState.upcoming:
        return Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final series in stage.series) ...[
                GestureDetector(
                  onTap: () => context.push('/series/${series.slug}'),
                  child: Text(series.titleAr, style: serif(18, masar.chipText)),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    lessonCountLabel(series.lessonCount),
                    if (series.totalDurationSeconds > 0)
                      durationLabel(
                        Duration(seconds: series.totalDurationSeconds),
                      ),
                  ].join(' · '),
                  style: TextStyle(
                    fontFamily: kUiFont,
                    fontSize: 12,
                    color: masar.textMuted,
                  ),
                ),
              ],
            ],
          ),
        );

      case StageState.current:
        return Column(
          children: [
            for (final series in stage.series)
              GestureDetector(
                onTap: () => context.push('/series/${series.slug}'),
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: series == stage.series.last ? 0 : 8,
                  ),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadius.group),
                    border: Border.all(color: scheme.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: masar.heroShadow,
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              series.titleAr,
                              style: serif(18, scheme.onSurface),
                            ),
                          ),
                          Text(
                            '${arabicDigits(series.completedCount)} من ${arabicDigits(series.lessonCount)}',
                            style: TextStyle(
                              fontFamily: kUiFont,
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: LinearProgressIndicator(
                          value: series.progress,
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ResumePill(detail: detail, series: series),
                    ],
                  ),
                ),
              ),
          ],
        );
    }
  }
}

class _ResumePill extends ConsumerWidget {
  const _ResumePill({required this.detail, required this.series});

  final JourneyDetail detail;
  final SeriesWithProgress series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final nextLesson = (series.completedCount + 1).clamp(
      1,
      series.lessonCount == 0 ? 1 : series.lessonCount,
    );
    final label = detail.summary.enrolled
        ? (series.started
              ? 'استئناف — الدرس ${arabicDigits(nextLesson)}'
              : 'ابدأ — الدرس ${arabicDigits(nextLesson)}')
        : 'ابدأ المسار — الدرس ${arabicDigits(nextLesson)}';

    return GestureDetector(
      onTap: () async {
        if (!detail.summary.enrolled) {
          await ref
              .read(progressRepositoryProvider)
              .enroll(detail.summary.slug);
        }
        // Resume straight into the next lesson, as the design's CTA does.
        final seriesDetail = await ref
            .read(catalogRepositoryProvider)
            .watchSeriesDetail(series.slug)
            .first;
        final target = seriesDetail?.resumeTarget;
        if (!context.mounted) return;
        if (target != null) {
          context.push('/player/${target.videoId}?series=${series.slug}');
        } else {
          context.push('/series/${series.slug}');
        }
      },
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kUiFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
