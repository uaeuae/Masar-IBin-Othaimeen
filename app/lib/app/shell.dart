import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/empty_state.dart';
import '../data/providers.dart';

/// Three-tab shell (الرئيسية / المسارات / المكتبة). Gates all content on the
/// catalog being imported — first run imports the bundled snapshot, so this
/// resolves fast and fully offline.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogReady = ref.watch(catalogReadyProvider);

    return Scaffold(
      body: catalogReady.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تجهيز المحتوى',
          message: 'حدث خطأ أثناء تحميل قاعدة الدروس.',
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.invalidate(catalogReadyProvider),
        ),
        data: (_) => navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route_rounded),
            label: 'المسارات',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_library_outlined),
            selectedIcon: Icon(Icons.local_library_rounded),
            label: 'المكتبة',
          ),
        ],
      ),
    );
  }
}
