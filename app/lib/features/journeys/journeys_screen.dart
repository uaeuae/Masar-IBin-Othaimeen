import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/skeleton.dart';
import '../library/library_providers.dart';
import '../library/scholar_filter.dart';
import '../scholars/scholar_providers.dart';
import 'journeys_providers.dart';

class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journeysAsync = ref.watch(journeySummariesProvider);
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final scholars = ref.watch(scholarsBySlugProvider);
    final scienceFilter = ref.watch(scienceFilterProvider);
    final scholarFilter = ref.watch(activeScholarFilterProvider);

    String scienceName(String? slug) =>
        sciences
            .where((s) => s.slug == slug)
            .map((s) => s.nameAr)
            .firstOrNull ??
        '';
    int scienceOrder(String? slug) =>
        sciences
            .where((s) => s.slug == slug)
            .map((s) => s.sortOrder)
            .firstOrNull ??
        1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المسارات', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        MasarChip(
                          label: 'الكل',
                          selected: scienceFilter == null,
                          onTap: () => ref
                              .read(scienceFilterProvider.notifier)
                              .set(null),
                        ),
                        for (final science in sciences) ...[
                          const SizedBox(width: 8),
                          MasarChip(
                            label: science.nameAr,
                            selected: scienceFilter == science.slug,
                            onTap: () => ref
                                .read(scienceFilterProvider.notifier)
                                .set(science.slug),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Two مسارات share the title «مسار العقيدة», one per scholar —
            // filtering by شيخ is what tells the list apart.
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 20, end: 20),
              child: ScholarFilterChips(),
            ),
            Expanded(
              child: journeysAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: const [
                    Skeleton(height: 140, width: double.infinity),
                    SizedBox(height: 12),
                    Skeleton(height: 140, width: double.infinity),
                  ],
                ),
                error: (error, stack) => const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحميل المسارات',
                ),
                data: (journeys) {
                  // No level filter: with four journeys, hiding three of them
                  // behind a segmented control cost more than it saved. The
                  // level is a tag on each card instead.
                  final filtered = journeys
                      .where(
                        (j) =>
                            scienceFilter == null ||
                            j.scienceSlug == scienceFilter,
                      )
                      .where(
                        (j) =>
                            scholarFilter == null ||
                            j.scholarSlugs.contains(scholarFilter),
                      )
                      .toList();
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'لا مسارات تطابق التصفية',
                      message: scholarFilter == null
                          ? 'جرّب اختيار علم آخر.'
                          : 'جرّب علمًا آخر، أو أزل تصفية الشيخ.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final journey = filtered[index];
                      return JourneyCard(
                        title: journey.titleAr,
                        level: journey.level,
                        stageCount: journey.stageCount,
                        totalDurationSeconds: journey.totalDurationSeconds,
                        scienceName: scienceName(journey.scienceSlug),
                        scienceSortOrder: scienceOrder(journey.scienceSlug),
                        seriesPreview: journey.seriesPreview,
                        scholars: [
                          for (final slug in journey.scholarSlugs)
                            if (scholars[slug] != null) scholars[slug]!,
                        ],
                        enrolled: journey.enrolled,
                        progress: journey.enrolled ? journey.progress : null,
                        onTap: () => context.push('/journey/${journey.slug}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
