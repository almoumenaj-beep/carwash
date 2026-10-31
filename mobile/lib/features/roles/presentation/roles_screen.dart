import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/can.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/roles_repository.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      floatingActionButton: Can(
        anyOf: const [Permissions.rolesManage],
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/roles/new'),
          icon: const Icon(Icons.add),
          label: Text(l10n.newRole),
        ),
      ),
      body: switch (ref.watch(rolesProvider)) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(rolesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final role = value[index];
              return ListTile(
                leading: Icon(role.isOwnerRole ? Icons.workspace_premium_outlined : Icons.badge_outlined),
                title: Text(role.label),
                subtitle: Text(
                  '${role.isOwnerRole ? l10n.allPermissions : l10n.permissionsCount(role.permissions.length)} · ${l10n.staffCount(role.usersCount)}',
                ),
                trailing: role.isOwnerRole ? const Icon(Icons.lock_outline) : const Icon(Icons.chevron_right),
                onTap: () => context.push('/roles/${role.id}'),
              );
            },
          ),
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(rolesProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
