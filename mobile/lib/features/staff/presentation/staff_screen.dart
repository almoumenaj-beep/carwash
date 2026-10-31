import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/staff_repository.dart';
import '../domain/staff_member.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/staff/new'),
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.newStaff),
      ),
      body: switch (ref.watch(staffListProvider)) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(staffListProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _StaffTile(staff: value[index]),
          ),
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(staffListProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({required this.staff});

  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final roles = staff.roles.map((role) => role.label).join(l10n.listSeparator);
    final branches = staff.allBranches
        ? l10n.allBranches
        : staff.branches.map((branch) => branch.name).join(l10n.listSeparator);

    return ListTile(
      leading: CircleAvatar(child: Text(staff.name.characters.first)),
      title: Text(staff.name),
      subtitle: Text([roles, branches].where((part) => part.isNotEmpty).join(' · ')),
      trailing: staff.isActive
          ? (staff.isOwner ? Chip(label: Text(l10n.ownerBadge)) : null)
          : Chip(label: Text(l10n.inactive), backgroundColor: theme.colorScheme.errorContainer),
      onTap: () => context.push('/staff/${staff.id}'),
    );
  }
}
