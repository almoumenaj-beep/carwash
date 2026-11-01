import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/presentation/set_pin_dialog.dart';

/// The signed-in staff member's own account, kept to one line per item; the full
/// permission list opens in a sheet on demand.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  Future<void> _setPin(BuildContext context) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const SetPinDialog());
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).pinSaved)));
    }
  }

  void _showPermissions(BuildContext context, Set<String> permissions) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) =>
            _PermissionsList(permissions: permissions, controller: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    if (me == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final branchNames = me.branches.map((branch) => branch.name).join(l10n.listSeparator);
    final branches = me.branches.isEmpty
        ? l10n.noBranches
        : (me.allBranches ? '${l10n.allBranches}: $branchNames' : branchNames);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(sessionProvider.future),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    child: Text(me.name.characters.first, style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 12),
                  Text(me.name, style: theme.textTheme.titleLarge),
                  if (me.email != null) Text(me.email!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${me.roles.map((role) => role.label).join(l10n.listSeparator)} · ${me.carWashName}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(l10n.branchesSection),
              subtitle: Text(branches),
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(l10n.permissionsSection),
              subtitle: Text(l10n.permissionsCount(me.permissions.length)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPermissions(context, me.permissions),
            ),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.pin_outlined), title: Text(l10n.setPin), onTap: () => _setPin(context)),
            ListTile(
              leading: const Icon(Icons.switch_account_outlined),
              title: Text(l10n.switchUser),
              onTap: () => context.push('/pin'),
            ),
            ListTile(
              leading: const Icon(Icons.translate),
              title: Text(l10n.languageField),
              subtitle: Text(
                ref.watch(localeProvider).languageCode == 'ar' ? l10n.arabicLanguage : l10n.englishLanguage,
              ),
              onTap: ref.read(localeProvider.notifier).toggle,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(l10n.darkMode),
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              onChanged: ref.read(themeModeProvider.notifier).setDark,
            ),
            ListTile(leading: const Icon(Icons.palette_outlined), title: Text(l10n.appColor)),
            const Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, 16), child: _ColorPicker()),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(l10n.signOut, style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => ref.read(sessionProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Permissions grouped by module ("orders.view" → orders: view).
class _PermissionsList extends StatelessWidget {
  const _PermissionsList({required this.permissions, required this.controller});

  final Set<String> permissions;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final byModule = <String, List<String>>{};
    for (final permission in permissions) {
      final [module, action] = permission.split('.');
      byModule.putIfAbsent(module, () => []).add(action);
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          '${l10n.permissionsSection} · ${l10n.permissionsCount(permissions.length)}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
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

/// The app colours as swatches; tapping one re-themes the whole app at once.
class _ColorPicker extends ConsumerWidget {
  const _ColorPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(brandColorProvider);
    final names = {
      'teal': l10n.colorTeal,
      'turquoise': l10n.colorTurquoise,
      'deep_teal': l10n.colorDeepTeal,
      'sky': l10n.colorSky,
      'navy': l10n.colorNavy,
      'green': l10n.colorGreen,
      'purple': l10n.colorPurple,
      'orange': l10n.colorOrange,
    };

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in AppTheme.brandColors)
          Tooltip(
            message: names[color.key] ?? color.key,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ref.read(brandColorProvider.notifier).select(color),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.seed,
                    child: color.key == selected.key ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                  const SizedBox(height: 4),
                  Text(names[color.key] ?? color.key, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
