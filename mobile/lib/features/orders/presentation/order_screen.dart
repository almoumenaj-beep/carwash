import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/percent_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/money/money_method_label.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../customers/domain/customer.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'order_widgets.dart';

/// One work order: the car, services and total, the next steps the user may take, and its history.
class OrderScreen extends ConsumerWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    final value = order.value;

    if (value == null) {
      return Scaffold(
        appBar: AppBar(),
        body: order.hasError
            ? ErrorView(error: order.error!, onRetry: () => ref.invalidate(orderProvider(orderId)))
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return _OrderView(order: value);
  }
}

class _OrderView extends ConsumerStatefulWidget {
  const _OrderView({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends ConsumerState<_OrderView> {
  bool _moving = false;

  Future<void> _move(OrderStatus next) async {
    setState(() => _moving = true);
    final moved = await moveOrder(context, ref, widget.order, next);
    if (moved != null) {
      ref.invalidate(orderProvider(widget.order.id));
    }
    if (mounted) {
      setState(() => _moving = false);
    }
  }

  Future<void> _editAssignment() async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AssignmentSheet(order: widget.order),
    );
    if (changed == true) {
      ref.invalidate(orderProvider(widget.order.id));
    }
  }

  String _time(DateTime at) => MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at.toLocal()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final me = ref.watch(sessionProvider).value;
    final order = widget.order;
    final customer = order.customer;
    final canEdit = order.status.isActive && (me?.can(Permissions.ordersUpdate) ?? false);
    final actions = order.allowedNext.where((next) => canMoveTo(ref, next)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(order.reference),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: l10n.assignmentTitle,
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editAssignment,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(orderProvider(order.id).future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(
                  order.plateNumber,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.checkedInBy(order.createdBy.name)} · ${_time(order.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            if (order.cancelReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.cancelledBecause(order.cancelReason!),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(customer == null ? Icons.person_outline : Icons.verified_outlined),
                title: Text(customer == null ? l10n.walkIn : (customer.name ?? formatPhone(customer.phone))),
                subtitle: customer?.name == null
                    ? null
                    : Text(formatPhone(customer!.phone), textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                trailing: customer != null && me != null && canOpen('/customers/${customer.id}', me)
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: customer != null && me != null && canOpen('/customers/${customer.id}', me)
                    ? () => context.push('/customers/${customer.id}')
                    : null,
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final item in order.items) ...[
                    ListTile(
                      dense: true,
                      leading: Icon(
                        item.isPackage
                            ? Icons.redeem_outlined
                            : (item.isAddon ? Icons.add_circle_outline : Icons.local_car_wash_outlined),
                      ),
                      title: Text(item.quantity > 1 ? '${item.name} × ${item.quantity}' : item.name),
                      trailing: Text(money.format(item.lineTotal)),
                    ),
                    for (final component in item.components)
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 16),
                        title: Text(component.name, style: theme.textTheme.bodySmall),
                      ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.orderTotal, style: theme.textTheme.titleMedium),
                    subtitle: order.estimatedMinutes > 0 ? Text(l10n.aboutMinutes(order.estimatedMinutes)) : null,
                    trailing: Text(money.format(order.subtotal), style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.garage_outlined),
                    title: Text(l10n.bayField),
                    trailing: Text(order.bay?.name ?? l10n.noBayYet),
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(l10n.washersSection),
                    subtitle: order.staff.isEmpty
                        ? null
                        : Text(order.staff.map((member) => member.name).join(l10n.listSeparator)),
                  ),
                  if (order.notes != null)
                    ListTile(
                      leading: const Icon(Icons.notes_outlined),
                      title: Text(l10n.notesField),
                      subtitle: Text(order.notes!),
                    ),
                ],
              ),
            ),
            if (order.invoice case final invoice?)
              Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
                  title: Text('${l10n.paidBadge} · ${invoice.reference}'),
                  subtitle: Text(
                    [
                      if (invoice.discountTotal > 0)
                        '${l10n.discountLabel}: ${money.format(invoice.discountTotal)}'
                            '${invoice.discountReason == null ? '' : ' (${invoice.discountReason})'}',
                      '${l10n.vatAddedLabel(PercentFormat.format(invoice.vatRateBps))}: '
                          '${money.format(invoice.vatAmount)}',
                      '${l10n.paymentMethodField}: ${moneyMethodLabel(l10n, invoice.paymentMethod)}',
                      if (invoice.changeGiven > 0) l10n.changeDue(money.format(invoice.changeGiven)),
                    ].join('\n'),
                  ),
                  trailing: Text(money.format(invoice.total), style: theme.textTheme.titleMedium),
                ),
              )
            else if (order.status.isActive && (me?.can(Permissions.posCheckout) ?? false)) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/checkout/${order.id}');
                  ref.invalidate(orderProvider(order.id));
                },
                icon: const Icon(Icons.payments_outlined),
                label: Text(order.status == OrderStatus.ready ? l10n.payAndDeliver : l10n.collectPayment),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final next in actions)
                    if (next == OrderStatus.cancelled)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                        onPressed: _moving ? null : () => _move(next),
                        child: Text(actionLabel(l10n, order.status, next)),
                      )
                    else if (order.status.isForwardTo(next))
                      FilledButton(
                        onPressed: _moving ? null : () => _move(next),
                        child: Text(actionLabel(l10n, order.status, next)),
                      )
                    else
                      OutlinedButton(
                        onPressed: _moving ? null : () => _move(next),
                        child: Text(actionLabel(l10n, order.status, next)),
                      ),
                ],
              ),
            ],
            if (order.qualityChecks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.statusQualityCheck, style: theme.textTheme.titleSmall),
              for (final check in order.qualityChecks.reversed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          leading: Icon(
                            check.passed ? Icons.verified_outlined : Icons.replay,
                            color: check.passed ? theme.colorScheme.primary : theme.colorScheme.error,
                          ),
                          title: Text(check.passed ? l10n.inspectionPassed : l10n.inspectionFailed),
                          subtitle: Text([_time(check.at), ?check.by].join(' · ')),
                        ),
                        for (final result in check.results)
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: Icon(
                              result.passed ? Icons.check_circle_outline : Icons.cancel_outlined,
                              size: 20,
                              color: result.passed ? theme.colorScheme.primary : theme.colorScheme.error,
                            ),
                            title: Text(result.name),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Text(l10n.historyTitle, style: theme.textTheme.titleSmall),
            for (final change in order.history.reversed)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(statusLabel(l10n, change.to)),
                subtitle: Text([_time(change.at), ?change.by, ?change.reason].join(' · ')),
              ),
          ],
        ),
      ),
    );
  }
}

/// Changes the bay, washers and notes of an order still in the wash.
class _AssignmentSheet extends ConsumerStatefulWidget {
  const _AssignmentSheet({required this.order});

  final Order order;

  @override
  ConsumerState<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<_AssignmentSheet> {
  late String? _bayId = widget.order.bay?.id;
  late Set<String> _staffIds = {for (final member in widget.order.staff) member.id};
  late final _notes = TextEditingController(text: widget.order.notes);
  bool _saving = false;
  ApiProblem? _problem;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _problem = null;
    });

    final notes = _notes.text.trim();
    try {
      await ref.read(ordersRepositoryProvider).update(widget.order.id, {
        'bay_id': _bayId,
        'staff_ids': _staffIds.toList(),
        'notes': notes.isEmpty ? null : notes,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() {
          _problem = problem;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _problem;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.assignmentTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            BayPicker(branchId: widget.order.branchId, value: _bayId, onChanged: (id) => setState(() => _bayId = id)),
            const SizedBox(height: 16),
            WasherPicker(
              branchId: widget.order.branchId,
              selected: _staffIds,
              onChanged: (ids) => setState(() => _staffIds = ids),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              maxLines: 2,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l10n.notesField),
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  problem.errors.values.firstOrNull?.first ?? problemMessage(context, problem),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(onPressed: _saving || _staffIds.isEmpty ? null : _save, child: Text(l10n.save)),
          ],
        ),
      ),
    );
  }
}
