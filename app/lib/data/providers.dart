import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart'
    show ErrorDescription, FlutterError, FlutterErrorDetails, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/theme_mode_provider.dart';
import 'catalog_repository.dart';
import 'db/database.dart';
import 'download_manager.dart';
import 'download_repository.dart';
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

/// Where offline audio lives. Overridden in tests with a temp directory so
/// they never write into the real app-support folder.
final downloadsDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => DownloadRepository.defaultDirectory,
);

final downloadRepositoryProvider = Provider<DownloadRepository>(
  (ref) => DownloadRepository(
    ref.watch(databaseProvider),
    directory: ref.watch(downloadsDirectoryProvider),
  ),
);

/// Overridden in tests, which must not touch the platform connectivity plugin.
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

/// True when downloading is permitted right now: always on Wi-Fi (or ethernet),
/// on mobile data only if the user allowed it.
final downloadAllowedProvider = Provider<NetworkCheck>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return () async {
    if (ref.read(allowMobileDataProvider)) return true;
    final results = await connectivity.checkConnectivity();
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          // The desktop dev preview reports `other`; blocking it there would
          // make downloads untestable off a phone.
          r == ConnectivityResult.other,
    );
  };
});

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  return DownloadManager(
    repository: ref.watch(downloadRepositoryProvider),
    allowedOnCurrentNetwork: ref.watch(downloadAllowedProvider),
  );
});

/// Every download's state, keyed by lesson id — watched by the lesson rows,
/// the series screen, and the downloads settings page.
final downloadsProvider = StreamProvider<Map<String, DownloadStatus>>(
  (ref) => ref.watch(downloadRepositoryProvider).watchAll(),
);

/// Which content snapshot this device is on. Worth reporting with a bug: a
/// «wrong info» report is about a specific catalog, and content is corrected by
/// republishing it.
final catalogVersionProvider = FutureProvider<int>(
  (ref) => ref.watch(catalogRepositoryProvider).currentVersion(),
);

/// Resolves once the bundled catalog has been imported (first run) or a
/// catalog is already present. Screens gate on this before querying.
///
/// Failures are logged on the way past. Riverpod turns them into an
/// `AsyncError` that the shell renders as an error screen, which means they
/// never reach `runZonedGuarded` in main.dart — so without this, the one
/// failure that can make the app unusable is also the one failure that leaves
/// no trace in `crash.log` for a tester to send back.
final catalogReadyProvider = FutureProvider<void>((ref) async {
  try {
    await ref.watch(catalogRepositoryProvider).ensureLoaded();
  } catch (error, stack) {
    debugPrint('catalog could not be prepared: $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'masar',
        context: ErrorDescription('preparing the catalog on startup'),
      ),
    );
    rethrow;
  }
});
