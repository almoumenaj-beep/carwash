import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../appointments/application/booking_alerts.dart';
import '../../auth/application/session_controller.dart';
import 'home_sections.dart';

/// Widths at which the layout changes: below [desktop] the hamburger rail, from [desktop] the full side menu.
abstract final class Breakpoints {
  /// The full side menu needs this much width; anything narrower (phones in any orientation,
  /// portrait tablets) gets the hamburger rail instead.
  static const desktop = 1200.0;

  /// The widest a page's content grows to, so lists and forms stay readable on large screens.
  static const contentMaxWidth = 1100.0;
}

/// Frames every signed-in screen to the screen's size: below the desktop width a slim rail whose
/// hamburger opens the full side menu as a drawer, from the desktop width the menu stays visible;
/// the page itself sits beside it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Polls today's bookings for website bookings, wherever the user is in the app.
    ref.watch(bookingAlertsWatcherProvider);

    final width = MediaQuery.sizeOf(context).width;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final menuBackground = isDark ? AppTheme.warmBar : AppTheme.navy;

    // Below the desktop width the menu lives behind a hamburger: a slim rail with the button opens it
    // as a drawer, up to phone size in either orientation.
    if (width < Breakpoints.desktop) {
      return Scaffold(
        drawer: Drawer(
          width: 280,
          child: _SideMenu(location: location, background: menuBackground, darkSurface: isDark),
        ),
        body: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Row(
            children: [
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: menuBackground,
                  border: const BorderDirectional(end: BorderSide(color: AppTheme.gold, width: 2)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: AppLocalizations.of(context).menuTooltip,
                          icon: Icon(Icons.menu, color: isDark ? AppTheme.navy : AppTheme.lightGold),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          _SideMenu(location: location, background: menuBackground, darkSurface: isDark),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideMenu extends ConsumerWidget {
  const _SideMenu({required this.location, required this.background, required this.darkSurface});

  final String location;
  final Color background;

  /// The menu sits on the light-warm bar color instead of navy.
  final bool darkSurface;

  bool _isCurrent(String path) => path == '/' ? location == '/' : location == path || location.startsWith('$path/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final l10n = AppLocalizations.of(context);
    final daily = me == null ? const <HomeSection>[] : openable(dailySections(l10n), me);
    final groups = [
      if (me != null)
        for (final group in sectionGroups(l10n))
          if (openable(group.sections, me) case final sections when sections.isNotEmpty)
            (title: group.title, sections: sections),
    ];

    final home = (path: '/', icon: Icons.home_outlined, title: l10n.homeTitle, subtitle: '');
    final account = (path: '/account', icon: Icons.account_circle_outlined, title: l10n.accountTitle, subtitle: '');

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: background,
        border: const BorderDirectional(end: BorderSide(color: AppTheme.gold, width: 2)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: AppLogo(size: 64, maxWidth: 238, lightBadge: true),
            ),
            Divider(color: darkSurface ? const Color(0x331B3A66) : Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, home),
                  for (final section in daily) _item(context, section),
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 6),
                      child: Text(
                        group.title,
                        style: TextStyle(
                          color: darkSurface ? const Color(0xFF8A6A1F) : AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final section in group.sections) _item(context, section),
                  ],
                ],
              ),
            ),
            Divider(color: darkSurface ? const Color(0x331B3A66) : Colors.white24, height: 1),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _item(context, account)),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, HomeSection section) {
    final current = _isCurrent(section.path);
    final foreground = current ? AppTheme.deepNavy : (darkSurface ? AppTheme.navy : Colors.white);
    final tile = Material(
      color: current ? AppTheme.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(section.path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Icon(section.icon, color: foreground, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  section.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontWeight: current ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2), child: tile);
  }
}
