import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/domain/me.dart';
import '../../l10n/app_localizations.dart';

/// Which branch a screen shows, as chips always in view: "all branches" (null, unless [includeAll] is off) or one
/// of the user's branches. Shows nothing for staff with a single branch.
class BranchChips extends ConsumerWidget {
  const BranchChips({super.key, required this.selected, required this.onChanged, this.includeAll = true});

  /// The chosen branch, or null for all of them.
  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool includeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    if (branches.length < 2) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final (id, name) in [
            if (includeAll) (null, l10n.allBranches),
            for (final branch in branches) (branch.id, branch.name),
          ])
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                avatar: id == null ? const Icon(Icons.store_mall_directory_outlined, size: 18) : null,
                label: Text(name),
                selected: selected == id,
                onSelected: (_) => onChanged(id),
              ),
            ),
        ],
      ),
    );
  }
}
