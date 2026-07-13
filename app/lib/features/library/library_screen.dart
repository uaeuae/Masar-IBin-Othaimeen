import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/formatters.dart';
import '../../core/science_icons.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton.dart';
import 'library_providers.dart';

/// المكتبة: browse everything by science — the non-curated escape hatch.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sciencesAsync = ref.watch(sciencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المكتبة')),
      body: sciencesAsync.when(
        loading: () => GridView.count(
          padding: const EdgeInsets.all(AppSpacing.lg),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: const [Skeleton(), Skeleton(), Skeleton(), Skeleton()],
        ),
        error: (error, stack) => const EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تحميل المكتبة',
        ),
        data: (sciences) => GridView.count(
          padding: const EdgeInsets.all(AppSpacing.lg),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.4,
          children: [
            for (final science in sciences)
              Card(
                child: InkWell(
                  onTap: science.seriesCount == 0
                      ? null
                      : () => context.push('/science/${science.slug}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.tile),
                          ),
                          child: Icon(
                            scienceIcon(science.icon),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          science.nameAr,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          seriesCountLabel(science.seriesCount),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
