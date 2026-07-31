import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/science_glyph.dart';
import '../../core/widgets/series_card.dart';
import '../../core/widgets/skeleton.dart';
import '../scholars/scholar_providers.dart';
import 'library_providers.dart';
import 'scholar_filter.dart';

enum _SeriesSort { newest, shortest, alphabetical }

class _SortNotifier extends Notifier<_SeriesSort> {
  @override
  _SeriesSort build() => _SeriesSort.newest;

  void set(_SeriesSort value) => state = value;
}

final _sortProvider = NotifierProvider.autoDispose<_SortNotifier, _SeriesSort>(
  _SortNotifier.new,
);

class ScienceSeriesScreen extends ConsumerWidget {
  const ScienceSeriesScreen({super.key, required this.scienceSlug});

  final String scienceSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final seriesAsync = ref.watch(seriesByScienceProvider(scienceSlug));
    final scholarFilter = ref.watch(activeScholarFilterProvider);
    final scholars = ref.watch(scholarsBySlugProvider);
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final science = sciences.where((s) => s.slug == scienceSlug).firstOrNull;
    final sort = ref.watch(_sortProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: seriesAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const [Skeleton(height: 200, width: double.infinity)],
          ),
          error: (error, stack) => const EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'تعذر تحميل السلاسل',
          ),
          data: (all) {
            // The library tile that leads here counts only the filtered
            // scholar's series; arriving at the unfiltered list would make
            // that count look wrong.
            final series = scholarFilter == null
                ? all
                : [
                    for (final s in all)
                      if (s.scholarSlug == scholarFilter) s,
                  ];
            final sorted = [...series];
            switch (sort) {
              case _SeriesSort.newest:
                break; // catalog order
              case _SeriesSort.shortest:
                sorted.sort(
                  (a, b) =>
                      a.totalDurationSeconds.compareTo(b.totalDurationSeconds),
                );
              case _SeriesSort.alphabetical:
                sorted.sort((a, b) => a.titleAr.compareTo(b.titleAr));
            }
            final totalLessons = series.fold(
              0,
              (sum, s) => sum + s.lessonCount,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    const BackCircle(),
                    const SizedBox(width: 12),
                    if (science != null) ...[
                      ScienceGlyph(
                        nameAr: science.nameAr,
                        sortOrder: science.sortOrder,
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      // Flexible, or the counts line runs past the edge once
                      // the reader turns text up — «٣ سلاسل · ٢٤ درسًا» is
                      // wider than what is left beside the glyph.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              science.nameAr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              '${seriesCountLabel(series.length)} · ${lessonCountLabel(totalLessons)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (scholarFilter != null) ...[
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ActiveScholarFilterChip(),
                  ),
                  const SizedBox(height: 12),
                ],
                // Scrolls rather than wraps: the three labels need ~392pt and a
                // 402pt phone leaves 362, so as a plain Row this overflowed by
                // 30 — and it gets worse at larger text sizes. Same treatment
                // as the science and scholar filter rows.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      MasarChip(
                        label: 'الأحدث',
                        dense: true,
                        selected: sort == _SeriesSort.newest,
                        onTap: () => ref
                            .read(_sortProvider.notifier)
                            .set(_SeriesSort.newest),
                      ),
                      const SizedBox(width: 8),
                      MasarChip(
                        label: 'الأقصر أولًا',
                        dense: true,
                        selected: sort == _SeriesSort.shortest,
                        onTap: () => ref
                            .read(_sortProvider.notifier)
                            .set(_SeriesSort.shortest),
                      ),
                      const SizedBox(width: 8),
                      MasarChip(
                        label: 'أبجديًا',
                        dense: true,
                        selected: sort == _SeriesSort.alphabetical,
                        onTap: () => ref
                            .read(_sortProvider.notifier)
                            .set(_SeriesSort.alphabetical),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (sorted.isEmpty)
                  scholarFilter == null
                      ? const EmptyState(
                          icon: Icons.auto_stories_rounded,
                          title: 'لا سلاسل في هذا العلم بعد',
                          message: 'سيضاف المحتوى تباعًا بإذن الله.',
                        )
                      : const EmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'لا سلاسل تطابق التصفية',
                          message: 'أزل تصفية الشيخ لعرض سلاسل هذا العلم.',
                        )
                else
                  for (final s in sorted) ...[
                    SeriesCard(series: s, scholar: scholars[s.scholarSlug]),
                    if (s != sorted.last) const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
