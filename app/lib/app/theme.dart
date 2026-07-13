import 'package:flutter/material.dart';

/// Spacing scale. Use these instead of raw numbers so rhythm stays consistent.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AppRadius {
  static const double tile = 12;
  static const double card = 16;
  static const double sheet = 24;
}

/// Deep, dignified green — the identity color of the app.
const Color _seed = Color(0xFF186B5A);

/// Per-level badge colors that keep contrast in both themes.
@immutable
class LevelColors extends ThemeExtension<LevelColors> {
  const LevelColors({
    required this.beginnerBg,
    required this.beginnerFg,
    required this.intermediateBg,
    required this.intermediateFg,
    required this.advancedBg,
    required this.advancedFg,
  });

  final Color beginnerBg;
  final Color beginnerFg;
  final Color intermediateBg;
  final Color intermediateFg;
  final Color advancedBg;
  final Color advancedFg;

  static const light = LevelColors(
    beginnerBg: Color(0xFFDCEFE4),
    beginnerFg: Color(0xFF14523C),
    intermediateBg: Color(0xFFFBEED3),
    intermediateFg: Color(0xFF6E4A03),
    advancedBg: Color(0xFFE9E2F8),
    advancedFg: Color(0xFF473478),
  );

  static const dark = LevelColors(
    beginnerBg: Color(0xFF1F3A2F),
    beginnerFg: Color(0xFFA9D8BE),
    intermediateBg: Color(0xFF3D2F14),
    intermediateFg: Color(0xFFE8C77E),
    advancedBg: Color(0xFF322852),
    advancedFg: Color(0xFFC9BAF2),
  );

  @override
  LevelColors copyWith({
    Color? beginnerBg,
    Color? beginnerFg,
    Color? intermediateBg,
    Color? intermediateFg,
    Color? advancedBg,
    Color? advancedFg,
  }) {
    return LevelColors(
      beginnerBg: beginnerBg ?? this.beginnerBg,
      beginnerFg: beginnerFg ?? this.beginnerFg,
      intermediateBg: intermediateBg ?? this.intermediateBg,
      intermediateFg: intermediateFg ?? this.intermediateFg,
      advancedBg: advancedBg ?? this.advancedBg,
      advancedFg: advancedFg ?? this.advancedFg,
    );
  }

  @override
  LevelColors lerp(LevelColors? other, double t) {
    if (other == null) return this;
    return LevelColors(
      beginnerBg: Color.lerp(beginnerBg, other.beginnerBg, t)!,
      beginnerFg: Color.lerp(beginnerFg, other.beginnerFg, t)!,
      intermediateBg: Color.lerp(intermediateBg, other.intermediateBg, t)!,
      intermediateFg: Color.lerp(intermediateFg, other.intermediateFg, t)!,
      advancedBg: Color.lerp(advancedBg, other.advancedBg, t)!,
      advancedFg: Color.lerp(advancedFg, other.advancedFg, t)!,
    );
  }
}

/// Arabic text wants more air than Latin defaults: bigger base size and
/// generous line-height so ascenders/diacritics never feel cramped.
TextTheme _textTheme(ColorScheme scheme) {
  const family = 'IBMPlexSansArabic';
  return TextTheme(
    displaySmall: const TextStyle(
      fontFamily: family,
      fontSize: 30,
      fontWeight: FontWeight.w700,
      height: 1.4,
    ),
    headlineSmall: const TextStyle(
      fontFamily: family,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.45,
    ),
    titleLarge: const TextStyle(
      fontFamily: family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleMedium: const TextStyle(
      fontFamily: family,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleSmall: const TextStyle(
      fontFamily: family,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    bodyLarge: const TextStyle(
      fontFamily: family,
      fontSize: 17,
      fontWeight: FontWeight.w400,
      height: 1.7,
    ),
    bodyMedium: const TextStyle(
      fontFamily: family,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.7,
    ),
    bodySmall: const TextStyle(
      fontFamily: family,
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    labelLarge: const TextStyle(
      fontFamily: family,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    labelMedium: const TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
    labelSmall: const TextStyle(
      fontFamily: family,
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.4,
    ),
  ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final textTheme = _textTheme(scheme);
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'IBMPlexSansArabic',
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    extensions: [isDark ? LevelColors.dark : LevelColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
    ),
    chipTheme: ChipThemeData(
      labelStyle: textTheme.labelLarge,
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearTrackColor: scheme.surfaceContainerHighest,
      color: scheme.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
    ),
  );
}
