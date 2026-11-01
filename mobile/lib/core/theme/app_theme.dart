import 'package:flutter/material.dart';

/// Material 3 theme in light and dark, from one brand seed colour: a light teal (blue-green).
abstract final class AppTheme {
  static const _seed = Color(0xFF26A69A);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      // Fidelity keeps the primary colour close to the seed instead of muting it.
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
