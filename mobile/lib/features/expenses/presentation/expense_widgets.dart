import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/expense.dart';

String paymentMethodLabel(AppLocalizations l10n, ExpensePaymentMethod? method) => switch (method) {
  ExpensePaymentMethod.cashDrawer => l10n.payFromDrawer,
  ExpensePaymentMethod.cash => l10n.payCash,
  ExpensePaymentMethod.bankTransfer => l10n.payBankTransfer,
  ExpensePaymentMethod.card => l10n.payCard,
  null => l10n.notPaidYet,
};

String frequencyLabel(AppLocalizations l10n, RecurrenceFrequency frequency) => switch (frequency) {
  RecurrenceFrequency.weekly => l10n.frequencyWeekly,
  RecurrenceFrequency.monthly => l10n.frequencyMonthly,
  RecurrenceFrequency.yearly => l10n.frequencyYearly,
};

/// The default category for materials ("Cleaning supplies" or the Arabic default), if the car wash still has one.
ExpenseCategory? materialsCategory(List<ExpenseCategory> categories) =>
    categories.where((category) => isMaterialsCategory(category.name)).firstOrNull;

bool isMaterialsCategory(String name) => name.contains('مواد') || name.toLowerCase().contains('suppl');

/// The message to show for a failed change: the first field error, or the general one.
String changeError(BuildContext context, Object error, StackTrace stackTrace) {
  final problem = ApiProblem.from(error, stackTrace);
  return problem.errors.values.firstOrNull?.first ?? problemMessage(context, problem);
}

/// A money field that accepts Arabic digits and separators.
class AmountField extends ConsumerWidget {
  const AmountField({super.key, required this.controller, required this.label, this.onChanged});

  final TextEditingController controller;
  final String label;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyFormatProvider);
    final l10n = AppLocalizations.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
      decoration: InputDecoration(labelText: label, suffixText: money.currency),
      validator: (value) {
        final amount = money.parse(value ?? '');
        if (value == null || value.trim().isEmpty) {
          return l10n.fieldRequired;
        }
        return amount == null || amount <= 0 ? l10n.amountInvalid(money.toInput(2500)) : null;
      },
      onChanged: onChanged == null ? null : (_) => onChanged!(),
    );
  }
}

/// Asks how an owed expense is paid; pops with the method, or null when cancelled.
Future<ExpensePaymentMethod?> askPaymentMethod(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<ExpensePaymentMethod>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.payExpense),
      children: [
        for (final method in ExpensePaymentMethod.values)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(method),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(paymentMethodLabel(l10n, method)),
            ),
          ),
      ],
    ),
  );
}
