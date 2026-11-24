import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The car wash's logo, a wide badge; [size] is its height and the width follows the image's
/// aspect ratio, capped at [maxWidth] so tight spots (the side menu) never overflow.
///
/// The image is transparent and shows whatever lies behind it; where the surface is dark (navy
/// bars in the light theme, the splash and login pages in the dark theme) its own dark ink would
/// drown, so it then sits on a cream rounded badge. [lightBadge] marks spots that are navy in the
/// light theme only — the dark theme lightens its bars, so the badge drops off there by itself.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.maxWidth, this.lightBadge = false});

  final double size;
  final double? maxWidth;

  /// The spot sits on a navy surface in the light theme, so it needs the badge then.
  final bool lightBadge;

  @override
  Widget build(BuildContext context) {
    final logo = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: size, maxWidth: maxWidth ?? size * 3.6),
      child: Image.asset(
        'assets/branding/logo.png',
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: AppLocalizations.of(context).appTitle,
      ),
    );

    final isLight = Theme.of(context).brightness == Brightness.light;
    final needsBadge = lightBadge ? isLight : !isLight;
    if (!needsBadge) return logo;

    return Container(
      decoration: BoxDecoration(color: const Color(0xFFFBF6EA), borderRadius: BorderRadius.circular(size * 0.2)),
      padding: EdgeInsets.symmetric(horizontal: size * 0.18, vertical: size * 0.07),
      child: logo,
    );
  }
}
