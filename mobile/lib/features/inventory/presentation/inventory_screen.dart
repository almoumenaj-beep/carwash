import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/branch_chips.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/domain/expense.dart' show apiDate;
import '../../expenses/presentation/expense_widgets.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';
import 'purchase_editor_screen.dart';

/// Stock at a branch, with low materials flagged, stock counts, issues by hand and each material's history; what
/// left the stock each day; and the purchases received there.
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.inventoryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.stockTab),
              Tab(text: l10n.dailyUsageTab),
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
        body: Column(
          children: [
            BranchChips(selected: branch.id, includeAll: false, onChanged: (id) => setState(() => _branchId = id)),
            Expanded(
              child: TabBarView(
                children: [
                  _Stock(branchId: branch.id, canAdjust: canAdjust),
                  _DailyUsage(branchId: branch.id, canAdjust: canAdjust),
                  _Purchases(branchId: branch.id),
                ],
              ),
            ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: value.isEmpty ? null : () => issueMaterials(context, ref, branchId, value),
                      icon: const Icon(Icons.outbox_outlined),
                      label: Text(l10n.issueMaterials),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => editItem(null),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addMaterial),
                    ),
                  ],
                ),
              ),
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
  StockMovementReason.issue => l10n.movementIssue,
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
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final issued = await issueMaterials(context, ref, widget.branchId, [item], initial: item);
                  if (issued && mounted) {
                    navigator.pop();
                  }
                },
                icon: const Icon(Icons.outbox_outlined),
                label: Text(l10n.issueMaterials),
              ),
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

/// Asks what to take out of the branch's stock by hand, and does it. True once something was issued.
Future<bool> issueMaterials(
  BuildContext context,
  WidgetRef ref,
  String branchId,
  List<InventoryItem> items, {
  InventoryItem? initial,
}) async {
  final issued = await showDialog<bool>(
    context: context,
    builder: (_) => _IssueDialog(branchId: branchId, items: items, initial: initial),
  );
  return issued ?? false;
}

class _IssueDialog extends ConsumerStatefulWidget {
  const _IssueDialog({required this.branchId, required this.items, required this.initial});

  final String branchId;
  final List<InventoryItem> items;
  final InventoryItem? initial;

  @override
  ConsumerState<_IssueDialog> createState() => _IssueDialogState();
}

class _IssueDialogState extends ConsumerState<_IssueDialog> {
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  late final List<InventoryItem> _available = widget.items.where((item) => item.isActive && item.quantity > 0).toList();
  late InventoryItem? _item = widget.initial ?? _available.firstOrNull;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final item = _item;
    final quantity = parseQuantity(_quantity.text);
    if (item == null || quantity == null || quantity <= 0) {
      setState(() => _error = l10n.quantityInvalid);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await ref
          .read(inventoryRepositoryProvider)
          .issue(widget.branchId, item.id, quantity, note: note.isEmpty ? null : note);
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(dailyStockUsageProvider);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = changeError(context, error, stackTrace);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = _item;

    return AlertDialog(
      title: Text(l10n.issueMaterials),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_available.isEmpty)
              Text(l10n.nothingInStock)
            else ...[
              DropdownButtonFormField<String>(
                initialValue: item?.id,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.materialField),
                items: [
                  for (final option in _available)
                    DropdownMenuItem(
                      value: option.id,
                      child: Text('${option.name} (${formatQuantity(option.quantity)} ${option.unit})'),
                    ),
                ],
                onChanged: (id) => setState(() => _item = _available.firstWhere((option) => option.id == id)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantity,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.issueQuantityField, suffixText: item?.unit),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                maxLength: 255,
                decoration: InputDecoration(labelText: l10n.issueNoteField, hintText: l10n.issueNoteHint),
              ),
            ],
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(onPressed: _saving || _available.isEmpty ? null : _save, child: Text(l10n.issueMaterials)),
      ],
    );
  }
}

/// What left the branch's stock day by day: what the washes used, what was issued by hand, and each hand issue.
class _DailyUsage extends ConsumerStatefulWidget {
  const _DailyUsage({required this.branchId, required this.canAdjust});

  final String branchId;
  final bool canAdjust;

  @override
  ConsumerState<_DailyUsage> createState() => _DailyUsageState();
}

class _DailyUsageState extends ConsumerState<_DailyUsage> {
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final isToday = DateUtils.isSameDay(_day, DateTime.now());
    final query = (branchId: widget.branchId, date: apiDate(_day));
    final items = ref.watch(inventoryItemsProvider(widget.branchId)).value ?? const <InventoryItem>[];

    return RefreshIndicator(
      onRefresh: () => ref.refresh(dailyStockUsageProvider(query).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.previousDay,
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: Text(
                  isToday ? l10n.today : MaterialLocalizations.of(context).formatMediumDate(_day),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.nextDay,
                icon: const Icon(Icons.chevron_right),
                onPressed: isToday ? null : () => setState(() => _day = _day.add(const Duration(days: 1))),
              ),
            ],
          ),
          if (widget.canAdjust && isToday)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: FilledButton.tonalIcon(
                onPressed: items.isEmpty ? null : () => issueMaterials(context, ref, widget.branchId, items),
                icon: const Icon(Icons.outbox_outlined),
                label: Text(l10n.issueMaterials),
              ),
            ),
          switch (ref.watch(dailyStockUsageProvider(query))) {
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!value.materialsSetUp)
                  Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    color: theme.colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l10n.materialsNotSetUp),
                      subtitle: Text(l10n.materialsNotSetUpHint),
                    ),
                  ),
                if (value.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l10n.noUsageThatDay, textAlign: TextAlign.center),
                  )
                else ...[
                  for (final row in value.items)
                    ListTile(
                      leading: const Icon(Icons.water_drop_outlined),
                      title: Text(row.name),
                      subtitle: Text(
                        [
                          if (row.washes > 0) l10n.usedByWashes('${formatQuantity(row.washes)} ${row.unit}'),
                          if (row.issued > 0) l10n.issuedByHand('${formatQuantity(row.issued)} ${row.unit}'),
                        ].join(' · '),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${formatQuantity(row.total)} ${row.unit}', style: theme.textTheme.titleSmall),
                          if (row.cost > 0) Text(money.format(row.cost), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  if (value.totalCost > 0)
                    ListTile(
                      title: Text(l10n.usageCostTotal),
                      subtitle: Text(l10n.usageCostHint),
                      trailing: Text(money.format(value.totalCost), style: theme.textTheme.titleMedium),
                    ),
                  if (value.issues.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(l10n.issuesByHandSection, style: theme.textTheme.titleSmall),
                    ),
                    for (final issue in value.issues)
                      ListTile(
                        dense: true,
                        title: Text('${issue.name} × ${formatQuantity(issue.quantity)} ${issue.unit}'),
                        subtitle: Text(
                          [
                            MaterialLocalizations.of(context)
                                .formatTimeOfDay(TimeOfDay.fromDateTime(issue.at.toLocal())),
                            ?issue.by,
                            ?issue.note,
                          ].join(' · '),
                        ),
                      ),
                  ],
                ],
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(dailyStockUsageProvider(query)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
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
                // What was bought names the row: the supplier alone does not tell two purchases apart.
                title: Text(
                  purchase.lines
                      .map((line) => '${line.name} × ${formatQuantity(line.quantity)} ${line.unit}')
                      .join('، '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    MaterialLocalizations.of(context).formatMediumDate(purchase.purchasedOn),
                    l10n.supplierLabel(purchase.supplierName ?? l10n.noSupplier),
                    if (purchase.isPaid) l10n.paidBadge else l10n.notPaidYet,
                  ].join(' · '),
                ),
                trailing: Text(money.format(purchase.total)),
                children: [
                  for (final line in purchase.lines)
                    ListTile(
                      dense: true,
                      title: Text(line.name),
                      subtitle: Text('${formatQuantity(line.quantity)} ${line.unit} × ${money.format(line.unitCost)}'),
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
