import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/back_circle.dart';

/// Placeholder screen for designed-but-unbuilt features (المتون، ملاحظاتي).
/// Shows the feature's promise in the design's voice, plainly marked قريبًا.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen.matn({super.key})
    : icon = Icons.menu_book_outlined,
      title = 'المتون',
      message =
          'قراءة المتن بخط وقور مع فهرس الفصول، وبضغطة واحدة: '
          '«شاهد شرح هذا الموضع» ينقلك إلى موضعه من شرح الشيخ.';

  const ComingSoonScreen.notes({super.key})
    : icon = Icons.bookmark_border_rounded,
      title = 'ملاحظاتي',
      message =
          'ملاحظاتك وعلاماتك المرجعية على مواضع الدروس — '
          'تكتبها أثناء الاستماع وتعود إليها متى شئت.';

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final masar = masarColorsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [BackCircle()]),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(0x14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 38, color: scheme.primary),
                      ),
                      const SizedBox(height: 18),
                      Text(title, style: serif(26, scheme.onSurface)),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: masar.goldTintBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'قريبًا إن شاء الله',
                          style: TextStyle(
                            fontFamily: kUiFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: masar.goldTintFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
