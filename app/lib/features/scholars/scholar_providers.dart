import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/view_models.dart';
import '../library/library_providers.dart';

/// Scholars keyed by slug. Cards carry a `scholarSlug`, not a whole record, so
/// every attributed row resolves through this one stream rather than issuing a
/// query per card.
final scholarsBySlugProvider = Provider.autoDispose<Map<String, ScholarInfo>>((
  ref,
) {
  final scholars = ref.watch(scholarsProvider).value ?? const <ScholarInfo>[];
  return {for (final scholar in scholars) scholar.slug: scholar};
});

final scholarProvider = Provider.autoDispose.family<ScholarInfo?, String>(
  (ref, slug) => ref.watch(scholarsBySlugProvider)[slug],
);

final scholarStatsProvider = StreamProvider.autoDispose
    .family<ScholarStats, String>(
      (ref, slug) => ref.watch(catalogRepositoryProvider).watchScholarStats(slug),
    );

final seriesByScholarProvider = StreamProvider.autoDispose
    .family<List<SeriesWithProgress>, String>(
      (ref, slug) =>
          ref.watch(catalogRepositoryProvider).watchSeriesByScholar(slug),
    );
