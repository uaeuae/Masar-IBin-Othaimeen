import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/resume_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton.dart';
import '../journeys/journeys_providers.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching =
        ref.watch(continueWatchingProvider).value ?? const [];
    final enrolled = ref.watch(enrolledJourneysProvider).value ?? const [];
    final journeysAsync = ref.watch(journeySummariesProvider);

    final enrolledSlugs = {for (final j in enrolled) j.slug};

    return Scaffold(
      appBar: AppBar(
        title: const Text('مسار ابن عثيمين'),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          if (continueWatching.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: SectionHeader(title: 'متابعة المشاهدة'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                itemCount: continueWatching.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = continueWatching[index];
                  final remaining = item.durationSeconds == null
                      ? null
                      : Duration(
                          seconds: (item.durationSeconds! - item.watchedSeconds)
                              .clamp(0, 1 << 31),
                        );
                  return ResumeCard(
                    lessonTitle: item.titleAr,
                    seriesTitle: item.seriesTitleAr,
                    videoId: item.videoId,
                    progress: item.progress,
                    remaining: remaining,
                    onTap: () => context.push(
                      '/player/${item.videoId}?series=${item.seriesSlug}',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
          if (enrolled.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: SectionHeader(title: 'مساراتي'),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final journey in enrolled)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.lg,
                  end: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                child: JourneyCard(
                  title: journey.titleAr,
                  description: journey.descriptionAr,
                  level: journey.level,
                  stageCount: journey.stageCount,
                  lessonCount: journey.lessonCount,
                  progress: journey.progress,
                  coverUrl: journey.coverUrl,
                  onTap: () => context.push('/journey/${journey.slug}'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: SectionHeader(
              title: enrolled.isEmpty ? 'ابدأ رحلتك' : 'مسارات أخرى',
              onSeeAll: () => context.go('/journeys'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          journeysAsync.when(
            loading: () => const Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Skeleton(height: 160, width: double.infinity),
                  SizedBox(height: AppSpacing.md),
                  Skeleton(height: 160, width: double.infinity),
                ],
              ),
            ),
            error: (error, stack) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'تعذر تحميل المسارات',
              message: 'حدث خطأ غير متوقع. أعد فتح التطبيق.',
            ),
            data: (journeys) {
              final suggestions = journeys
                  .where((j) => !enrolledSlugs.contains(j.slug))
                  .take(3)
                  .toList();
              if (journeys.isEmpty) {
                return const EmptyState(
                  icon: Icons.route_rounded,
                  title: 'لا مسارات بعد',
                  message: 'سيصلك المحتوى فور توفره.',
                );
              }
              return Column(
                children: [
                  for (final journey in suggestions)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.lg,
                        end: AppSpacing.lg,
                        bottom: AppSpacing.md,
                      ),
                      child: JourneyCard(
                        title: journey.titleAr,
                        description: journey.descriptionAr,
                        level: journey.level,
                        stageCount: journey.stageCount,
                        lessonCount: journey.lessonCount,
                        coverUrl: journey.coverUrl,
                        onTap: () => context.push('/journey/${journey.slug}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
