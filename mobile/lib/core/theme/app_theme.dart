import 'package:flutter/material.dart';

/// Material 3 theme in light and dark, from one brand seed colour.
abstract final class AppTheme {
  static const _seed = Color(0xFF0277BD);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
