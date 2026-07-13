import 'package:flutter/material.dart';

/// Maps the catalog's `icon` slug to a Material icon.
IconData scienceIcon(String? slug) => switch (slug) {
  'mosque' => Icons.mosque_rounded,
  'scale' => Icons.balance_rounded,
  'book' => Icons.menu_book_rounded,
  'quran' => Icons.auto_stories_rounded,
  'foundation' => Icons.foundation_rounded,
  'heart' => Icons.favorite_rounded,
  _ => Icons.school_rounded,
};
