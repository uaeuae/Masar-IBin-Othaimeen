import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/journey_card.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/segmented_control.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/models/enums.dart';
import '../library/library_providers.dart';
import 'journeys_providers.dart';

class JourneysScreen extends ConsumerWidget {
  const JourneysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journeysAsync = ref.watch(journeySummariesProvider);
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final level = ref.watch(levelFilterProvider);
    final scienceFilter = ref.watch(scienceFilterProvider);

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
                  const SizedBox(height: 12),
                  SegmentedControl<JourneyLevel>(
                    segments: {
                      for (final l in JourneyLevel.values) l: l.labelAr,
                    },
                    selected: level,
                    onChanged: (l) =>
                        ref.read(levelFilterProvider.notifier).set(l),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
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
                  final filtered = journeys
                      .where((j) => j.level == level)
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
                        scienceName: scienceName(journey.scienceSlug),
                        scienceSortOrder: scienceOrder(journey.scienceSlug),
                        seriesPreview: journey.seriesPreview,
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
