import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The car wash's logo: the round «اللمعة الذهبية» badge, transparent around the circle.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: AppLocalizations.of(context).appTitle,
    );
  }
}
