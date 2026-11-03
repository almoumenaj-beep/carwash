import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';
import 'expense_categories_screen.dart';
import 'expense_widgets.dart';

/// Records an expense at a branch: paid now (from the till's drawer, in cash, by transfer or card) or left owed.
/// Pops with true once saved.
class ExpenseEditorScreen extends ConsumerWidget {
  const ExpenseEditorScreen({super.key, this.branchId});

  /// The branch to start on; the user's first branch otherwise.
  final String? branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoriesProvider);
    final suppliers = ref.watch(suppliersProvider);

    return switch ((categories, suppliers)) {
      (AsyncData(value: final categories), AsyncData(value: final suppliers)) => _ExpenseForm(
        branchId: branchId,
        categories: categories.where((category) => category.isActive).toList(),
        suppliers: suppliers.where((supplier) => supplier.isActive).toList(),
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

class _ExpenseForm extends ConsumerStatefulWidget {
  const _ExpenseForm({required this.branchId, required this.categories, required this.suppliers});

  final String? branchId;
  final List<ExpenseCategory> categories;
  final List<Supplier> suppliers;

  @override
  ConsumerState<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late String? _branchId = widget.branchId;
  String? _categoryId;
  String? _supplierId;

  /// Null records the expense as owed.
  ExpensePaymentMethod? _method = ExpensePaymentMethod.cash;
  DateTime _spentOn = DateUtils.dateOnly(DateTime.now());
  bool _saving = false;
  String? _error;

  /// The category list's own "new category" entry.
  static const _newCategory = '';

  /// Categories added from this form, until the list reloads with them.
  final List<ExpenseCategory> _added = [];
  int _categoryFieldVersion = 0;

  List<ExpenseCategory> get _categories => [
    ...widget.categories,
    ..._added.where((added) => !widget.categories.any((category) => category.id == added.id)),
  ];

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Adds a category by name and chooses it.
  Future<void> _addCategory() async {
    final name = await askCategoryName(context);
    if (name != null && name.isNotEmpty && mounted) {
      try {
        final category = await ref.read(expensesRepositoryProvider).saveCategory(null, {'name': name});
        _added.add(category);
        _categoryId = category.id;
        ref.invalidate(expenseCategoriesProvider);
      } catch (error, stackTrace) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
        }
      }
    }
    if (mounted) {
      setState(() => _categoryFieldVersion++);
    }
  }

  Future<void> _save(String branchId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final description = _description.text.trim();
    try {
      await ref.read(expensesRepositoryProvider).record({
        'branch_id': branchId,
        'expense_category_id': _categoryId,
        'supplier_id': _supplierId,
        'amount': ref.read(moneyFormatProvider).parse(_amount.text),
        'spent_on': apiDate(_spentOn),
        'payment_method': _method?.apiValue,
        if (description.isNotEmpty) 'description': description,
      });
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
    final theme = Theme.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;
    final fromDrawer = _method == ExpensePaymentMethod.cashDrawer;
    final canAddCategory = ref.watch(sessionProvider).value?.can(Permissions.expensesApprove) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newExpense)),
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
            DropdownButtonFormField<String>(
              // Rebuilt after "new category" so it shows the category added, or the earlier choice if cancelled.
              key: ValueKey(_categoryFieldVersion),
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: l10n.expenseCategory),
              items: [
                for (final category in _categories) DropdownMenuItem(value: category.id, child: Text(category.name)),
                if (canAddCategory)
                  DropdownMenuItem(
                    value: _newCategory,
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l10n.addCategory, style: TextStyle(color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
              ],
              validator: (value) => value == null || value == _newCategory ? l10n.fieldRequired : null,
              onChanged: (id) => id == _newCategory ? _addCategory() : setState(() => _categoryId = id),
            ),
            const SizedBox(height: 12),
            AmountField(controller: _amount, label: l10n.amountField),
            const SizedBox(height: 16),
            Text(l10n.paymentMethodField, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final method in [...ExpensePaymentMethod.values, null])
                  ChoiceChip(
                    label: Text(paymentMethodLabel(l10n, method)),
                    selected: _method == method,
                    onSelected: (_) => setState(() => _method = method),
                  ),
              ],
            ),
            if (fromDrawer)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.payFromDrawerHint, style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _supplierId,
              decoration: InputDecoration(
                labelText: l10n.supplierField,
                helperText: _method == null ? l10n.owedToSupplierHint : null,
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noSupplier)),
                for (final supplier in widget.suppliers)
                  DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
              ],
              onChanged: (id) => setState(() => _supplierId = id),
            ),
            if (!fromDrawer) ...[
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.expenseDate),
                trailing: Text(MaterialLocalizations.of(context).formatMediumDate(_spentOn)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _spentOn,
                    firstDate: DateTime(2024),
                    lastDate: DateUtils.dateOnly(DateTime.now()),
                  );
                  if (picked != null) {
                    setState(() => _spentOn = picked);
                  }
                },
              ),
            ],
            TextFormField(
              controller: _description,
              maxLength: 255,
              decoration: InputDecoration(labelText: l10n.descriptionField),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving || branch == null ? null : () => _save(branch.id),
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
