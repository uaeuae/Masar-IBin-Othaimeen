import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/widgets/back_circle.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/level_badge.dart';
import '../../core/widgets/masar_chip.dart';
import '../../core/widgets/science_glyph.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/view_models.dart';
import 'library_providers.dart';

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
          data: (series) {
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            science.nameAr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            '${seriesCountLabel(series.length)} · ${lessonCountLabel(totalLessons)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    MasarChip(
                      label: 'الأحدث',
                      selected: sort == _SeriesSort.newest,
                      onTap: () => ref
                          .read(_sortProvider.notifier)
                          .set(_SeriesSort.newest),
                    ),
                    const SizedBox(width: 8),
                    MasarChip(
                      label: 'الأقصر أولًا',
                      selected: sort == _SeriesSort.shortest,
                      onTap: () => ref
                          .read(_sortProvider.notifier)
                          .set(_SeriesSort.shortest),
                    ),
                    const SizedBox(width: 8),
                    MasarChip(
                      label: 'أبجديًا',
                      selected: sort == _SeriesSort.alphabetical,
                      onTap: () => ref
                          .read(_sortProvider.notifier)
                          .set(_SeriesSort.alphabetical),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (sorted.isEmpty)
                  const EmptyState(
                    icon: Icons.auto_stories_rounded,
                    title: 'لا سلاسل في هذا العلم بعد',
                    message: 'سيضاف المحتوى تباعًا بإذن الله.',
                  )
                else
                  for (final s in sorted) ...[
                    _SeriesCard(series: s),
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

/// White card: Amiri title + level badge, "X حلقة · Y ساعة", progress if started.
class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series});

  final SeriesWithProgress series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: InkWell(
        onTap: () => context.push('/series/${series.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      series.titleAr,
                      style: serif(19, scheme.onSurface),
                    ),
                  ),
                  if (series.level != null) ...[
                    const SizedBox(width: 10),
                    LevelBadge(level: series.level!, compact: true),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  episodeCountLabel(series.lessonCount),
                  if (series.totalDurationSeconds > 0)
                    durationLabel(
                      Duration(seconds: series.totalDurationSeconds),
                    ),
                ].join(' · '),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (series.started) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        child: LinearProgressIndicator(
                          value: series.progress,
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${arabicDigits(series.completedCount)} / ${arabicDigits(series.lessonCount)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
