import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/money/money_method_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/orders_repository.dart';

/// Asks for the reason, says what will happen, and gives back a whole invoice. Pops true once done.
class RefundDialog extends ConsumerStatefulWidget {
  const RefundDialog({super.key, required this.invoiceId, required this.amount, required this.method});

  final String invoiceId;

  /// Minor units.
  final int amount;
  final String method;

  @override
  ConsumerState<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends ConsumerState<RefundDialog> {
  final _reason = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _refund() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(ordersRepositoryProvider).refund(widget.invoiceId, _reason.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
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
    final colors = Theme.of(context).colorScheme;
    final money = ref.watch(moneyFormatProvider);

    return AlertDialog(
      title: Text(l10n.refundTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.amount == 0
                  ? l10n.refundNothingToPay
                  : l10n.refundAmountBy(money.format(widget.amount), moneyMethodLabel(l10n, widget.method)),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(widget.method == 'cash' && widget.amount > 0 ? l10n.refundCashHint : l10n.refundHint),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              autofocus: true,
              maxLength: 255,
              decoration: InputDecoration(labelText: l10n.refundReasonField),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.back)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: _saving || _reason.text.trim().isEmpty ? null : _refund,
          child: Text(l10n.refundTitle),
        ),
      ],
    );
  }
}
