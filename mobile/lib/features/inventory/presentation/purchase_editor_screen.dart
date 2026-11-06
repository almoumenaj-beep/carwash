import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';

/// Records materials received at [branchId]: each material is chosen with its quantity and unit price and added to a
/// list, with the supplier and how it was paid, or left owed. Pops with true once saved.
class PurchaseEditorScreen extends ConsumerWidget {
  const PurchaseEditorScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inventoryItemsProvider(branchId));
    final suppliers = ref.watch(suppliersProvider);
    final categories = ref.watch(expenseCategoriesProvider);

    // While a list reloads after something was added from the form, the form stays up with what was typed in it.
    if (items.hasValue && suppliers.hasValue && categories.hasValue) {
      return _PurchaseForm(
        branchId: branchId,
        items: items.requireValue.where((item) => item.isActive).toList(),
        suppliers: suppliers.requireValue.where((supplier) => supplier.isActive).toList(),
        categories: categories.requireValue.where((category) => category.isActive).toList(),
      );
    }

    return switch ((items, suppliers, categories)) {
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
  /// The list's own "new material" entry.
  static const _newMaterialOption = '';

  final List<({InventoryItem item, double quantity, int unitCost})> _lines = [];
  final _quantity = TextEditingController();
  final _cost = TextEditingController();
  String? _materialId;

  /// Rebuilds the material list so it shows what is chosen, after a line or a new material.
  int _materialFieldVersion = 0;

  /// Materials added from this form, until the list reloads with them.
  final List<InventoryItem> _addedItems = [];
  String? _lineError;
  final _note = TextEditingController();
  String? _supplierId;
  late String? _categoryId = materialsCategory(widget.categories)?.id ?? widget.categories.firstOrNull?.id;

  /// Suppliers added from this form, until the list reloads with them.
  final List<Supplier> _addedSuppliers = [];
  int _supplierFieldVersion = 0;

  /// Null records the purchase as owed to the supplier.
  ExpensePaymentMethod? _method;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  List<Supplier> get _suppliers => [
    ...widget.suppliers,
    ..._addedSuppliers.where((added) => !widget.suppliers.any((supplier) => supplier.id == added.id)),
  ];

  /// Adds a supplier by name and phone, and chooses it.
  Future<void> _newSupplier() async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _QuickAddDialog(title: l10n.addSupplier, secondLabel: l10n.phoneField, secondRequired: false),
    );
    if (answer == null || !mounted) {
      return;
    }

    try {
      final supplier = await ref.read(expensesRepositoryProvider).saveSupplier(null, {
        'name': answer.$1,
        'phone': answer.$2.isEmpty ? null : answer.$2,
        'is_active': true,
      });
      ref.invalidate(suppliersProvider);
      setState(() {
        _addedSuppliers.add(supplier);
        _supplierId = supplier.id;
        _supplierFieldVersion++;
      });
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    }
  }

  List<InventoryItem> get _items => [
    ...widget.items,
    ..._addedItems.where((added) => !widget.items.any((item) => item.id == added.id)),
  ];

  /// Adds a material bought for the first time, and chooses it.
  Future<void> _newMaterial() async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _QuickAddDialog(title: l10n.addMaterial, secondLabel: l10n.unitField, secondHint: l10n.unitHint),
    );
    if (!mounted) {
      return;
    }
    if (answer == null) {
      setState(() => _materialFieldVersion++);
      return;
    }

    try {
      final item = await ref.read(inventoryRepositoryProvider).saveItem(null, {
        'name': answer.$1,
        'unit': answer.$2,
        'is_active': true,
      });
      ref.invalidate(inventoryItemsProvider);
      setState(() {
        _addedItems.add(item);
        _materialId = item.id;
        _materialFieldVersion++;
        _lineError = null;
      });
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _materialFieldVersion++;
          _lineError = changeError(context, error, stackTrace);
        });
      }
    }
  }

  /// Moves the chosen material, quantity and price to the list; false, with the reason shown, when they are not valid.
  bool _addLine() {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    final item = _items.where((item) => item.id == _materialId).firstOrNull;
    final quantity = parseQuantity(_quantity.text);
    final cost = money.parse(_cost.text);

    final problem = item == null
        ? l10n.chooseMaterialFirst
        : (quantity == null || quantity <= 0)
        ? l10n.quantityInvalid
        : cost == null
        ? l10n.amountInvalid(money.toInput(2500))
        : null;
    if (problem != null) {
      setState(() => _lineError = problem);
      return false;
    }

    setState(() {
      _lines.add((item: item!, quantity: quantity!, unitCost: cost!));
      _materialId = null;
      _quantity.clear();
      _cost.clear();
      _materialFieldVersion++;
      _lineError = null;
    });
    return true;
  }

  int _lineTotal(({InventoryItem item, double quantity, int unitCost}) line) => (line.quantity * line.unitCost).round();

  /// The total of the list, rounded like the server.
  int get _total => _lines.fold(0, (total, line) => total + _lineTotal(line));

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    // A material being entered but not added yet is what the user means to buy too.
    final entering = _materialId != null || _quantity.text.trim().isNotEmpty || _cost.text.trim().isNotEmpty;
    if (entering && !_addLine()) {
      return;
    }
    if (_lines.isEmpty || _categoryId == null) {
      setState(() => _error = l10n.addAtLeastOneMaterial);
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
            {'inventory_item_id': line.item.id, 'quantity': line.quantity, 'unit_cost': line.unitCost},
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
    final available = _items.where((item) => !_lines.any((line) => line.item.id == item.id)).toList();
    final chosen = available.where((item) => item.id == _materialId).firstOrNull;
    final canAddMaterial = ref.watch(sessionProvider).value?.can(Permissions.inventoryAdjust) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPurchase)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String?>(
            key: ValueKey(_supplierFieldVersion),
            initialValue: _supplierId,
            decoration: InputDecoration(labelText: l10n.supplierField),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.noSupplier)),
              for (final supplier in _suppliers) DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
            ],
            onChanged: (id) => setState(() => _supplierId = id),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _newSupplier,
              icon: const Icon(Icons.add),
              label: Text(l10n.newSupplierButton),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.materialsSection, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('material-$_materialFieldVersion'),
                  initialValue: chosen?.id,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.materialField),
                  items: [
                    for (final item in available)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    if (canAddMaterial)
                      DropdownMenuItem(
                        value: _newMaterialOption,
                        child: Text(
                          l10n.newMaterialOption,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                  ],
                  onChanged: (id) {
                    if (id == _newMaterialOption) {
                      _newMaterial();
                    } else {
                      setState(() {
                        _materialId = id;
                        _lineError = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.quantityField,
                    suffixText: chosen?.unit,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.unitPriceField,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ),
            ],
          ),
          if (_lineError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_lineError!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: Text(l10n.addToList),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.purchaseListSection(_lines.length), style: theme.textTheme.titleSmall),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.purchaseListEmpty, style: theme.textTheme.bodySmall),
            )
          else
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (final line in _lines)
                    ListTile(
                      dense: true,
                      title: Text(line.item.name),
                      subtitle: Text(
                        '${formatQuantity(line.quantity)} ${line.item.unit} × ${money.format(line.unitCost)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(money.format(_lineTotal(line))),
                          IconButton(
                            tooltip: l10n.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => setState(() => _lines.remove(line)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
              Expanded(child: Text('${l10n.orderTotal}: ${money.format(_total)}', style: theme.textTheme.titleMedium)),
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

/// Asks for a name and one more detail, without leaving the purchase; pops with both, trimmed.
class _QuickAddDialog extends StatefulWidget {
  const _QuickAddDialog({required this.title, required this.secondLabel, this.secondHint, this.secondRequired = true});

  final String title;
  final String secondLabel;
  final String? secondHint;
  final bool secondRequired;

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  final _name = TextEditingController();
  final _second = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _name.dispose();
    _second.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final second = _second.text.trim();
    if (name.isEmpty || (widget.secondRequired && second.isEmpty)) {
      setState(() => _missing = true);
      return;
    }
    Navigator.of(context).pop((name, second));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.nameField),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _second,
            decoration: InputDecoration(labelText: widget.secondLabel, hintText: widget.secondHint),
          ),
          if (_missing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.fieldRequired, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
