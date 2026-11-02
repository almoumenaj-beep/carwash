import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';
import 'expense_widgets.dart';

/// Adds a recurring expense ([schedule] null) or edits, pauses or deletes one. Pops with true once changed.
class RecurringExpenseEditorScreen extends ConsumerWidget {
  const RecurringExpenseEditorScreen({super.key, this.schedule});

  final RecurringExpense? schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoriesProvider);
    final suppliers = ref.watch(suppliersProvider);

    return switch ((categories, suppliers)) {
      (AsyncData(value: final categories), AsyncData(value: final suppliers)) => _RecurringForm(
        schedule: schedule,
        categories: categories.where((category) => category.isActive || category.id == schedule?.category.id).toList(),
        suppliers: suppliers.where((supplier) => supplier.isActive || supplier.id == schedule?.supplier?.id).toList(),
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(expenseCategoriesProvider);
            ref.invalidate(suppliersProvider);
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

class _RecurringForm extends ConsumerStatefulWidget {
  const _RecurringForm({required this.schedule, required this.categories, required this.suppliers});

  final RecurringExpense? schedule;
  final List<ExpenseCategory> categories;
  final List<Supplier> suppliers;

  @override
  ConsumerState<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends ConsumerState<_RecurringForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.schedule == null ? '' : ref.read(moneyFormatProvider).toInput(widget.schedule!.amount),
  );
  late final _description = TextEditingController(text: widget.schedule?.description);
  late String? _branchId = widget.schedule?.branchId;
  late String? _categoryId = widget.schedule?.category.id;
  late String? _supplierId = widget.schedule?.supplier?.id;
  late RecurrenceFrequency _frequency = widget.schedule?.frequency ?? RecurrenceFrequency.monthly;
  late DateTime _nextDueOn = widget.schedule?.nextDueOn ?? DateUtils.dateOnly(DateTime.now());
  late bool _active = widget.schedule?.isActive ?? true;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() change) async {
    try {
      await change();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(expensesRepositoryProvider);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;
    final description = _description.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule == null ? l10n.addRecurring : l10n.recurringTab),
        actions: [
          if (widget.schedule != null)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _run(() => repository.deleteRecurring(widget.schedule!.id)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (branches.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: branch?.id,
                decoration: InputDecoration(labelText: l10n.branchesSection),
                items: [for (final option in branches) DropdownMenuItem(value: option.id, child: Text(option.name))],
                onChanged: (id) => setState(() => _branchId = id),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _description,
              maxLength: 255,
              decoration: InputDecoration(labelText: l10n.descriptionField, hintText: l10n.recurringDescriptionHint),
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: l10n.expenseCategory),
              items: [
                for (final category in widget.categories)
                  DropdownMenuItem(value: category.id, child: Text(category.name)),
              ],
              validator: (value) => value == null ? l10n.fieldRequired : null,
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 12),
            AmountField(controller: _amount, label: l10n.amountField),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _supplierId,
              decoration: InputDecoration(labelText: l10n.supplierField),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noSupplier)),
                for (final supplier in widget.suppliers)
                  DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
              ],
              onChanged: (id) => setState(() => _supplierId = id),
            ),
            const SizedBox(height: 16),
            SegmentedButton<RecurrenceFrequency>(
              segments: [
                for (final frequency in RecurrenceFrequency.values)
                  ButtonSegment(value: frequency, label: Text(frequencyLabel(l10n, frequency))),
              ],
              selected: {_frequency},
              onSelectionChanged: (selection) => setState(() => _frequency = selection.single),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.nextDueField),
              trailing: Text(MaterialLocalizations.of(context).formatMediumDate(_nextDueOn)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _nextDueOn,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(DateTime.now().year + 5),
                );
                if (picked != null) {
                  setState(() => _nextDueOn = picked);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.activeSwitch),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: branch == null
                  ? null
                  : () {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      _run(
                        () => repository.saveRecurring(widget.schedule?.id, {
                          'branch_id': branch.id,
                          'expense_category_id': _categoryId,
                          'supplier_id': _supplierId,
                          'amount': ref.read(moneyFormatProvider).parse(_amount.text),
                          'description': description.isEmpty ? null : description,
                          'frequency': _frequency.name,
                          'next_due_on': apiDate(_nextDueOn),
                          'is_active': _active,
                        }),
                      );
                    },
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
