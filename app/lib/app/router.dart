import 'package:go_router/go_router.dart';

import '../features/gallery/gallery_screen.dart';

/// Route table. M3 replaces the temporary gallery root with the real
/// three-tab shell (الرئيسية / المسارات / المكتبة); /gallery stays as a dev tool.
final router = GoRouter(
  initialLocation: '/gallery',
  routes: [
    GoRoute(
      path: '/gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
  ],
);
