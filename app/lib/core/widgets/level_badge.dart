import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';

/// Small pill showing a journey's difficulty level (مبتدئ / متوسط / متقدم).
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final JourneyLevel level;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<LevelColors>() ?? LevelColors.light;
    final (bg, fg) = switch (level) {
      JourneyLevel.beginner => (colors.beginnerBg, colors.beginnerFg),
      JourneyLevel.intermediate => (
        colors.intermediateBg,
        colors.intermediateFg,
      ),
      JourneyLevel.advanced => (colors.advancedBg, colors.advancedFg),
    };

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
      child: Text(
        level.labelAr,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
