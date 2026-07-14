import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

enum BackCircleStyle { surface, onHero }

/// Circular back button. RTL: the chevron points "forward" (left) natively
/// because the SVG in the design is a left-pointing chevron in RTL flow.
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
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: onHero ? masar.onHero : masar.chipText,
          ),
        ),
      ),
    );
  }
}
