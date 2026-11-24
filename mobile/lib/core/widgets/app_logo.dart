import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The car wash's logo, a wide badge; [size] is its height and the width follows the image's
/// aspect ratio, capped at [maxWidth] so tight spots (the side menu) never overflow.
///
/// The image is transparent and shows whatever lies behind it; over navy surfaces (the bars) or in
/// the dark theme that would drown its own dark ink, so it then sits on a white rounded badge —
/// [lightBadge] forces the badge, and the dark theme adds it on its own.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.maxWidth, this.lightBadge = false});

  final double size;
  final double? maxWidth;

  /// Show the logo on a white rounded badge even in the light theme, for navy surfaces.
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

    if (!lightBadge && Theme.of(context).brightness == Brightness.light) return logo;

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.2)),
      padding: EdgeInsets.symmetric(horizontal: size * 0.18, vertical: size * 0.07),
      child: logo,
    );
  }
}
