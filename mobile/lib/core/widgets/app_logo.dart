import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The car wash's logo, a wide badge; [size] is its height and the width follows the image's
/// aspect ratio, capped at [maxWidth] so tight spots (the side menu) never overflow.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.maxWidth});

  final double size;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size, maxWidth: maxWidth ?? size * 3.6),
      child: Image.asset(
        'assets/branding/logo.png',
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: AppLocalizations.of(context).appTitle,
      ),
    );
  }
}
