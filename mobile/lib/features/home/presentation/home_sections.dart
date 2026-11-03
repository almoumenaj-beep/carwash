import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';

/// A section of the app: where it opens, and how it is shown.
typedef HomeSection = ({String path, IconData icon, String title, String subtitle});

/// Related sections shown together under one heading.
typedef HomeGroup = ({String id, IconData icon, String title, List<HomeSection> sections});

/// The sections used every day, shown as tiles on the home screen.
List<HomeSection> dailySections(AppLocalizations l10n) => [
  (path: '/queue', icon: Icons.local_car_wash_outlined, title: l10n.queueTitle, subtitle: l10n.queueSubtitle),
  (
    path: '/appointments',
    icon: Icons.event_available_outlined,
    title: l10n.appointmentsTitle,
    subtitle: l10n.appointmentsSubtitle,
  ),
  (path: '/shift', icon: Icons.point_of_sale_outlined, title: l10n.shiftTitle, subtitle: l10n.shiftSubtitle),
  (path: '/customers', icon: Icons.people_alt_outlined, title: l10n.customersTitle, subtitle: l10n.customersSubtitle),
];

/// The other sections, grouped by what they are about.
List<HomeGroup> sectionGroups(AppLocalizations l10n) => [
  (
    id: 'finance',
    icon: Icons.account_balance_outlined,
    title: l10n.groupFinance,
    sections: [
      (
        path: '/reports',
        icon: Icons.bar_chart_outlined,
        title: l10n.dailySalesTitle,
        subtitle: l10n.dailySalesSubtitle,
      ),
      (
        path: '/finance',
        icon: Icons.query_stats_outlined,
        title: l10n.financialReportsTitle,
        subtitle: l10n.financialReportsSubtitle,
      ),
      (
        path: '/expenses',
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.expensesTitle,
        subtitle: l10n.expensesSubtitle,
      ),
    ],
  ),
  (
    id: 'resources',
    icon: Icons.inventory_2_outlined,
    title: l10n.groupResources,
    sections: [
      (
        path: '/inventory',
        icon: Icons.inventory_2_outlined,
        title: l10n.inventoryTitle,
        subtitle: l10n.inventorySubtitle,
      ),
      (
        path: '/equipment',
        icon: Icons.precision_manufacturing_outlined,
        title: l10n.equipmentTitle,
        subtitle: l10n.equipmentSubtitle,
      ),
    ],
  ),
  (
    id: 'people',
    icon: Icons.groups_outlined,
    title: l10n.groupPeople,
    sections: [
      (
        path: '/staff-affairs',
        icon: Icons.badge_outlined,
        title: l10n.staffAffairsTitle,
        subtitle: l10n.staffAffairsSubtitle,
      ),
      (path: '/staff', icon: Icons.manage_accounts_outlined, title: l10n.staffTitle, subtitle: l10n.staffSubtitle),
      (path: '/roles', icon: Icons.admin_panel_settings_outlined, title: l10n.rolesTitle, subtitle: l10n.rolesSubtitle),
    ],
  ),
  (
    id: 'setup',
    icon: Icons.settings_outlined,
    title: l10n.groupSetup,
    sections: [
      (path: '/catalog', icon: Icons.sell_outlined, title: l10n.catalogTitle, subtitle: l10n.catalogSubtitle),
      (path: '/branches', icon: Icons.store_outlined, title: l10n.branchesTitle, subtitle: l10n.branchesSubtitle),
      (path: '/devices', icon: Icons.devices_other_outlined, title: l10n.devicesTitle, subtitle: l10n.devicesSubtitle),
      (path: '/settings', icon: Icons.tune_outlined, title: l10n.settingsTitle, subtitle: l10n.settingsSubtitle),
    ],
  ),
];

/// The sections [me] may open.
List<HomeSection> openable(List<HomeSection> sections, Me me) =>
    sections.where((section) => canOpen(section.path, me)).toList();

/// The daily sections as tiles, then a card per group; a group with one section the user may open opens it
/// directly. Everything is shown only to staff holding its permission.
class HomeSectionsMenu extends ConsumerWidget {
  const HomeSectionsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    if (me == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final daily = openable(dailySections(l10n), me);
    final groups = [
      for (final group in sectionGroups(l10n))
        if (openable(group.sections, me) case final sections when sections.isNotEmpty)
          (group: group, sections: sections),
    ];

    if (daily.isEmpty && groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.noSectionsYet, textAlign: TextAlign.center),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (daily.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(l10n.groupDaily, style: theme.textTheme.titleMedium),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final section in daily)
                    SizedBox(
                      width: width,
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: theme.colorScheme.primaryContainer,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(section.path),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                            child: Column(
                              children: [
                                Icon(section.icon, size: 32, color: theme.colorScheme.onPrimaryContainer),
                                const SizedBox(height: 8),
                                Text(
                                  section.title,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        if (groups.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(l10n.groupMore, style: theme.textTheme.titleMedium),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (:group, :sections) in groups)
                  ListTile(
                    leading: Icon(group.icon),
                    title: Text(sections.length == 1 ? sections.single.title : group.title),
                    subtitle: Text(
                      sections.length == 1
                          ? sections.single.subtitle
                          : sections.map((section) => section.title).join('، '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(sections.length == 1 ? sections.single.path : '/more/${group.id}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The sections of one group that the user may open.
class SectionGroupScreen extends ConsumerWidget {
  const SectionGroupScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final l10n = AppLocalizations.of(context);
    final group = sectionGroups(l10n).where((group) => group.id == groupId).firstOrNull;
    final sections = me == null || group == null ? const <HomeSection>[] : openable(group.sections, me);

    return Scaffold(
      appBar: AppBar(title: Text(group?.title ?? '')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final section in sections)
                  ListTile(
                    leading: Icon(section.icon),
                    title: Text(section.title),
                    subtitle: Text(section.subtitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(section.path),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
