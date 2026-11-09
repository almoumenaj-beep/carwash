import 'package:flutter/material.dart';

/// Material 3 theme in light and dark, from the blue of the «اللمعة الذهبية» logo.
abstract final class AppTheme {
  static const _seed = Color(0xFF2F5D9A);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed, brightness: brightness),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
