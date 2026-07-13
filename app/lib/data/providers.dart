import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_repository.dart';
import 'db/database.dart';
import 'progress_repository.dart';

/// Overridden in main() with the loaded instance (and in tests with a mock).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

/// Overridden in tests with an in-memory executor.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'masar'));
  ref.onDispose(db.close);
  return db;
});

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(databaseProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(databaseProvider)),
);

/// Resolves once the bundled catalog has been imported (first run) or a
/// catalog is already present. Screens gate on this before querying.
final catalogReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(catalogRepositoryProvider).ensureLoaded(),
);
