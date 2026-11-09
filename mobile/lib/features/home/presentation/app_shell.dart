import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import 'home_sections.dart';

/// Widths at which the layout changes: below [tablet] the phone layout, from [desktop] the full side menu.
abstract final class Breakpoints {
  static const tablet = 720.0;
  static const desktop = 1180.0;

  /// The widest a page's content grows to, so lists and forms stay readable on large screens.
  static const contentMaxWidth = 1100.0;
}

/// Frames every signed-in screen to the screen's size: phones keep the plain screen, tablets get a narrow bar of
/// section icons, and large screens a full side menu with the sections by group; the page itself sits beside it.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < Breakpoints.tablet) {
      return child;
    }

    final compact = width < Breakpoints.desktop;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          _SideMenu(location: location, compact: compact, background: isDark ? AppTheme.deepNavy : AppTheme.navy),
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
  const _SideMenu({required this.location, required this.compact, required this.background});

  final String location;
  final bool compact;
  final Color background;

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
      width: compact ? 88 : 270,
      decoration: BoxDecoration(
        color: background,
        border: const BorderDirectional(end: BorderSide(color: AppTheme.gold, width: 2)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 12 : 20),
              child: Column(
                children: [
                  AppLogo(size: compact ? 52 : 96),
                  if (!compact && me != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      me.carWashName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppTheme.lightGold, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, home),
                  for (final section in daily) _item(context, section),
                  for (final group in groups) ...[
                    if (compact)
                      const Divider(color: Colors.white24, indent: 16, endIndent: 16)
                    else
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 6),
                        child: Text(
                          group.title,
                          style: const TextStyle(color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    for (final section in group.sections) _item(context, section),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _item(context, account)),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, HomeSection section) {
    final current = _isCurrent(section.path);
    final foreground = current ? AppTheme.deepNavy : Colors.white;
    final tile = Material(
      color: current ? AppTheme.gold : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(section.path),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 14, vertical: 11),
          child: compact
              ? Icon(section.icon, color: foreground)
              : Row(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: compact ? Tooltip(message: section.title, child: tile) : tile,
    );
  }
}
