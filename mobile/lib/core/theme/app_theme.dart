import 'package:flutter/material.dart';

/// A brand colour the app can be themed with, named for the colour picker.
typedef BrandColor = ({String key, Color seed});

/// Material 3 themes in light and dark, generated from one brand seed colour.
abstract final class AppTheme {
  /// The colours offered on the account screen; the first is the default (a soft light teal).
  static const brandColors = <BrandColor>[
    (key: 'teal', seed: Color(0xFF4DB6AC)),
    (key: 'turquoise', seed: Color(0xFF00ACC1)),
    (key: 'deep_teal', seed: Color(0xFF00796B)),
    (key: 'sky', seed: Color(0xFF29B6F6)),
    (key: 'navy', seed: Color(0xFF283593)),
    (key: 'green', seed: Color(0xFF43A047)),
    (key: 'purple', seed: Color(0xFF7E57C2)),
    (key: 'orange', seed: Color(0xFFFB8C00)),
  ];

  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
