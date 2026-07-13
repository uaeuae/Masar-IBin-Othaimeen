import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/enums.dart';
import '../library/library_providers.dart';
import 'journeys_providers.dart';

class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeysAsync = ref.watch(journeySummariesProvider);
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final levelFilter = ref.watch(levelFilterProvider);
    final scienceFilter = ref.watch(scienceFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المسارات التعليمية')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Row(
              children: [
                for (final level in [null, ...JourneyLevel.values]) ...[
                  FilterChip(
                    label: Text(level?.labelAr ?? 'الكل'),
                    selected: levelFilter == level,
                    showCheckmark: false,
                    onSelected: (_) =>
                        ref.read(levelFilterProvider.notifier).set(level),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
          if (sciences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('كل العلوم'),
                      selected: scienceFilter == null,
                      showCheckmark: false,
                      onSelected: (_) =>
                          ref.read(scienceFilterProvider.notifier).set(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    for (final science in sciences) ...[
                      FilterChip(
                        label: Text(science.nameAr),
                        selected: scienceFilter == science.slug,
                        showCheckmark: false,
                        onSelected: (_) => ref
                            .read(scienceFilterProvider.notifier)
                            .set(science.slug),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: journeysAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: const [
                  Skeleton(height: 180, width: double.infinity),
                  SizedBox(height: AppSpacing.md),
                  Skeleton(height: 180, width: double.infinity),
                ],
              ),
              error: (error, stack) => const EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر تحميل المسارات',
              ),
              data: (journeys) {
                final filtered = journeys
                    .where((j) => levelFilter == null || j.level == levelFilter)
                    .where(
                      (j) =>
                          scienceFilter == null ||
                          j.scienceSlug == scienceFilter,
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'لا مسارات تطابق التصفية',
                    message: 'جرّب تغيير المستوى أو العلم.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final journey = filtered[index];
                    return JourneyCard(
                      title: journey.titleAr,
                      description: journey.descriptionAr,
                      level: journey.level,
                      stageCount: journey.stageCount,
                      lessonCount: journey.lessonCount,
                      progress: journey.enrolled ? journey.progress : null,
                      coverUrl: journey.coverUrl,
                      onTap: () => context.push('/journey/${journey.slug}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
