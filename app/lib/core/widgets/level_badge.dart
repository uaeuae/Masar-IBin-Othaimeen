import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';

/// Level pill: مبتدئ green-tint, متوسط olive, متقدم gold — per the design.
/// [onHero] renders the gold-outlined variant used on the green header.
class LevelBadge extends StatelessWidget {
  const LevelBadge({
    super.key,
    required this.level,
    this.onHero = false,
    this.compact = false,
  });

  final JourneyLevel level;
  final bool onHero;

  /// Series-card size (10.5px) vs default (11.5px).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final scheme = Theme.of(context).colorScheme;

    if (onHero) {
      return Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: const Color(0x33D1B774),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: const Color(0x66D1B774)),
        ),
        child: Text(
          level.labelAr,
          style: const TextStyle(
            fontFamily: kUiFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEBD9A8),
          ),
        ),
      );
    }

    final (bg, fg) = switch (level) {
      JourneyLevel.beginner => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      JourneyLevel.intermediate => (masar.oliveTintBg, masar.oliveTintFg),
      JourneyLevel.advanced => (masar.goldTintBg, masar.goldTintFg),
    };

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        level.labelAr,
        style: TextStyle(
          fontFamily: kUiFont,
          fontSize: compact ? 10.5 : 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
