import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/money_method_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../customers/domain/customer.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/memberships_repository.dart';
import '../domain/membership.dart';

/// A customer's memberships on their page: what is left of each, selling a new one, and stopping one.
class CustomerMembershipsCard extends ConsumerWidget {
  const CustomerMembershipsCard({super.key, required this.customer});

  final Customer customer;

  Future<void> _stop(BuildContext context, WidgetRef ref, CustomerMembership membership) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.membershipStop),
        content: Text(l10n.membershipStopExplained),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.back)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.membershipStop)),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(membershipsRepositoryProvider).cancel(membership.id);
      ref.invalidate(customerMembershipsProvider(customer.id));
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(sessionProvider).value;
    final canSell = me?.can(Permissions.posCheckout) ?? false;
    final canStop = (me?.can(Permissions.posCloseShift) ?? false) && (me?.can(Permissions.reportsSales) ?? false);
    final memberships = ref.watch(customerMembershipsProvider(customer.id)).value ?? const <CustomerMembership>[];
    final date = MaterialLocalizations.of(context).formatMediumDate;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: Text(l10n.membershipsTitle),
            trailing: canSell
                ? TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l10n.membershipSell),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _SellDialog(customer: customer),
                    ),
                  )
                : null,
          ),
          for (final membership in memberships)
            ListTile(
              textColor: membership.isUsable ? null : theme.disabledColor,
              title: Text(membership.name),
              subtitle: Text(
                [
                  membership.washesLeft == null
                      ? l10n.membershipUnlimited
                      : l10n.membershipWashesLeft(membership.washesLeft!),
                  if (membership.isCancelled)
                    l10n.membershipStopped
                  else
                    l10n.membershipUntil(date(membership.expiresAt.toLocal())),
                  ?membership.plateNumber,
                ].join(' · '),
              ),
              trailing: canStop && membership.isUsable
                  ? IconButton(
                      tooltip: l10n.membershipStop,
                      icon: const Icon(Icons.block),
                      onPressed: () => _stop(context, ref, membership),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _SellDialog extends ConsumerStatefulWidget {
  const _SellDialog({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_SellDialog> createState() => _SellDialogState();
}

class _SellDialogState extends ConsumerState<_SellDialog> {
  MembershipPlan? _plan;
  String? _branchId;
  String? _vehicleId;
  String _method = 'cash';
  bool _saving = false;
  String? _error;

  Future<void> _sell(String branchId) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(membershipsRepositoryProvider)
          .sell(
            widget.customer.id,
            planId: _plan!.id,
            branchId: branchId,
            method: _method,
            vehicleId: _plan!.forOneCar ? _vehicleId : null,
          );
      ref.invalidate(customerMembershipsProvider(widget.customer.id));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final plans = (ref.watch(membershipPlansProvider).value ?? const <MembershipPlan>[])
        .where((plan) => plan.isActive)
        .toList();
    final branches = ref.watch(sessionProvider).value?.branches ?? const [];
    final branchId = _branchId ?? (branches.isEmpty ? null : branches.first.id);
    final plan = _plan;
    final needsCar = plan != null && plan.forOneCar && _vehicleId == null;

    return AlertDialog(
      title: Text(l10n.membershipSell),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (plans.isEmpty) Text(l10n.noMembershipPlans),
            DropdownButtonFormField<MembershipPlan>(
              initialValue: plan,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.membershipsTitle),
              items: [
                for (final option in plans)
                  DropdownMenuItem(value: option, child: Text('${option.name} · ${money.format(option.price)}')),
              ],
              onChanged: (value) => setState(() => _plan = value),
            ),
            if (plan != null && plan.forOneCar) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _vehicleId,
                decoration: InputDecoration(labelText: l10n.membershipCarField),
                items: [
                  for (final vehicle in widget.customer.vehicles)
                    DropdownMenuItem(value: vehicle.id, child: Text(vehicle.plateNumber)),
                ],
                onChanged: (value) => setState(() => _vehicleId = value),
              ),
            ],
            if (branches.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: branchId,
                decoration: InputDecoration(labelText: l10n.branchesSection),
                items: [for (final branch in branches) DropdownMenuItem(value: branch.id, child: Text(branch.name))],
                onChanged: (value) => setState(() => _branchId = value),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.paymentMethodField, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final method in const ['cash', 'card', 'benefit'])
                  ButtonSegment(value: method, label: Text(moneyMethodLabel(l10n, method))),
              ],
              selected: {_method},
              onSelectionChanged: (selection) => setState(() => _method = selection.single),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _saving || plan == null || needsCar || branchId == null ? null : () => _sell(branchId),
          child: Text(l10n.membershipSell),
        ),
      ],
    );
  }
}
