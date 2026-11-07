import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../data/equipment_repository.dart';
import '../domain/equipment.dart';

/// On the home screen: how many machines need maintenance or are broken. Shows nothing when all is well.
class EquipmentAlertCard extends ConsumerWidget {
  const EquipmentAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final equipment = ref.watch(equipmentProvider).value ?? const <Equipment>[];
    final due = equipment.where((item) => item.isDue).length;
    final broken = equipment.where((item) => item.status == EquipmentStatus.outOfService).length;
    if (due == 0 && broken == 0) {
      return const SizedBox.shrink();
    }

    return Card(
      color: colors.errorContainer,
      child: ListTile(
        leading: Icon(Icons.build_circle_outlined, color: colors.onErrorContainer),
        title: Text(
          [if (due > 0) l10n.maintenanceDueCount(due), if (broken > 0) l10n.equipmentBrokenCount(broken)].join('\n'),
          style: TextStyle(color: colors.onErrorContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.onErrorContainer),
        onTap: () => context.push('/equipment'),
      ),
    );
  }
}
