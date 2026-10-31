import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/widgets/language_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../auth/presentation/set_pin_dialog.dart';

/// Landing screen after sign-in: who is signed in, at which car wash, with which roles,
/// branches and permissions. Feature menus will be built on top of these permissions.
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
        title: Text(me.carWashName),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: l10n.switchUser,
            icon: const Icon(Icons.switch_account_outlined),
            onPressed: () => context.push('/pin'),
          ),
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
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
                subtitle: me.email == null ? null : Text(me.email!),
                trailing: me.isOwner ? Chip(label: Text(l10n.ownerBadge)) : null,
              ),
            ),
            const _ManagementMenu(),
            _Section(
              title: l10n.rolesSection,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final role in me.roles) Chip(label: Text(role.label))],
              ),
            ),
            _Section(
              title: l10n.branchesSection,
              child: _Branches(me: me),
            ),
            _Section(
              title: '${l10n.permissionsSection} · ${l10n.permissionsCount(me.permissions.length)}',
              child: _Permissions(permissions: me.permissions),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _setPin(context),
              icon: const Icon(Icons.pin_outlined),
              label: Text(l10n.setPin),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPin(BuildContext context) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const SetPinDialog());
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).pinSaved)));
    }
  }
}

/// Management sections, each shown only to staff holding its permission.
class _ManagementMenu extends ConsumerWidget {
  const _ManagementMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final l10n = AppLocalizations.of(context);
    final entries = [
      (path: '/staff', icon: Icons.groups_outlined, title: l10n.staffTitle, subtitle: l10n.staffSubtitle),
      (path: '/roles', icon: Icons.admin_panel_settings_outlined, title: l10n.rolesTitle, subtitle: l10n.rolesSubtitle),
      (path: '/devices', icon: Icons.devices_other_outlined, title: l10n.devicesTitle, subtitle: l10n.devicesSubtitle),
    ].where((entry) => me != null && canOpen(entry.path, me)).toList();

    if (entries.isEmpty) {
      return const SizedBox.shrink();
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Branches extends StatelessWidget {
  const _Branches({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (me.branches.isEmpty) {
      return Text(l10n.noBranches);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (me.allBranches) Text(l10n.allBranches, style: Theme.of(context).textTheme.labelLarge),
        for (final branch in me.branches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.store_outlined),
            title: Text(branch.name),
            subtitle: Text(branch.code),
          ),
      ],
    );
  }
}

/// Permissions grouped by module ("orders.view" → orders: view).
class _Permissions extends StatelessWidget {
  const _Permissions({required this.permissions});

  final Set<String> permissions;

  @override
  Widget build(BuildContext context) {
    final byModule = <String, List<String>>{};
    for (final permission in permissions) {
      final [module, action] = permission.split('.');
      byModule.putIfAbsent(module, () => []).add(action);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: module, value: actions) in byModule.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(module, style: Theme.of(context).textTheme.labelLarge),
                for (final action in actions) Chip(label: Text(action), visualDensity: VisualDensity.compact),
              ],
            ),
          ),
      ],
    );
  }
}
