import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Rounded box with the science's Amiri initial (ع، ف، ح، ت…), as in the
/// design. Core sciences (sort_order <= 3) are green-tinted, the rest gold.
class ScienceGlyph extends StatelessWidget {
  const ScienceGlyph({
    super.key,
    required this.nameAr,
    this.sortOrder = 1,
    this.size = 38,
  });

  final String nameAr;
  final int sortOrder;
  final double size;

  /// "العقيدة" → "ع", "أصول الفقه" → "أ".
  static String initialOf(String nameAr) {
    var text = nameAr.trim();
    if (text.startsWith('ال') && text.length > 2) text = text.substring(2);
    return text.isEmpty ? '؟' : text[0];
  }

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final green = sortOrder <= 3;
    final bg = green ? scheme.primaryContainer : masar.goldTintBg;
    final fg = green ? scheme.onPrimaryContainer : masar.goldTintFg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      alignment: Alignment.center,
      child: Text(initialOf(nameAr), style: serif(size * 0.5, fg, height: 1)),
    );
  }
}
