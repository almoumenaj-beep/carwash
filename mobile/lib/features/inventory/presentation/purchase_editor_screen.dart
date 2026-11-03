import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';

/// Records materials received at [branchId]: the lines (material, quantity, cost per unit), the supplier,
/// and how it was paid, or left owed. Pops with true once saved.
class PurchaseEditorScreen extends ConsumerWidget {
  const PurchaseEditorScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsProvider(branchId));
    final suppliers = ref.watch(suppliersProvider);
    final categories = ref.watch(expenseCategoriesProvider);

    return switch ((items, suppliers, categories)) {
      (AsyncData(value: final items), AsyncData(value: final suppliers), AsyncData(value: final categories)) =>
        _PurchaseForm(
          branchId: branchId,
          items: items.where((item) => item.isActive).toList(),
          suppliers: suppliers.where((supplier) => supplier.isActive).toList(),
          categories: categories.where((category) => category.isActive).toList(),
        ),
      (AsyncError(:final error), _, _) ||
      (_, AsyncError(:final error), _) ||
      (_, _, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(inventoryItemsProvider(branchId));
            ref.invalidate(suppliersProvider);
            ref.invalidate(expenseCategoriesProvider);
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

/// One line being entered: the material and the typed quantity and cost.
class _Line {
  _Line(this.item, {int unitCost = 0, required String costText})
    : quantity = TextEditingController(),
      cost = TextEditingController(text: unitCost > 0 ? costText : '');

  final InventoryItem item;
  final TextEditingController quantity;
  final TextEditingController cost;

  void dispose() {
    quantity.dispose();
    cost.dispose();
  }
}

class _PurchaseForm extends ConsumerStatefulWidget {
  const _PurchaseForm({required this.branchId, required this.items, required this.suppliers, required this.categories});

  final String branchId;
  final List<InventoryItem> items;
  final List<Supplier> suppliers;
  final List<ExpenseCategory> categories;

  @override
  ConsumerState<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends ConsumerState<_PurchaseForm> {
  final List<_Line> _lines = [];
  final _note = TextEditingController();
  String? _supplierId;
  late String? _categoryId = widget.categories.firstOrNull?.id;

  /// Null records the purchase as owed to the supplier.
  ExpensePaymentMethod? _method;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  void _addLine(InventoryItem item) {
    final money = ref.read(moneyFormatProvider);
    setState(() => _lines.add(_Line(item, unitCost: item.unitCost, costText: money.toInput(item.unitCost))));
  }

  /// The total of the lines typed so far, rounded like the server; null when a line cannot be read.
  int? _total(MoneyFormat money) {
    var total = 0;
    for (final line in _lines) {
      final quantity = parseQuantity(line.quantity.text);
      final cost = money.parse(line.cost.text);
      if (quantity == null || cost == null) {
        return null;
      }
      total += (quantity * cost).round();
    }
    return total;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    if (_lines.isEmpty || _total(money) == null || _categoryId == null) {
      setState(() => _error = _lines.isEmpty ? l10n.addAtLeastOneMaterial : l10n.quantityInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _note.text.trim();
    try {
      await ref.read(inventoryRepositoryProvider).recordPurchase({
        'branch_id': widget.branchId,
        'supplier_id': _supplierId,
        'expense_category_id': _categoryId,
        'payment_method': _method?.apiValue,
        if (note.isNotEmpty) 'note': note,
        'lines': [
          for (final line in _lines)
            {
              'inventory_item_id': line.item.id,
              'quantity': parseQuantity(line.quantity.text),
              'unit_cost': money.parse(line.cost.text),
            },
        ],
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
    final money = ref.watch(moneyFormatProvider);
    final total = _total(money);
    final available = widget.items.where((item) => !_lines.any((line) => line.item.id == item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPurchase)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _supplierId,
            decoration: InputDecoration(labelText: l10n.supplierField),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.noSupplier)),
              for (final supplier in widget.suppliers) DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
            ],
            onChanged: (id) => setState(() => _supplierId = id),
          ),
          const SizedBox(height: 16),
          Text(l10n.materialsSection, style: theme.textTheme.titleSmall),
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(line.item.name)),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: line.quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.quantityField,
                        suffixText: line.item.unit,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: line.cost,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.unitPriceField, isDense: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _lines.remove(line);
                      line.dispose();
                    }),
                  ),
                ],
              ),
            ),
          if (available.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PopupMenuButton<InventoryItem>(
                onSelected: _addLine,
                itemBuilder: (_) => [for (final item in available) PopupMenuItem(value: item, child: Text(item.name))],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.addMaterialLine, style: TextStyle(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            )
          else if (widget.items.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l10n.noMaterials)),
          const Divider(height: 24),
          Text(l10n.paymentMethodField, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final method in [null, ...ExpensePaymentMethod.values])
                ChoiceChip(
                  label: Text(paymentMethodLabel(l10n, method)),
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: InputDecoration(labelText: l10n.expenseCategory, helperText: l10n.purchaseCategoryHint),
            items: [
              for (final category in widget.categories)
                DropdownMenuItem(value: category.id, child: Text(category.name)),
            ],
            onChanged: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: InputDecoration(labelText: l10n.notesField),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.orderTotal}: ${total == null ? '—' : money.format(total)}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
