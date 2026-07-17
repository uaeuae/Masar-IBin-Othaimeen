import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/empty_state.dart';
import '../core/widgets/masar_nav_bar.dart';
import '../data/providers.dart';
import 'theme.dart';

/// Three-tab shell (الرئيسية / المسارات / المكتبة). While the catalog imports
/// on first run, shows the designed splash — green gradient, the مسار roundel,
/// and the foundation attribution.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogReady = ref.watch(catalogReadyProvider);

    return catalogReady.when(
      loading: () => const _Splash(),
      error: (error, stack) => Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'تعذر تجهيز المحتوى',
          message: 'حدث خطأ أثناء تحميل قاعدة الدروس.',
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.invalidate(catalogReadyProvider),
        ),
      ),
      data: (_) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: MasarNavBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

/// The design's splash (1a): gradient, double gold ring around "مسار",
/// name + tagline, progress dots, attribution pinned near the bottom.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF3EFE0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF21624B), Color(0xFF17492F)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xA6D1B774),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x59D1B774)),
                      ),
                      alignment: Alignment.center,
                      child: Text('مسار', style: serif(44, cream, height: 1)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('مسار طالب العلم', style: serif(28, cream)),
                  const SizedBox(height: 8),
                  const Text(
                    'رحلة طالب العلم مع دروس الشيخ رحمه الله',
                    style: TextStyle(
                      fontFamily: kUiFont,
                      fontSize: 14,
                      color: Color(0xB3F3EFE0),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final alpha in const [0xE6, 0x73, 0x40]) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cream.withAlpha(alpha),
                          ),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 56,
              left: 40,
              right: 40,
              child: Text(
                'جميع الحقوق محفوظة لمؤسسة الشيخ محمد بن صالح العثيمين الخيرية\nتطبيق تطوعي غير ربحي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kUiFont,
                  fontSize: 11.5,
                  height: 1.7,
                  color: Color(0x8CF3EFE0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
