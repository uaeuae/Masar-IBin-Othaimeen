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

/// The user's level (مبتدئ default) — the design's "level chips replace
/// onboarding". Persisted; drives home suggestions AND the journeys filter.
class LevelFilterNotifier extends Notifier<JourneyLevel> {
  static const _key = 'preferred_level';

  @override
  JourneyLevel build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_key);
    return JourneyLevel.values.asNameMap()[stored] ?? JourneyLevel.beginner;
  }

  void set(JourneyLevel level) {
    state = level;
    ref.read(sharedPreferencesProvider).setString(_key, level.name);
  }
}

final levelFilterProvider = NotifierProvider<LevelFilterNotifier, JourneyLevel>(
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
