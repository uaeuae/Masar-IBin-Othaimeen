import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

enum BackCircleStyle { surface, onHero }

/// Circular back button. Uses the semantic "back" icon: Flutter auto-mirrors
/// it (matchTextDirection), so in RTL it renders pointing right — toward
/// where the user came from.
class BackCircle extends StatelessWidget {
  const BackCircle({
    super.key,
    this.style = BackCircleStyle.surface,
    this.onTap,
  });

  final BackCircleStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final onHero = style == BackCircleStyle.onHero;

    return Semantics(
      button: true,
      label: 'رجوع',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => context.pop(),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: onHero ? const Color(0x24FFFFFF) : masar.chipBg,
            shape: BoxShape.circle,
            border: onHero ? null : Border.all(color: masar.chipBorder),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 13,
            color: onHero ? masar.onHero : masar.chipText,
          ),
        ),
      ),
    );
  }
}
