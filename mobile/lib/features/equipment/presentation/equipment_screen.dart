import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/equipment_repository.dart';
import '../domain/equipment.dart';
import 'equipment_forms.dart';

String equipmentStatusLabel(AppLocalizations l10n, EquipmentStatus status) => switch (status) {
  EquipmentStatus.inService => l10n.equipmentInService,
  EquipmentStatus.outOfService => l10n.equipmentOutOfService,
  EquipmentStatus.retired => l10n.equipmentRetired,
};

/// When periodic maintenance is due, e.g. "Maintenance overdue by 3 days".
String? maintenanceDueLabel(AppLocalizations l10n, Equipment equipment) {
  final days = equipment.daysUntilMaintenance;
  if (days == null) {
    return null;
  }
  if (days < 0) {
    return l10n.maintenanceOverdue(-days);
  }
  return days == 0 ? l10n.maintenanceDueToday : l10n.maintenanceDueIn(days);
}

/// Equipment at the user's branches, what is due for maintenance first.
class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canManage = ref.watch(sessionProvider).value?.can(Permissions.equipmentManage) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.equipmentTitle)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EquipmentEditorScreen())),
              icon: const Icon(Icons.add),
              label: Text(l10n.addEquipment),
            )
          : null,
      body: switch (ref.watch(equipmentProvider)) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.noEquipment, textAlign: TextAlign.center),
          ),
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(equipmentProvider.future),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (value.any((equipment) => equipment.isDue))
                Card(
                  margin: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.build_circle_outlined),
                    title: Text(l10n.maintenanceDueCount(value.where((equipment) => equipment.isDue).length)),
                  ),
                ),
              for (final equipment in value) _EquipmentTile(equipment: equipment),
            ],
          ),
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(equipmentProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EquipmentTile extends StatelessWidget {
  const _EquipmentTile({required this.equipment});

  final Equipment equipment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final due = maintenanceDueLabel(l10n, equipment);
    final retired = equipment.status == EquipmentStatus.retired;

    return ListTile(
      textColor: retired ? Theme.of(context).disabledColor : null,
      leading: Icon(
        equipment.status == EquipmentStatus.outOfService
            ? Icons.report_problem_outlined
            : Icons.precision_manufacturing_outlined,
        color: equipment.isDue || equipment.status == EquipmentStatus.outOfService ? colors.error : null,
      ),
      title: Text(equipment.name),
      subtitle: Text(
        [
          equipment.branchName,
          if (equipment.status != EquipmentStatus.inService) equipmentStatusLabel(l10n, equipment.status),
          ?due,
        ].join(' · '),
        style: equipment.isDue ? TextStyle(color: colors.error) : null,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/equipment/${equipment.id}'),
    );
  }
}

/// A piece of equipment with its maintenance history; staff who manage equipment record maintenance here.
class EquipmentDetailScreen extends ConsumerWidget {
  const EquipmentDetailScreen({super.key, required this.equipmentId});

  final String equipmentId;

  /// Asks first, since it changes the expenses and the equipment's schedule or status.
  Future<void> _cancelMaintenance(BuildContext context, WidgetRef ref, String maintenanceId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.cancelMaintenance),
        content: Text(l10n.cancelMaintenanceConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.back)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.cancelMaintenance)),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(equipmentRepositoryProvider).cancelMaintenance(equipmentId, maintenanceId);
      ref.invalidate(equipmentProvider);
      ref.invalidate(maintenancesProvider(equipmentId));
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  /// Says what the change does and asks first; a slip of the finger must not change the equipment's status.
  Future<void> _confirmStatus(
    BuildContext context,
    WidgetRef ref,
    EquipmentStatus status, {
    required String title,
    required String explanation,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.back)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.confirmAction)),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await _setStatus(context, ref, status);
    }
  }

  /// Asks why it broke and says what reporting it does.
  Future<void> _reportBreakdown(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(context: context, builder: (_) => const _BreakdownDialog());
    if (reason == null) {
      return;
    }

    try {
      await ref.read(equipmentRepositoryProvider).reportBreakdown(equipmentId, reason);
      ref.invalidate(equipmentProvider);
      ref.invalidate(breakdownsProvider(equipmentId));
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  Future<void> _setStatus(BuildContext context, WidgetRef ref, EquipmentStatus status) async {
    try {
      await ref.read(equipmentRepositoryProvider).update(equipmentId, {'status': status.apiValue});
      ref.invalidate(equipmentProvider);
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final canManage = ref.watch(sessionProvider).value?.can(Permissions.equipmentManage) ?? false;
    final canApprove = ref.watch(sessionProvider).value?.can(Permissions.expensesApprove) ?? false;
    final equipment = ref.watch(equipmentProvider).value?.where((item) => item.id == equipmentId).firstOrNull;
    if (equipment == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ref.watch(equipmentProvider).hasError
            ? ErrorView(error: ref.watch(equipmentProvider).error!, onRetry: () => ref.invalidate(equipmentProvider))
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final date = MaterialLocalizations.of(context).formatMediumDate;
    final due = maintenanceDueLabel(l10n, equipment);
    final history = ref.watch(maintenancesProvider(equipmentId));
    final breakdowns = ref.watch(breakdownsProvider(equipmentId)).value ?? const <Breakdown>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        actions: [
          if (canManage)
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => EquipmentEditorScreen(equipment: equipment))),
            ),
        ],
      ),
      floatingActionButton: canManage && equipment.status != EquipmentStatus.retired
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => MaintenanceEditorScreen(equipment: equipment))),
              icon: const Icon(Icons.build_outlined),
              label: Text(l10n.recordMaintenance),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(equipmentProvider);
          ref.invalidate(breakdownsProvider(equipmentId));
          return ref.refresh(maintenancesProvider(equipmentId).future);
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(equipmentStatusLabel(l10n, equipment.status)),
                    subtitle: Text(
                      [
                        equipment.branchName,
                        if (equipment.breakdownReason != null) equipment.breakdownReason!,
                      ].join('\n'),
                    ),
                  ),
                  if (canManage)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (equipment.status == EquipmentStatus.inService)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.report_problem_outlined),
                              label: Text(l10n.reportBreakdown),
                              onPressed: () => _reportBreakdown(context, ref),
                            ),
                          if (equipment.status == EquipmentStatus.outOfService)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.backInService),
                              onPressed: () => _setStatus(context, ref, EquipmentStatus.inService),
                            ),
                          if (equipment.status == EquipmentStatus.retired)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.restore),
                              label: Text(l10n.returnToService),
                              onPressed: () => _setStatus(context, ref, EquipmentStatus.inService),
                            )
                          else
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                              icon: const Icon(Icons.block),
                              label: Text(l10n.retireEquipment),
                              onPressed: () => _confirmStatus(
                                context,
                                ref,
                                EquipmentStatus.retired,
                                title: l10n.retireEquipment,
                                explanation: l10n.retireEquipmentExplained,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ListTile(
                    leading: Icon(
                      Icons.event_repeat_outlined,
                      color: equipment.isDue ? Theme.of(context).colorScheme.error : null,
                    ),
                    title: Text(
                      equipment.maintenanceIntervalDays == null
                          ? l10n.noPeriodicMaintenance
                          : l10n.maintenanceEvery(equipment.maintenanceIntervalDays!),
                    ),
                    subtitle: equipment.nextMaintenanceOn == null
                        ? null
                        : Text(
                            '${l10n.nextMaintenance}: ${date(equipment.nextMaintenanceOn!)}${due == null ? '' : ' · $due'}',
                            style: equipment.isDue ? TextStyle(color: Theme.of(context).colorScheme.error) : null,
                          ),
                  ),
                  if (equipment.serialNumber != null)
                    ListTile(
                      leading: const Icon(Icons.tag),
                      title: Text(l10n.serialNumberField),
                      trailing: Text(equipment.serialNumber!),
                    ),
                  if (equipment.purchasedOn != null || equipment.purchaseCost != null)
                    ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(l10n.purchaseSection),
                      subtitle: Text(
                        [
                          if (equipment.purchasedOn != null) date(equipment.purchasedOn!),
                          if (equipment.purchaseCost != null) money.format(equipment.purchaseCost!),
                        ].join(' · '),
                      ),
                    ),
                  if (equipment.notes != null)
                    ListTile(leading: const Icon(Icons.notes), title: Text(equipment.notes!)),
                ],
              ),
            ),
            if (breakdowns.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(l10n.breakdownHistory, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final breakdown in breakdowns)
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: Text(breakdown.reason),
                  subtitle: Text('${date(breakdown.reportedAt.toLocal())} · ${breakdown.reportedBy}'),
                ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l10n.maintenanceHistory, style: Theme.of(context).textTheme.titleMedium),
            ),
            switch (history) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noMaintenanceYet, textAlign: TextAlign.center),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final maintenance in value)
                    ListTile(
                      leading: Icon(
                        maintenance.kind == MaintenanceKind.periodic ? Icons.event_repeat : Icons.handyman_outlined,
                      ),
                      title: Text(
                        maintenance.kind == MaintenanceKind.periodic
                            ? l10n.periodicMaintenance
                            : l10n.repairMaintenance,
                        style: maintenance.isCancelled
                            ? TextStyle(decoration: TextDecoration.lineThrough, color: Theme.of(context).disabledColor)
                            : null,
                      ),
                      subtitle: Text(
                        [
                          date(maintenance.performedOn),
                          ?maintenance.description,
                          ?maintenance.supplierName,
                          maintenance.createdBy,
                          if (maintenance.isCancelled)
                            maintenance.cancelledBy == null
                                ? l10n.appointmentCancelled
                                : l10n.issueCancelledBy(maintenance.cancelledBy!),
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (maintenance.cost > 0)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(money.format(maintenance.cost)),
                                if (!maintenance.isPaid && !maintenance.isCancelled)
                                  Text(
                                    l10n.notPaidYet,
                                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                                  ),
                              ],
                            ),
                          // Already paid, it takes money back out of the books, which needs the right to approve.
                          if (canManage &&
                              !maintenance.isCancelled &&
                              (maintenance.cost == 0 || !maintenance.isPaid || canApprove))
                            IconButton(
                              tooltip: l10n.cancelMaintenance,
                              icon: const Icon(Icons.undo),
                              onPressed: () => _cancelMaintenance(context, ref, maintenance.id),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(maintenancesProvider(equipmentId)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Asks why the equipment broke, and returns the reason when confirmed.
class _BreakdownDialog extends StatefulWidget {
  const _BreakdownDialog();

  @override
  State<_BreakdownDialog> createState() => _BreakdownDialogState();
}

class _BreakdownDialogState extends State<_BreakdownDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reason = _reason.text.trim();

    return AlertDialog(
      title: Text(l10n.reportBreakdown),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.reportBreakdownExplained),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLength: 255,
            decoration: InputDecoration(labelText: l10n.breakdownReasonField),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.back)),
        FilledButton(
          onPressed: reason.isEmpty ? null : () => Navigator.of(context).pop(reason),
          child: Text(l10n.confirmAction),
        ),
      ],
    );
  }
}
