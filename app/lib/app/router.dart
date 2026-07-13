import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/gallery/gallery_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journeys/journey_detail_screen.dart';
import '../features/journeys/journeys_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/science_series_screen.dart';
import '../features/player/player_screen.dart';
import '../features/series/series_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';

/// One router per ProviderScope — keeps navigation state test-isolated.
final routerProvider = Provider<GoRouter>((ref) {
  final router = _createRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter _createRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journeys',
              builder: (context, state) => const JourneysScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
      ],
    ),
    // Full-screen detail routes (no bottom bar).
    GoRoute(
      path: '/journey/:slug',
      builder: (context, state) =>
          JourneyDetailScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/series/:slug',
      builder: (context, state) =>
          SeriesDetailScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/science/:slug',
      builder: (context, state) =>
          ScienceSeriesScreen(scienceSlug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/player/:videoId',
      builder: (context, state) => PlayerScreen(
        videoId: state.pathParameters['videoId']!,
        seriesSlug: state.uri.queryParameters['series'],
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // Internal design-system gallery (dev tool).
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
  ],
);
