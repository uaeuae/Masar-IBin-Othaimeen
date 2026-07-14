import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Custom bottom bar per the design: translucent surface, hairline top
/// border, tinted active icon + bold 11px label, no indicator pill.
class MasarNavBar extends StatelessWidget {
  const MasarNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    (
      icon: Icons.route_outlined,
      activeIcon: Icons.route_rounded,
      label: 'المسارات',
    ),
    (
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: 'المكتبة',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: masar.navBackground,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: EdgeInsetsDirectional.only(
        top: 10,
        bottom: 10 + bottomInset,
        start: 24,
        end: 24,
      ),
      child: Row(
        children: [
          for (final (index, item) in _items.indexed)
            Expanded(
              child: Semantics(
                selected: index == currentIndex,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        index == currentIndex ? item.activeIcon : item.icon,
                        size: 23,
                        color: index == currentIndex
                            ? scheme.primary
                            : masar.navInactive,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: kUiFont,
                          fontSize: 11,
                          fontWeight: index == currentIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: index == currentIndex
                              ? scheme.primary
                              : masar.navInactive,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
