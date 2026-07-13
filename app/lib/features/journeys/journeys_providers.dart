import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/view_models.dart';

final journeySummariesProvider =
    StreamProvider.autoDispose<List<JourneySummary>>(
      (ref) => ref.watch(catalogRepositoryProvider).watchJourneySummaries(),
    );

final journeyDetailProvider = StreamProvider.autoDispose
    .family<JourneyDetail?, String>(
      (ref, slug) =>
          ref.watch(catalogRepositoryProvider).watchJourneyDetail(slug),
    );

/// Filters on the المسارات tab. Not auto-disposed so they survive tab switches.
class LevelFilterNotifier extends Notifier<JourneyLevel?> {
  @override
  JourneyLevel? build() => null;

  void set(JourneyLevel? level) => state = level;
}

final levelFilterProvider =
    NotifierProvider<LevelFilterNotifier, JourneyLevel?>(
      LevelFilterNotifier.new,
    );

class ScienceFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? slug) => state = slug;
}

final scienceFilterProvider = NotifierProvider<ScienceFilterNotifier, String?>(
  ScienceFilterNotifier.new,
);
