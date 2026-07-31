import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/view_models.dart';

final sciencesProvider = StreamProvider.autoDispose<List<ScienceSummary>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchSciences(),
);

final seriesByScienceProvider = StreamProvider.autoDispose
    .family<List<SeriesWithProgress>, String>(
      (ref, scienceSlug) => ref
          .watch(catalogRepositoryProvider)
          .watchSeriesByScience(scienceSlug),
    );

/// Scholar registry — attribution for the «عن الكتاب» card and the home
/// resume card.
final scholarsProvider = StreamProvider.autoDispose<List<ScholarInfo>>(
  (ref) => ref.watch(catalogRepositoryProvider).watchScholars(),
);
