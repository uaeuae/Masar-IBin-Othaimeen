import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Filter pill — selected: solid green (mint in dark); unselected: bordered.
class MasarChip extends StatelessWidget {
  const MasarChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 7,
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
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? scheme.onPrimary : masar.chipText,
          ),
        ),
      ),
    );
  }
}
