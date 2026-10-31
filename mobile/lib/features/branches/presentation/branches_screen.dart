import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/branches_repository.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.branchesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/branches/new'),
        icon: const Icon(Icons.add_business_outlined),
        label: Text(l10n.newBranch),
      ),
      body: switch (ref.watch(branchListProvider)) {
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(branchListProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final branch = value[index];
              return ListTile(
                leading: const Icon(Icons.store_outlined),
                title: Text(branch.name),
                subtitle: Text([branch.code, if (branch.address != null) branch.address!].join(' · ')),
                trailing: branch.isActive ? const Icon(Icons.chevron_right) : Chip(label: Text(l10n.branchClosed)),
                onTap: () => context.push('/branches/${branch.id}'),
              );
            },
          ),
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(branchListProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
