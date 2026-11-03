import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../staff_affairs/presentation/attendance_card.dart';

/// Landing screen after sign-in: who is working, and the sections they may open.
/// Account details (roles, branches, permissions) and settings such as language and dark mode live on the account screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    if (me == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        // The car wash's name beside the logo, shrunk to fit rather than cut off.
        title: Row(
          children: [
            const AppLogo(size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  me.carWashName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.switchUser,
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => context.push('/pin'),
          ),
          IconButton(
            tooltip: l10n.accountTitle,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/account'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(sessionProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(me.name.characters.first)),
                title: Text(l10n.greeting(me.name)),
                subtitle: Text(me.roles.map((role) => role.label).join(l10n.listSeparator)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/account'),
              ),
            ),
            const AttendanceCard(),
            const _SectionsMenu(),
          ],
        ),
      ),
    );
  }
}

/// The sections of the app, each shown only to staff holding its permission.
class _SectionsMenu extends ConsumerWidget {
  const _SectionsMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final l10n = AppLocalizations.of(context);
    final entries = [
      (path: '/queue', icon: Icons.local_car_wash_outlined, title: l10n.queueTitle, subtitle: l10n.queueSubtitle),
      (path: '/shift', icon: Icons.point_of_sale_outlined, title: l10n.shiftTitle, subtitle: l10n.shiftSubtitle),
      (
        path: '/reports',
        icon: Icons.bar_chart_outlined,
        title: l10n.dailySalesTitle,
        subtitle: l10n.dailySalesSubtitle,
      ),
      (
        path: '/expenses',
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.expensesTitle,
        subtitle: l10n.expensesSubtitle,
      ),
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
      (
        path: '/staff-affairs',
        icon: Icons.badge_outlined,
        title: l10n.staffAffairsTitle,
        subtitle: l10n.staffAffairsSubtitle,
      ),
      (
        path: '/customers',
        icon: Icons.people_alt_outlined,
        title: l10n.customersTitle,
        subtitle: l10n.customersSubtitle,
      ),
      (path: '/catalog', icon: Icons.sell_outlined, title: l10n.catalogTitle, subtitle: l10n.catalogSubtitle),
      (path: '/staff', icon: Icons.groups_outlined, title: l10n.staffTitle, subtitle: l10n.staffSubtitle),
      (path: '/roles', icon: Icons.admin_panel_settings_outlined, title: l10n.rolesTitle, subtitle: l10n.rolesSubtitle),
      (path: '/branches', icon: Icons.store_outlined, title: l10n.branchesTitle, subtitle: l10n.branchesSubtitle),
      (path: '/devices', icon: Icons.devices_other_outlined, title: l10n.devicesTitle, subtitle: l10n.devicesSubtitle),
      (path: '/settings', icon: Icons.settings_outlined, title: l10n.settingsTitle, subtitle: l10n.settingsSubtitle),
    ].where((entry) => me != null && canOpen(entry.path, me)).toList();

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.noSectionsYet, textAlign: TextAlign.center),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final entry in entries)
            ListTile(
              leading: Icon(entry.icon),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(entry.path),
            ),
        ],
      ),
    );
  }
}
