import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// The app language. Arabic by default; the API receives it as `Accept-Language`.
class LocaleController extends Notifier<Locale> {
  static const supportedLocales = [Locale('ar'), Locale('en')];

  @override
  Locale build() => const Locale('ar');

  void toggle() {
    state = state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
  }
}
