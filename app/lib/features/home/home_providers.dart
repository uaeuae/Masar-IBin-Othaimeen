import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/view_models.dart';

final continueWatchingProvider =
    StreamProvider.autoDispose<List<ContinueWatchingItem>>(
      (ref) => ref.watch(catalogRepositoryProvider).watchContinueWatching(),
    );

final enrolledJourneysProvider =
    StreamProvider.autoDispose<List<JourneySummary>>(
      (ref) => ref.watch(catalogRepositoryProvider).watchEnrolledJourneys(),
    );
