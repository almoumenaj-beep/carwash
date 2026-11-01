import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';

String statusLabel(AppLocalizations l10n, OrderStatus status) => switch (status) {
  OrderStatus.waiting => l10n.statusWaiting,
  OrderStatus.inProgress => l10n.statusInProgress,
  OrderStatus.qualityCheck => l10n.statusQualityCheck,
  OrderStatus.ready => l10n.statusReady,
  OrderStatus.delivered => l10n.statusDelivered,
  OrderStatus.cancelled => l10n.statusCancelled,
};

/// The button text for moving an order from [current] to [next].
String actionLabel(AppLocalizations l10n, OrderStatus current, OrderStatus next) => switch (next) {
  OrderStatus.waiting => l10n.actionBackToWaiting,
  OrderStatus.inProgress => current == OrderStatus.waiting ? l10n.actionStart : l10n.actionBackToWashing,
  OrderStatus.qualityCheck => l10n.actionQualityCheck,
  OrderStatus.ready => l10n.actionReady,
  OrderStatus.delivered => l10n.actionDeliver,
  OrderStatus.cancelled => l10n.cancelOrder,
};

/// Whether the signed-in user may move orders to [next]; cancelling has its own permission.
bool canMoveTo(WidgetRef ref, OrderStatus next) {
  final me = ref.read(sessionProvider).value;
  return me != null &&
      me.can(next == OrderStatus.cancelled ? Permissions.ordersCancel : Permissions.ordersUpdateStatus);
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      OrderStatus.waiting => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      OrderStatus.inProgress || OrderStatus.qualityCheck => (scheme.primaryContainer, scheme.onPrimaryContainer),
      OrderStatus.ready => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      OrderStatus.delivered => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Text(
        statusLabel(AppLocalizations.of(context), status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: foreground),
      ),
    );
  }
}

/// Moves [order] to [next], asking for a reason first when cancelling. Returns the updated order,
/// or null when the user backed out or the server refused (the reason is shown in a snack bar).
Future<Order?> moveOrder(BuildContext context, WidgetRef ref, Order order, OrderStatus next) async {
  String? reason;
  if (next == OrderStatus.cancelled) {
    reason = await showDialog<String>(context: context, builder: (_) => const _CancelReasonDialog());
    if (reason == null) {
      return null;
    }
  }

  Map<String, bool>? checklist;
  if (order.status == OrderStatus.qualityCheck && (next == OrderStatus.ready || next == OrderStatus.inProgress)) {
    if (!context.mounted) {
      return null;
    }
    checklist = await showModalBottomSheet<Map<String, bool>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _InspectionSheet(order: order, passing: next == OrderStatus.ready),
    );
    if (checklist == null) {
      return null;
    }
  }

  try {
    return await ref.read(ordersRepositoryProvider).changeStatus(order.id, next, reason: reason, checklist: checklist);
  } catch (error, stackTrace) {
    final problem = ApiProblem.from(error, stackTrace);
    if (context.mounted) {
      final message = problem.errors.values.firstOrNull?.first ?? problemMessage(context, problem);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    return null;
  }
}

/// The quality check: one tick per service on the order, for "done properly". Passing the car ([passing])
/// needs every service ticked; sending it back records the unticked ones as not done properly.
/// Pops with the results (order item id → done properly), or null when closed.
class _InspectionSheet extends StatefulWidget {
  const _InspectionSheet({required this.order, required this.passing});

  final Order order;
  final bool passing;

  @override
  State<_InspectionSheet> createState() => _InspectionSheetState();
}

class _InspectionSheetState extends State<_InspectionSheet> {
  late final Map<String, bool> _done = {for (final point in widget.order.inspectionPoints) point.id: false};

  bool get _allDone => _done.values.every((done) => done);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.statusQualityCheck} · ${widget.order.plateNumber}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.inspectionHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final point in widget.order.inspectionPoints)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _done[point.id],
                      title: Text(point.name),
                      onChanged: (done) => setState(() => _done[point.id] = done ?? false),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (widget.passing)
              FilledButton.icon(
                onPressed: _allDone ? () => Navigator.of(context).pop(Map.of(_done)) : null,
                icon: const Icon(Icons.verified_outlined),
                label: Text(l10n.passInspection),
              )
            else
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(Map.of(_done)),
                icon: const Icon(Icons.replay),
                label: Text(l10n.actionBackToWashing),
              ),
          ],
        ),
      ),
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.cancelOrder),
      content: TextField(
        controller: _reason,
        autofocus: true,
        maxLength: 255,
        decoration: InputDecoration(labelText: l10n.cancelReasonField),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.keepOrder)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(l10n.cancelOrder),
        ),
      ],
    );
  }
}

/// Chooses the bay a car is washed in; hidden when the branch has no bays.
class BayPicker extends ConsumerWidget {
  const BayPicker({super.key, required this.branchId, required this.value, required this.onChanged});

  final String branchId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bays = ref.watch(branchBaysProvider(branchId)).value ?? const [];
    if (bays.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);

    return DropdownButtonFormField<String?>(
      initialValue: bays.any((bay) => bay.id == value) ? value : null,
      decoration: InputDecoration(labelText: l10n.bayField, prefixIcon: const Icon(Icons.garage_outlined)),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.noBayYet)),
        for (final bay in bays) DropdownMenuItem(value: bay.id, child: Text(bay.name)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Chooses the washers working on a car, from the branch's staff.
class WasherPicker extends ConsumerWidget {
  const WasherPicker({super.key, required this.branchId, required this.selected, required this.onChanged});

  final String branchId;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(branchStaffProvider(branchId)).value ?? const [];
    if (staff.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).washersSection, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final member in staff)
              FilterChip(
                label: Text(member.name),
                selected: selected.contains(member.id),
                onSelected: (on) => onChanged(on ? {...selected, member.id} : ({...selected}..remove(member.id))),
              ),
          ],
        ),
      ],
    );
  }
}

/// Minutes since [since], for "12 min" on the queue.
int minutesSince(DateTime since) {
  final minutes = DateTime.now().difference(since).inMinutes;
  return minutes < 0 ? 0 : minutes;
}
