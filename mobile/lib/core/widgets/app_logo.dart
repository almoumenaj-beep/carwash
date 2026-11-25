import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The car wash's logo, a wide badge; [size] is its height and the width follows the image's
/// aspect ratio, capped at [maxWidth] so tight spots (the side menu) never overflow.
///
/// The image is transparent and shows whatever lies behind it. It comes in two inks: the original
/// dark one for light surfaces, and a light-inked variant for dark ones — the dark theme always
/// uses it, and [onNavy] marks spots that are navy even in the light theme (the bars), so the logo
/// never needs a background badge.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.maxWidth, this.onNavy = false});

  final double size;
  final double? maxWidth;

  /// The spot sits on a navy surface even in the light theme (the app bar, the side menu).
  final bool onNavy;

  @override
  Widget build(BuildContext context) {
    final nightInk = onNavy || Theme.of(context).brightness == Brightness.dark;
    final width = maxWidth ?? size * 3.6;
    return SizedBox(
      width: width,
      height: size,
      child: ClipRect(
        child: Image.asset(
          nightInk ? 'assets/branding/logo_night.png' : 'assets/branding/logo.png',
          width: width,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          semanticLabel: AppLocalizations.of(context).appTitle,
        ),
      ),
    );
  }
}
