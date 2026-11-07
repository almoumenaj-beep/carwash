import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../auth/presentation/set_pin_dialog.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../../shifts/data/shifts_repository.dart';
import '../../shifts/domain/cash_shift.dart';
import '../../staff_affairs/data/staff_affairs_repository.dart';
import '../../staff_affairs/domain/staff_affairs.dart';
import 'change_password_dialog.dart';
import 'edit_profile_dialog.dart';

/// The signed-in staff member's own account, kept to one line per item; the full
/// permission list opens in a sheet on demand.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  /// Signs out. Blocked while a cashier is open anywhere, since nobody will be there to count its
  /// drawer afterwards; someone still clocked in is then asked whether their day has ended.
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider.notifier);
    List<CashShift> openShifts = const [];
    try {
      openShifts = await ref.read(shiftsRepositoryProvider).mine();
    } catch (_) {
      // Open shifts could not be read: signing out must still work.
    }

    if (openShifts.isNotEmpty && context.mounted) {
      final l10n = AppLocalizations.of(context);
      final branches = openShifts.map((shift) => shift.branchName ?? '').join(l10n.listSeparator);
      await showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.openShiftBlocksSignOutTitle),
          content: Text(l10n.openShiftBlocksSignOut(branches)),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(l10n.back)),
            FilledButton(
              onPressed: () {
                Navigator.of(dialog).pop();
                context.push('/shift?branch=${openShifts.first.branchId}');
              },
              child: Text(l10n.goToShift),
            ),
          ],
        ),
      );
      return;
    }

    AttendanceRecord? open;
    try {
      open = await ref.read(myAttendanceProvider.future);
    } catch (_) {
      // Attendance could not be read: signing out must still work.
    }

    if (open != null && context.mounted) {
      final l10n = AppLocalizations.of(context);
      final clockOut = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(l10n.endOfDayQuestion),
          content: Text(l10n.endOfDayHint),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialog).pop(), child: Text(l10n.back)),
            OutlinedButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.signOutOnly)),
            FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.clockOutAndSignOut)),
          ],
        ),
      );
      if (clockOut == null) {
        return;
      }
      if (clockOut) {
        try {
          await ref.read(staffAffairsRepositoryProvider).clockOut();
        } catch (error, stackTrace) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
          }
          return;
        }
      }
    }

    await session.signOut();
  }

  Future<void> _editProfile(BuildContext context, Me me) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => EditProfileDialog(me: me),
    );
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).profileSaved)));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if ((saved ?? false) && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).passwordChanged)));
    }
  }

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
                  if (me.phone != null)
                    Text(me.phone!, style: theme.textTheme.bodyMedium, textDirection: TextDirection.ltr),
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
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editProfile),
              onTap: () => _editProfile(context, me),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outlined),
              title: Text(l10n.changePassword),
              onTap: () => _changePassword(context),
            ),
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
            if (me.deviceIsShared) ...[
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: Text(l10n.setPin),
                onTap: () => _setPin(context),
              ),
              ListTile(
                leading: const Icon(Icons.switch_account_outlined),
                title: Text(l10n.switchUser),
                onTap: () => context.push('/pin'),
              ),
            ],
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
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(l10n.signOut, style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _signOut(context, ref),
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
