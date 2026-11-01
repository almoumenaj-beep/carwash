import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/session_storage.dart';
import 'app_theme.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

final brandColorProvider = NotifierProvider<BrandColorController, BrandColor>(BrandColorController.new);

/// Light (the default) or dark, remembered on this device.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    final saved = await ref.read(sessionStorageProvider).themeMode();
    if (saved == ThemeMode.dark.name) {
      state = ThemeMode.dark;
    }
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await ref.read(sessionStorageProvider).saveThemeMode(state.name);
  }

  Future<void> toggle() => setDark(!isDark);
}

/// The app's colour, one of [AppTheme.brandColors], remembered on this device.
class BrandColorController extends Notifier<BrandColor> {
  @override
  BrandColor build() {
    _restore();
    return AppTheme.brandColors.first;
  }

  Future<void> _restore() async {
    final saved = await ref.read(sessionStorageProvider).brandColor();
    final match = AppTheme.brandColors.where((color) => color.key == saved).firstOrNull;
    if (match != null) {
      state = match;
    }
  }

  Future<void> select(BrandColor color) async {
    state = color;
    await ref.read(sessionStorageProvider).saveBrandColor(color.key);
  }
}
