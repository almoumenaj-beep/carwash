import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/money_method_label.dart';
import '../../../core/money/percent_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../memberships/data/memberships_repository.dart';
import '../../memberships/domain/membership.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/domain/app_settings.dart';
import '../../shifts/data/shifts_repository.dart';
import '../data/orders_repository.dart';
import '../domain/checkout_totals.dart';
import '../domain/order.dart';
import 'order_widgets.dart';

/// Takes payment for an order: the services and total with VAT, a discount within the cashier's limit, and cash
/// (with the amount received and the change), card or Benefit. Card and Benefit are recorded by hand once the cashier
/// has confirmed the money arrived. A ready car can be handed over in the same step.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    final settings = ref.watch(settingsProvider);

    return switch ((order, settings)) {
      (AsyncData(value: final order), AsyncData(value: final settings)) => _CheckoutForm(
        order: order,
        vatRateBps: (settings.vatRate * 100).round(),
        pricesIncludeVat: settings.pricesIncludeVat,
        points: settings.pointsEnabled ? settings : null,
        membershipsOn: settings.membershipsEnabled,
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(orderProvider(orderId));
            ref.invalidate(settingsProvider);
          },
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _CheckoutForm extends ConsumerStatefulWidget {
  const _CheckoutForm({
    required this.order,
    required this.vatRateBps,
    required this.pricesIncludeVat,
    required this.points,
    required this.membershipsOn,
  });

  final Order order;
  final int vatRateBps;
  final bool pricesIncludeVat;

  /// The points rules; null while points are off.
  final AppSettings? points;
  final bool membershipsOn;

  @override
  ConsumerState<_CheckoutForm> createState() => _CheckoutFormState();
}

class _CheckoutFormState extends ConsumerState<_CheckoutForm> {
  final _discount = TextEditingController();
  final _reason = TextEditingController();
  final _tendered = TextEditingController();
  String _discountType = 'percent';
  String _method = 'cash';
  int _redeemSteps = 0;
  String? _membershipId;
  int _membershipPrice = 0;
  bool _saving = false;
  ApiProblem? _problem;

  @override
  void dispose() {
    _discount.dispose();
    _reason.dispose();
    _tendered.dispose();
    super.dispose();
  }

  /// The typed discount in the server's units, or null when it cannot be read.
  int? _discountValue(MoneyFormat money) {
    final text = _discount.text.trim();
    if (text.isEmpty) {
      return 0;
    }
    return _discountType == 'amount' ? money.parse(text) : PercentFormat.parse(text);
  }

  bool get _redeeming => _redeemSteps > 0;

  bool get _usingMembership => _membershipId != null;

  /// Points and memberships replace the cashier's discount, and need no discount limit or reason.
  bool get _specialDiscount => _redeeming || _usingMembership;

  /// What a membership would take off this order, like the server: the dearest service it covers. Null when it
  /// cannot be used here.
  int? _membershipValue(CustomerMembership membership) {
    if (!membership.isUsable || (membership.vehicleId != null && membership.vehicleId != widget.order.vehicleId)) {
      return null;
    }
    final prices = [
      for (final item in widget.order.items)
        if (membership.serviceIds.contains(item.serviceId) && item.unitPrice > 0) item.unitPrice,
    ];
    return prices.isEmpty ? null : prices.reduce((dearest, price) => price > dearest ? price : dearest);
  }

  /// How many steps of the points rate this customer can spend on this order: never more than they hold or the
  /// order is worth.
  int get _maxRedeemSteps {
    final points = widget.points;
    final balance = widget.order.customer?.pointsBalance;
    if (points == null || balance == null) {
      return 0;
    }
    final affordable = balance ~/ points.pointsRedeemPoints;
    final worthwhile = widget.order.subtotal ~/ points.pointsRedeemValue;
    return affordable < worthwhile ? affordable : worthwhile;
  }

  CheckoutTotals _totals(MoneyFormat money) {
    final value = _discountValue(money) ?? 0;
    return CheckoutTotals.of(
      subtotal: widget.order.subtotal,
      discountAmount: _usingMembership
          ? _membershipPrice
          : (_redeeming ? _redeemSteps * widget.points!.pointsRedeemValue : (_discountType == 'amount' ? value : 0)),
      discountPercentBps: !_specialDiscount && _discountType == 'percent' ? value : null,
      vatRateBps: widget.vatRateBps,
      pricesIncludeVat: widget.pricesIncludeVat,
    );
  }

  Future<void> _pay({required bool deliver}) async {
    final money = ref.read(moneyFormatProvider);
    final totals = _totals(money);
    final isCash = _method == 'cash';
    final tendered = !isCash || _tendered.text.trim().isEmpty ? totals.total : money.parse(_tendered.text);

    setState(() {
      _saving = true;
      _problem = null;
    });

    try {
      final paid = await ref
          .read(ordersRepositoryProvider)
          .checkout(
            widget.order.id,
            discountAmount: !_specialDiscount && totals.discount > 0 && _discountType == 'amount'
                ? totals.discount
                : null,
            discountPercentBps: !_specialDiscount && totals.discount > 0 && _discountType == 'percent'
                ? _discountValue(money)
                : null,
            discountReason: !_specialDiscount && totals.discount > 0 ? _reason.text.trim() : null,
            redeemPoints: _redeeming ? _redeemSteps * widget.points!.pointsRedeemPoints : null,
            membershipId: _membershipId,
            method: _method,
            tendered: isCash ? tendered : null,
            deliver: deliver,
          );
      ref.invalidate(orderProvider(widget.order.id));
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => _PaidDialog(order: paid, pointsOn: widget.points != null),
        );
      }
      if (mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() => _problem = problem);
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
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final me = ref.watch(sessionProvider).value;
    final order = widget.order;
    final totals = _totals(money);
    final limitBps = me?.maxDiscountBps ?? 0;
    final canDiscount = (me?.can(Permissions.posDiscount) ?? false) && limitBps > 0;
    final discountInvalid = _discountValue(money) == null;
    final overLimit = !_specialDiscount && totals.discountBps > limitBps;
    final reasonMissing = !_specialDiscount && totals.discount > 0 && _reason.text.trim().isEmpty;
    final tendered = _tendered.text.trim().isEmpty ? totals.total : money.parse(_tendered.text);
    final nothingToPay = totals.total == 0;
    final isCash = _method == 'cash';
    final points = widget.points;
    final pointsBalance = order.customer?.pointsBalance;
    final shortOfCash = isCash && (tendered == null || tendered < totals.total);
    final canDeliver = order.status == OrderStatus.ready && canMoveTo(ref, OrderStatus.delivered);
    final shift = ref.watch(currentShiftProvider(order.branchId));
    final hasShift = shift.value != null;
    final canPay = hasShift && !_saving && !discountInvalid && !overLimit && !reasonMissing && !shortOfCash;
    final problem = _problem;

    Widget row(String label, String value, {TextStyle? style}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.checkoutTitle} · ${order.reference}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (shift.hasValue && !hasShift)
            Card(
              color: theme.colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.point_of_sale_outlined),
                title: Text(l10n.openShiftFirst),
                trailing: FilledButton(
                  onPressed: () async {
                    await context.push('/shift?branch=${order.branchId}');
                    ref.invalidate(currentShiftProvider(order.branchId));
                  },
                  child: Text(l10n.openShift),
                ),
              ),
            ),
          Text(order.plateNumber, textDirection: TextDirection.ltr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in order.items)
                    row(
                      item.quantity > 1 ? '${item.name} × ${item.quantity}' : item.name,
                      money.format(item.lineTotal),
                    ),
                  const Divider(),
                  row(l10n.subtotalLabel, money.format(totals.subtotal)),
                  if (totals.discount > 0) row(l10n.discountLabel, '- ${money.format(totals.discount)}'),
                  row(
                    widget.pricesIncludeVat
                        ? l10n.vatIncludedLabel(PercentFormat.format(widget.vatRateBps))
                        : l10n.vatAddedLabel(PercentFormat.format(widget.vatRateBps)),
                    money.format(totals.vat),
                  ),
                  const Divider(),
                  row(l10n.orderTotal, money.format(totals.total), style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ),
          if (widget.membershipsOn && order.customer != null)
            for (final membership
                in ref.watch(customerMembershipsProvider(order.customer!.id)).value ?? const <CustomerMembership>[])
              if (_membershipValue(membership) case final value?)
                Card(
                  margin: const EdgeInsets.only(top: 16),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.card_membership_outlined),
                    title: Text(l10n.membershipUse(membership.name)),
                    subtitle: Text(
                      membership.washesLeft == null
                          ? l10n.membershipUnlimited
                          : l10n.membershipWashesLeft(membership.washesLeft!),
                    ),
                    value: _membershipId == membership.id,
                    onChanged: (on) => setState(() {
                      _membershipId = on ? membership.id : null;
                      _membershipPrice = on ? value : 0;
                      _redeemSteps = 0;
                      _discount.clear();
                      _reason.clear();
                    }),
                  ),
                ),
          if (points != null && pointsBalance != null)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.stars_outlined),
                    title: Text(l10n.pointsBalance(pointsBalance)),
                    subtitle: Text(l10n.pointsWillEarn(totals.total ~/ points.pointsEarnAmount)),
                  ),
                  if (_maxRedeemSteps == 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(l10n.pointsNeedMore(points.pointsRedeemPoints), style: theme.textTheme.bodySmall),
                      ),
                    )
                  else if (_discount.text.trim().isEmpty && !_usingMembership)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.pointsRedeemLine(
                                (_redeeming ? _redeemSteps : 1) * points.pointsRedeemPoints,
                                money.format((_redeeming ? _redeemSteps : 1) * points.pointsRedeemValue),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.pointsRedeemLess,
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _redeeming ? () => setState(() => _redeemSteps--) : null,
                          ),
                          Text('$_redeemSteps', style: theme.textTheme.titleMedium),
                          IconButton(
                            tooltip: l10n.pointsRedeemMore,
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _redeemSteps < _maxRedeemSteps
                                ? () => setState(() {
                                    _redeemSteps++;
                                    _reason.clear();
                                  })
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (canDiscount && !_specialDiscount) ...[
            const SizedBox(height: 16),
            Text(l10n.discountLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                SegmentedButton<String>(
                  segments: [
                    const ButtonSegment(value: 'percent', label: Text('%')),
                    ButtonSegment(value: 'amount', label: Text(money.currency)),
                  ],
                  selected: {_discountType},
                  onSelectionChanged: (selection) => setState(() {
                    _discountType = selection.single;
                    _discount.clear();
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _discount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: _discountType == 'percent' ? '%' : money.currency,
                      helperText: l10n.discountLimitHint(PercentFormat.format(limitBps)),
                      errorText: discountInvalid
                          ? (_discountType == 'percent' ? l10n.percentInvalid : l10n.amountInvalid(money.toInput(2500)))
                          : (overLimit ? l10n.discountOverLimit(PercentFormat.format(limitBps)) : null),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (totals.discount > 0) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: l10n.discountReasonField,
                  errorText: reasonMissing ? l10n.fieldRequired : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
          const SizedBox(height: 16),
          if (!nothingToPay) ...[
            Text(l10n.paymentMethodField, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  for (final method in const ['cash', 'card', 'benefit'])
                    ButtonSegment(value: method, label: Text(moneyMethodLabel(l10n, method))),
                ],
                selected: {_method},
                onSelectionChanged: (selection) => setState(() => _method = selection.single),
              ),
            ),
            const SizedBox(height: 16),
            if (!isCash)
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_method == 'card' ? l10n.cardPaymentHint : l10n.benefitPaymentHint)),
                ],
              ),
            if (isCash) ...[
              Text(l10n.cashReceivedField, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _tendered,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
                decoration: InputDecoration(
                  hintText: money.toInput(totals.total),
                  suffixText: money.currency,
                  errorText: shortOfCash ? l10n.cashTooLittle : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final note in _cashSuggestions(totals.total, money))
                    ActionChip(
                      label: Text(money.formatNumber(note)),
                      onPressed: () => setState(() => _tendered.text = money.toInput(note)),
                    ),
                ],
              ),
              if (tendered != null && tendered > totals.total) ...[
                const SizedBox(height: 12),
                Text(l10n.changeDue(money.format(tendered - totals.total)), style: theme.textTheme.titleMedium),
              ],
            ],
          ],
          if (problem != null) ...[
            const SizedBox(height: 12),
            Text(
              problem.errors.isEmpty
                  ? problemMessage(context, problem)
                  : problem.errors.values.map((messages) => messages.first).toSet().join('\n'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: canDeliver
                    ? OutlinedButton(onPressed: canPay ? () => _pay(deliver: false) : null, child: Text(l10n.payOnly))
                    : FilledButton.icon(
                        onPressed: canPay ? () => _pay(deliver: false) : null,
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(l10n.collectPayment),
                      ),
              ),
              if (canDeliver) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canPay ? () => _pay(deliver: true) : null,
                    icon: const Icon(Icons.key_outlined),
                    label: Text(l10n.payAndDeliver),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The exact amount and the next round notes above it (1, 5, 10 and 20 in the main unit), for quick entry.
List<int> _cashSuggestions(int total, MoneyFormat money) {
  final unit = money.parse('1') ?? 1000;
  final suggestions = <int>{total};
  for (final note in [1, 5, 10, 20]) {
    final step = note * unit;
    final rounded = ((total + step - 1) ~/ step) * step;
    if (rounded > total) {
      suggestions.add(rounded);
    }
  }
  return suggestions.take(4).toList();
}

class _PaidDialog extends ConsumerWidget {
  const _PaidDialog({required this.order, required this.pointsOn});

  final Order order;
  final bool pointsOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final invoice = order.invoice;

    return AlertDialog(
      icon: const Icon(Icons.check_circle_outline, size: 48),
      title: Text(l10n.paidTitle),
      content: invoice == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(invoice.reference),
                const SizedBox(height: 8),
                Text(money.format(invoice.total), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('${l10n.paymentMethodField}: ${moneyMethodLabel(l10n, invoice.paymentMethod)}'),
                if (invoice.changeGiven > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.changeDue(money.format(invoice.changeGiven)),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                if (order.status == OrderStatus.delivered) ...[const SizedBox(height: 8), Text(l10n.statusDelivered)],
                if (pointsOn && order.customer != null) ...[
                  const SizedBox(height: 8),
                  Text(l10n.pointsEarnedNow(invoice.pointsEarned, order.customer!.pointsBalance)),
                ],
              ],
            ),
      actions: [
        if (order.status == OrderStatus.ready || order.status == OrderStatus.delivered)
          OrderWhatsAppButton(order: order),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.done)),
      ],
    );
  }
}
