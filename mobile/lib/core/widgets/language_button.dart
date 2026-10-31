import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';

/// Switches between Arabic and English; labelled with the language it switches to.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: ref.read(localeProvider.notifier).toggle,
      icon: const Icon(Icons.translate),
      label: Text(AppLocalizations.of(context).changeLanguage),
    );
  }
}
