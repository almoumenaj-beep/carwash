import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';
import 'purchase_editor_screen.dart';

/// Stock at a branch, with low materials flagged, stock counts and each material's history; and the
/// purchases received there.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String? _branchId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(sessionProvider).value;
    final branches = me?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.inventoryTitle)),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    final canAdjust = me?.can(Permissions.inventoryAdjust) ?? false;
    final canPurchase = me?.can(Permissions.inventoryPurchase) ?? false;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(branches.length > 1 ? '${l10n.inventoryTitle} · ${branch.name}' : l10n.inventoryTitle),
          actions: [
            if (branches.length > 1)
              PopupMenuButton<String>(
                icon: const Icon(Icons.store_outlined),
                initialValue: branch.id,
                onSelected: (id) => setState(() => _branchId = id),
                itemBuilder: (_) => [
                  for (final option in branches) PopupMenuItem(value: option.id, child: Text(option.name)),
                ],
              ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.stockTab),
              Tab(text: l10n.purchasesTab),
            ],
          ),
        ),
        floatingActionButton: canPurchase
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final saved = await Navigator.of(context)
                      .push<bool>(MaterialPageRoute(builder: (_) => PurchaseEditorScreen(branchId: branch.id)));
                  if (saved == true) {
                    ref.invalidate(inventoryItemsProvider);
                    ref.invalidate(purchasesProvider);
                  }
                },
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(l10n.newPurchase),
              )
            : null,
        body: TabBarView(
          children: [
            _Stock(branchId: branch.id, canAdjust: canAdjust),
            _Purchases(branchId: branch.id),
          ],
        ),
      ),
    );
  }
}

class _Stock extends ConsumerWidget {
  const _Stock({required this.branchId, required this.canAdjust});

  final String branchId;
  final bool canAdjust;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(inventoryItemsProvider(branchId));

    Future<void> editItem(InventoryItem? item) async {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _ItemDialog(item: item),
      );
      if (saved == true) {
        ref.invalidate(inventoryItemsProvider);
      }
    }

    return switch (items) {
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(inventoryItemsProvider(branchId).future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            if (canAdjust)
              ListTile(leading: const Icon(Icons.add), title: Text(l10n.addMaterial), onTap: () => editItem(null)),
            if (value.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.noMaterials, textAlign: TextAlign.center),
              ),
            for (final item in value.where((item) => item.isActive || canAdjust))
              ListTile(
                leading: Icon(
                  item.isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                  color: item.isLow ? Theme.of(context).colorScheme.error : null,
                ),
                title: Text(item.isActive ? item.name : '${item.name} (${l10n.inactiveLabel})'),
                subtitle: Text(
                  item.isLow
                      ? l10n.lowStock(formatQuantity(item.minStock), item.unit)
                      : l10n.minStockLabel(formatQuantity(item.minStock), item.unit),
                ),
                trailing: Text(
                  '${formatQuantity(item.quantity)} ${item.unit}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: item.isLow ? Theme.of(context).colorScheme.error : null),
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) =>
                      _ItemSheet(branchId: branchId, item: item, canAdjust: canAdjust, onEdit: () => editItem(item)),
                ),
              ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(inventoryItemsProvider(branchId)),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

String reasonLabel(AppLocalizations l10n, StockMovementReason reason) => switch (reason) {
  StockMovementReason.purchase => l10n.movementPurchase,
  StockMovementReason.consumption => l10n.movementConsumption,
  StockMovementReason.count => l10n.movementCount,
};

/// A material at the branch: its stock, a stock count, and its latest movements.
class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({required this.branchId, required this.item, required this.canAdjust, required this.onEdit});

  final String branchId;
  final InventoryItem item;
  final bool canAdjust;
  final VoidCallback onEdit;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  final _counted = TextEditingController();
  final _note = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _count() async {
    final quantity = parseQuantity(_counted.text);
    if (quantity == null) {
      setState(() => _error = AppLocalizations.of(context).quantityInvalid);
      return;
    }
    try {
      final note = _note.text.trim();
      await ref
          .read(inventoryRepositoryProvider)
          .count(widget.branchId, widget.item.id, quantity, note: note.isEmpty ? null : note);
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(stockMovementsProvider);
      if (mounted) {
        Navigator.of(context).pop();
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
    final theme = Theme.of(context);
    final item = widget.item;
    final movements = ref.watch(stockMovementsProvider((branchId: widget.branchId, itemId: item.id)));

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: theme.textTheme.titleLarge)),
                if (widget.canAdjust)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onEdit();
                    },
                  ),
              ],
            ),
            Text('${formatQuantity(item.quantity)} ${item.unit}', style: theme.textTheme.headlineSmall),
            if (item.unitCost > 0)
              Text(
                l10n.unitCostLabel(ref.watch(moneyFormatProvider).format(item.unitCost), item.unit),
                style: theme.textTheme.bodySmall,
              ),
            if (widget.canAdjust) ...[
              const SizedBox(height: 16),
              Text(l10n.stockCount, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _counted,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.countedQuantity,
                        suffixText: item.unit,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _count, child: Text(l10n.save)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.notesField, isDense: true),
              ),
              if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            Text(l10n.stockHistory, style: theme.textTheme.titleSmall),
            switch (movements) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(l10n.noMovements),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final movement in value)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(reasonLabel(l10n, movement.reason)),
                      subtitle: Text(
                        [
                          MaterialLocalizations.of(context).formatMediumDate(movement.at.toLocal()),
                          ?movement.by,
                          ?movement.note,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${movement.change > 0 ? '+' : ''}${formatQuantity(movement.change)} → ${formatQuantity(movement.balance)}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: movement.change < 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => Text(changeError(context, error, StackTrace.current)),
              _ => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// Adds a material ([item] null) or edits its name, unit, minimum and whether it is used.
class _ItemDialog extends ConsumerStatefulWidget {
  const _ItemDialog({required this.item});

  final InventoryItem? item;

  @override
  ConsumerState<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends ConsumerState<_ItemDialog> {
  late final _name = TextEditingController(text: widget.item?.name);
  late final _unit = TextEditingController(text: widget.item?.unit);
  late final _minStock = TextEditingController(text: widget.item == null ? '' : formatQuantity(widget.item!.minStock));
  late bool _active = widget.item?.isActive ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _minStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final minStock = _minStock.text.trim().isEmpty ? 0.0 : parseQuantity(_minStock.text);
    if (_name.text.trim().isEmpty || _unit.text.trim().isEmpty || minStock == null) {
      setState(() => _error = minStock == null ? l10n.quantityInvalid : l10n.fieldRequired);
      return;
    }
    try {
      await ref.read(inventoryRepositoryProvider).saveItem(widget.item?.id, {
        'name': _name.text.trim(),
        'unit': _unit.text.trim(),
        'min_stock': minStock,
        'is_active': _active,
      });
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

    return AlertDialog(
      title: Text(widget.item == null ? l10n.addMaterial : widget.item!.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.nameField),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unit,
              decoration: InputDecoration(labelText: l10n.unitField, hintText: l10n.unitHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minStock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.minStockField, helperText: l10n.minStockHint),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.activeSwitch),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

class _Purchases extends ConsumerWidget {
  const _Purchases({required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return switch (ref.watch(purchasesProvider(branchId))) {
      AsyncData(:final value) when value.isEmpty => Center(child: Text(l10n.noPurchases)),
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(purchasesProvider(branchId).future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            for (final purchase in value)
              ExpansionTile(
                leading: Icon(
                  purchase.isPaid ? Icons.receipt_outlined : Icons.schedule,
                  color: purchase.isPaid ? null : Theme.of(context).colorScheme.error,
                ),
                title: Text(purchase.supplierName ?? l10n.noSupplier),
                subtitle: Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(purchase.purchasedOn)} · '
                  '${purchase.isPaid ? l10n.paidBadge : l10n.notPaidYet}',
                ),
                trailing: Text(money.format(purchase.total)),
                children: [
                  for (final line in purchase.lines)
                    ListTile(
                      dense: true,
                      title: Text('${line.name} × ${formatQuantity(line.quantity)} ${line.unit}'),
                      trailing: Text(money.format(line.lineTotal)),
                    ),
                ],
              ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(purchasesProvider(branchId))),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
