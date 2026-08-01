import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/enums.dart';
import '../../data/view_models.dart';

/// The scholar roundel from the design's multi-sheikh sheets (3a, 3b, 4b): a
/// gradient circle carrying one Amiri letter.
///
/// It exists so a lesson reads as *someone's* — the app carries several
/// scholars' teaching, and an unattributed card silently implies there is only
/// one. The letter is curated in `seed/scholars.yaml` rather than taken from
/// the name, because it comes from the شهرة: العثيمين gives ع, ابن باز gives ب,
/// while `nameAr[0]` would print ا for both.
class ScholarAvatar extends StatelessWidget {
  const ScholarAvatar({
    super.key,
    required this.initialAr,
    required this.accent,
    this.size = 22,
    this.onHero = false,
  });

  ScholarAvatar.of(ScholarInfo scholar, {super.key, this.size = 22, this.onHero = false})
    : initialAr = scholar.initialAr,
      accent = scholar.accent;

  final String initialAr;
  final ScholarAccent accent;
  final double size;

  /// On the green hero surfaces the gradient has no contrast left, so the
  /// design switches to a translucent cream disc (4a's resume card, 4b's
  /// header) instead of the accent.
  final bool onHero;

  @override
  Widget build(BuildContext context) {
    final masar = masarColorsOf(context);
    final colors = MasarColors.scholarAccents[accent]!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onHero ? masar.onHero.withAlpha(0x2E) : null,
        gradient: onHero
            ? null
            : LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: colors,
              ),
        border: onHero
            ? Border.all(color: masar.onHero.withAlpha(0x59))
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initialAr,
        textAlign: TextAlign.center,
        style: serif(
          // The design keeps the letter at just under half the disc at every
          // size it draws (46→20, 52→22, 84→32).
          size * 0.44,
          masar.onHero,
          height: 1,
        ),
      ),
    );
  }
}

/// Roundel + name, the attribution row the design puts under a series title
/// (3b) and beside the resume card's lesson line (4a).
class ScholarLine extends StatelessWidget {
  const ScholarLine({
    super.key,
    required this.scholar,
    this.trailing,
    this.avatarSize = 22,
    this.onHero = false,
    this.withHonorific = true,
    this.useShortName = false,
  });

  final ScholarInfo scholar;

  /// Appended after the name, as in «ابن عثيمين · الدرس ١٢».
  final String? trailing;
  final double avatarSize;
  final bool onHero;
  final bool withHonorific;

  /// Use the curated شهرة. For lines that carry something *else* too — a
  /// lesson title, a chip — where the full name would push it off the edge.
  final bool useShortName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masar = masarColorsOf(context);
    final name = useShortName
        ? scholar.displayShortName
        : withHonorific
        ? scholar.nameWithHonorific
        : scholar.nameAr;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScholarAvatar.of(scholar, size: avatarSize, onHero: onHero),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            trailing == null ? name : '$name · $trailing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: onHero ? masar.onHeroDim : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlapping roundels for a مسار whose stages come from different scholars
/// (design 4c). Overlapped rather than spaced so the group reads as one fact
/// about the journey rather than a list.
class StackedScholarAvatars extends StatelessWidget {
  const StackedScholarAvatars({super.key, required this.scholars, this.size = 20});

  final List<ScholarInfo> scholars;

  final double size;
  static const double _overlap = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size + (scholars.length - 1) * (size - _overlap),
      height: size,
      child: Stack(
        children: [
          for (final (index, scholar) in scholars.indexed)
            PositionedDirectional(
              start: index * (size - _overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.surface, width: 1.5),
                ),
                child: ScholarAvatar.of(scholar, size: size),
              ),
            ),
        ],
      ),
    );
  }
}
