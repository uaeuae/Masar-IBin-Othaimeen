import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Filter pill — selected: solid green (mint in dark); unselected: bordered.
class MasarChip extends StatelessWidget {
  const MasarChip({
    super.key,
    required this.label,
    required this.selected,
    this.dense = false,
    this.onTap,
  });

  final String label;
  final bool selected;

  /// Sort-chip size on the science series list (design 1i: 12.5px, 14/6).
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: dense ? 14 : 16,
          vertical: dense ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : masar.chipBg,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: selected ? null : Border.all(color: masar.chipBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kUiFont,
            fontSize: dense ? 12.5 : 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onPrimary : masar.chipText,
          ),
        ),
      ),
    );
  }
}
