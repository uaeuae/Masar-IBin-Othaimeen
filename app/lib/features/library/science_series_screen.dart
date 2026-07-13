import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/series_tile.dart';
import '../../core/widgets/skeleton.dart';
import 'library_providers.dart';

class ScienceSeriesScreen extends ConsumerWidget {
  const ScienceSeriesScreen({super.key, required this.scienceSlug});

  final String scienceSlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesByScienceProvider(scienceSlug));
    final sciences = ref.watch(sciencesProvider).value ?? const [];
    final science = sciences.where((s) => s.slug == scienceSlug).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(science?.nameAr ?? '')),
      body: seriesAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            Skeleton(height: 90, width: double.infinity),
            SizedBox(height: AppSpacing.md),
            Skeleton(height: 90, width: double.infinity),
          ],
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل السلاسل',
        ),
        data: (series) {
          if (series.isEmpty) {
            return const EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'لا سلاسل في هذا العلم بعد',
              message: 'سيضاف المحتوى تباعًا بإذن الله.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: series.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final s = series[index];
              return SeriesTile(
                title: s.titleAr,
                lessonCount: s.lessonCount,
                completedCount: s.completedCount,
                totalDuration: Duration(seconds: s.totalDurationSeconds),
                onTap: () => context.push('/series/${s.slug}'),
              );
            },
          );
        },
      ),
    );
  }
}
