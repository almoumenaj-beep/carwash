import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/session_storage.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

/// Dark (the default, shown to users as "night mode") or light, remembered on this device.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.dark;
  }

  Future<void> _restore() async {
    final saved = await ref.read(sessionStorageProvider).themeMode();
    if (saved == ThemeMode.light.name) {
      state = ThemeMode.light;
    }
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> setDark(bool dark) async {
    state = dark ? ThemeMode.dark : ThemeMode.light;
    await ref.read(sessionStorageProvider).saveThemeMode(state.name);
  }

  Future<void> toggle() => setDark(!isDark);
}
