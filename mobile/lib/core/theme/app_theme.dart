import 'package:flutter/material.dart';

/// Material 3 theme in light and dark, in the navy and gold of the «اللمعة الذهبية» logo: navy carries the light
/// theme with gold accents, and gold leads on the deep navy of the dark theme.
abstract final class AppTheme {
  static const navy = Color(0xFF1B3A66);
  static const deepNavy = Color(0xFF0E1B30);
  static const gold = Color(0xFFC9A24B);
  static const lightGold = Color(0xFFE2C27A);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ColorScheme.fromSeed(seedColor: navy, brightness: brightness);
    final scheme = isDark
        ? base.copyWith(
            primary: lightGold,
            onPrimary: deepNavy,
            primaryContainer: const Color(0xFF5A4719),
            onPrimaryContainer: const Color(0xFFFFE8B5),
            secondary: const Color(0xFF9BBCEB),
            onSecondary: deepNavy,
            secondaryContainer: const Color(0xFF24406A),
            onSecondaryContainer: const Color(0xFFD6E3FA),
            tertiary: lightGold,
            onTertiary: deepNavy,
            surface: const Color(0xFF0F1D33),
            onSurface: const Color(0xFFE9EDF4),
            surfaceContainerLowest: const Color(0xFF0B172A),
            surfaceContainerLow: const Color(0xFF13243F),
            surfaceContainer: const Color(0xFF172A48),
            surfaceContainerHigh: const Color(0xFF1C3152),
            surfaceContainerHighest: const Color(0xFF22395E),
            outlineVariant: const Color(0xFF2F4669),
          )
        : base.copyWith(
            primary: navy,
            onPrimary: Colors.white,
            secondary: const Color(0xFF8A6A1F),
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFFF5E6BF),
            onSecondaryContainer: const Color(0xFF3B2C00),
            tertiary: const Color(0xFF8A6A1F),
            tertiaryContainer: const Color(0xFFF5E6BF),
            onTertiaryContainer: const Color(0xFF3B2C00),
            surface: const Color(0xFFFBF9F5),
          );
    final barBackground = isDark ? deepNavy : navy;

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      appBarTheme: AppBarTheme(
        backgroundColor: barBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(color: lightGold, fontSize: 20, fontWeight: FontWeight.w600),
        shape: const Border(bottom: BorderSide(color: gold, width: 2)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainerLow : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: gold.withValues(alpha: isDark ? 0.35 : 0.45)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: gold, foregroundColor: deepNavy),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: barBackground,
        indicatorColor: gold,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? deepNavy : Colors.white70),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              TextStyle(fontSize: 12, color: states.contains(WidgetState.selected) ? lightGold : Colors.white70),
        ),
      ),
    );
  }
}
