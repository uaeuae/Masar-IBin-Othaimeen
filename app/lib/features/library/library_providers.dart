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

/// The scholars a filter chip can be built for: those who actually have
/// series.
///
/// A `coming_soon` scholar is omitted rather than shown disabled. He has no
/// content by definition, so his chip could only ever empty the screen — a
/// filter is a way to narrow what you can see, and a control that never
/// narrows anything is a dead end dressed as a choice. He is still announced,
/// in the place built for announcing him: his badged card in the الشيوخ row.
final filterableScholarsProvider = Provider.autoDispose<List<ScholarInfo>>((
  ref,
) {
  final scholars = ref.watch(scholarsProvider).value ?? const <ScholarInfo>[];
  return [
    for (final s in scholars)
      if (s.seriesCount > 0) s,
  ];
});

/// The selected scholar, or null for «كل الشيوخ» (design 3a, 4e).
///
/// One filter for the whole browse surface — the library grid, a science's
/// series list and search all read it — so that narrowing to a scholar stays
/// narrowed as you move between them instead of silently resetting. Every
/// screen that honours it also shows it, with a way to clear it.
class ScholarFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? slug) => state = slug;
}

final scholarFilterProvider = NotifierProvider<ScholarFilterNotifier, String?>(
  ScholarFilterNotifier.new,
);

/// Whether browsing by scholar is worth offering at all.
///
/// The trigger is more than one scholar *with series*, not more than one
/// scholar: filtering across a single body of content is noise, and an
/// announced scholar adds a name without adding anything to filter.
final scholarFilterVisibleProvider = Provider.autoDispose<bool>(
  (ref) => ref.watch(filterableScholarsProvider).length > 1,
);

/// The filter as screens should *apply* it, as opposed to the raw selection.
///
/// A new catalog can land while the app runs, so a selection can outlive the
/// chip row that set it. Resolving it against what is currently filterable
/// means a filter is never in force while invisible.
final activeScholarFilterProvider = Provider.autoDispose<String?>((ref) {
  final slug = ref.watch(scholarFilterProvider);
  if (slug == null || !ref.watch(scholarFilterVisibleProvider)) return null;
  final filterable = ref.watch(filterableScholarsProvider);
  return filterable.any((s) => s.slug == slug) ? slug : null;
});

/// The sciences grid, narrowed to the selected scholar.
///
/// Unfiltered, an empty علم stays on the grid as a promise («قريبًا»). Under a
/// scholar filter it is not a promise — the علم may be full, just not of his
/// lessons — so it drops out rather than lie.
final filteredSciencesProvider =
    StreamProvider.autoDispose<List<ScienceSummary>>((ref) {
      final scholar = ref.watch(activeScholarFilterProvider);
      final sciences = ref
          .watch(catalogRepositoryProvider)
          .watchSciences(scholarSlug: scholar);
      if (scholar == null) return sciences;
      return sciences.map(
        (all) => [
          for (final s in all)
            if (s.seriesCount > 0) s,
        ],
      );
    });
