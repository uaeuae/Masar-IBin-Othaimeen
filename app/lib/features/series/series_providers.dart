import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/view_models.dart';

final seriesDetailProvider = StreamProvider.autoDispose
    .family<SeriesDetail?, String>(
      (ref, slug) =>
          ref.watch(catalogRepositoryProvider).watchSeriesDetail(slug),
    );
