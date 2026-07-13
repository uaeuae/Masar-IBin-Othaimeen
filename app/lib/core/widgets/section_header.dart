import 'package:flutter/material.dart';

/// Home-style section heading with an optional "عرض الكل" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('عرض الكل')),
      ],
    );
  }
}
