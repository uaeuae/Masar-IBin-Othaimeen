import 'package:flutter/material.dart';

/// Design tokens transcribed from the approved design file
/// (docs/design/masar-screens.dc.html). Direction: "serene classical" —
/// deep green on warm ivory, Amiri for classical titles, IBM Plex Sans
/// Arabic for UI. Dark theme sits on near-black green with a mint accent.

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double chip = 99;
  static const double segmented = 12;
  static const double banner = 14;
  static const double group = 16;
  static const double card = 18;
  static const double hero = 20;
}

/// UI font (all controls, body, labels).
const String kUiFont = 'IBMPlexSansArabic';

/// Classical serif — journey/series/lesson titles, the logo, attribution lead.
const String kSerifFont = 'Amiri';

/// Mono — LTR timestamps in the player and the version footer, per design.
const String kMonoFont = 'IBMPlexMono';

/// Amiri title helper. The design uses it at 44 (logo), 30 (page titles),
/// 21–22 (hero/lesson), 18–19 (cards).
TextStyle serif(
  double size,
  Color color, {
  FontWeight weight = FontWeight.w400,
  double height = 1.35,
}) {
  return TextStyle(
    fontFamily: kSerifFont,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
  );
}

/// Everything the standard ColorScheme can't carry, verbatim from the design.
@immutable
class MasarColors extends ThemeExtension<MasarColors> {
  const MasarColors({
    required this.heroGreen,
    required this.onHero,
    required this.onHeroDim,
    required this.onHeroFaint,
    required this.headerGradient,
    required this.gold,
    required this.goldTintBg,
    required this.goldTintFg,
    required this.oliveTintBg,
    required this.oliveTintFg,
    required this.greenTintBorder,
    required this.textMuted,
    required this.textFaint,
    required this.highlightRow,
    required this.highlightTrack,
    required this.navBackground,
    required this.navInactive,
    required this.timelineInactive,
    required this.upcomingCircle,
    required this.chipBg,
    required this.chipBorder,
    required this.chipText,
    required this.attributionBg,
    required this.attributionBorder,
    required this.attributionText,
    required this.heroShadow,
  });

  /// The brand green — stays #1E5B45 in BOTH themes (hero cards, headers).
  final Color heroGreen;
  final Color onHero; // cream #F3EFE0
  final Color onHeroDim; // cream @ .75
  final Color onHeroFaint; // cream @ .7
  final List<Color> headerGradient; // #21624B -> #17492F
  final Color gold; // #D1B774 — progress on green, tafsir accent
  final Color goldTintBg;
  final Color goldTintFg;
  final Color oliveTintBg; // متوسط badge
  final Color oliveTintFg;
  final Color greenTintBorder; // #D5E2D9 — border of green-tinted circles
  final Color textMuted; // #8A968D
  final Color textFaint; // timestamps #B0AC9C
  final Color highlightRow; // current-lesson row bg
  final Color highlightTrack;
  final Color navBackground;
  final Color navInactive;
  final Color timelineInactive; // #D8D4C6
  final Color upcomingCircle; // #ECE9DE
  final Color chipBg;
  final Color chipBorder;
  final Color chipText;
  final Color attributionBg;
  final Color attributionBorder;
  final Color attributionText;
  final Color heroShadow;

  static const light = MasarColors(
    heroGreen: Color(0xFF1E5B45),
    onHero: Color(0xFFF3EFE0),
    onHeroDim: Color(0xBFF3EFE0),
    onHeroFaint: Color(0xB3F3EFE0),
    headerGradient: [Color(0xFF21624B), Color(0xFF17492F)],
    gold: Color(0xFFD1B774),
    goldTintBg: Color(0xFFF3EDDD),
    goldTintFg: Color(0xFFA8874B),
    oliveTintBg: Color(0xFFEEF0E4),
    oliveTintFg: Color(0xFF6E7A4E),
    greenTintBorder: Color(0xFFD5E2D9),
    textMuted: Color(0xFF8A968D),
    textFaint: Color(0xFFB0AC9C),
    highlightRow: Color(0xFFF4F8F5),
    highlightTrack: Color(0xFFE1E8E2),
    navBackground: Color(0xF0FFFFFF),
    navInactive: Color(0xFF8A968D),
    timelineInactive: Color(0xFFD8D4C6),
    upcomingCircle: Color(0xFFECE9DE),
    chipBg: Color(0xFFFFFFFF),
    chipBorder: Color(0xFFE3DFD1),
    chipText: Color(0xFF55645B),
    attributionBg: Color(0xFFEFEBDD),
    attributionBorder: Color(0xFFE3DCC5),
    attributionText: Color(0xFF55503F),
    heroShadow: Color(0x381E5B45),
  );

  static const dark = MasarColors(
    heroGreen: Color(0xFF1E5B45),
    onHero: Color(0xFFF3EFE0),
    onHeroDim: Color(0xBFF3EFE0),
    onHeroFaint: Color(0xB3F3EFE0),
    headerGradient: [Color(0xFF21624B), Color(0xFF17492F)],
    gold: Color(0xFFD1B774),
    goldTintBg: Color(0xFF2A2416),
    goldTintFg: Color(0xFFD1B774),
    oliveTintBg: Color(0xFF222B1C),
    oliveTintFg: Color(0xFFA8B36E),
    greenTintBorder: Color(0xFF26332B),
    textMuted: Color(0xFF5B6B60),
    textFaint: Color(0xFF5B6B60),
    highlightRow: Color(0xFF1B2620),
    highlightTrack: Color(0xFF26332B),
    navBackground: Color(0xF00F1613),
    navInactive: Color(0xFF5B6B60),
    timelineInactive: Color(0xFF26332B),
    upcomingCircle: Color(0xFF17211A),
    chipBg: Color(0xFF17211A),
    chipBorder: Color(0xFF26332B),
    chipText: Color(0xFF93A398),
    attributionBg: Color(0xFF17211A),
    attributionBorder: Color(0xFF26332B),
    attributionText: Color(0xFF93A398),
    heroShadow: Color(0x00000000),
  );

  @override
  MasarColors copyWith() => this;

  @override
  MasarColors lerp(MasarColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

MasarColors masarColorsOf(BuildContext context) =>
    Theme.of(context).extension<MasarColors>() ?? MasarColors.light;

ColorScheme _lightScheme() => const ColorScheme.light(
  primary: Color(0xFF1E5B45),
  onPrimary: Color(0xFFF3F1E7),
  primaryContainer: Color(0xFFE7EFE9),
  onPrimaryContainer: Color(0xFF1E5B45),
  secondaryContainer: Color(0xFFF3EDDD),
  onSecondaryContainer: Color(0xFFA8874B),
  tertiary: Color(0xFFD1B774),
  surface: Color(0xFFF6F4EE),
  onSurface: Color(0xFF1F2A24),
  onSurfaceVariant: Color(0xFF6B7A70),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFFFFFFF),
  surfaceContainerHigh: Color(0xFFF4F8F5),
  surfaceContainerHighest: Color(0xFFECE9DE),
  outline: Color(0xFFE3DFD1),
  outlineVariant: Color(0xFFE7E3D6),
);

ColorScheme _darkScheme() => const ColorScheme.dark(
  primary: Color(0xFF7CC4A2),
  onPrimary: Color(0xFF0F1613),
  primaryContainer: Color(0xFF1B2A21),
  onPrimaryContainer: Color(0xFF7CC4A2),
  secondaryContainer: Color(0xFF2A2416),
  onSecondaryContainer: Color(0xFFD1B774),
  tertiary: Color(0xFFD1B774),
  surface: Color(0xFF0F1613),
  onSurface: Color(0xFFECEAE0),
  onSurfaceVariant: Color(0xFF93A398),
  surfaceContainerLowest: Color(0xFF17211A),
  surfaceContainerLow: Color(0xFF17211A),
  surfaceContainer: Color(0xFF17211A),
  surfaceContainerHigh: Color(0xFF1B2620),
  surfaceContainerHighest: Color(0xFF26332B),
  outline: Color(0xFF26332B),
  outlineVariant: Color(0xFF26332B),
);

TextTheme _textTheme(ColorScheme scheme) {
  return TextTheme(
    // Page titles (المسارات / المكتبة 28, الإعدادات 24)
    headlineMedium: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.35,
    ),
    headlineSmall: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      height: 1.35,
    ),
    // Section headers (متابعة المشاهدة 17 w700)
    titleLarge: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 1.45,
    ),
    titleMedium: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.45,
    ),
    titleSmall: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      height: 1.45,
    ),
    bodyLarge: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodyMedium: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodySmall: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    labelLarge: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelMedium: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    labelSmall: const TextStyle(
      fontFamily: kUiFont,
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = isDark ? _darkScheme() : _lightScheme();
  final masar = isDark ? MasarColors.dark : MasarColors.light;
  final textTheme = _textTheme(scheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: kUiFont,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [masar],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? const Color(0xFF26332B) : const Color(0xFFF0EDE2),
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.surfaceContainerHighest,
      color: scheme.primary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(
        isDark ? scheme.onPrimary : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : (isDark ? const Color(0xFF26332B) : const Color(0xFFD8D4C6)),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
    ),
  );
}
