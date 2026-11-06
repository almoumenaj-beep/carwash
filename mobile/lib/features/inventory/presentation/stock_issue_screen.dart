import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/branch_chips.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../../orders/data/orders_repository.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';

/// Issues materials to a staff member: each material is chosen with its quantity and added to a list, which can be
/// reviewed before the whole list is issued at once.
class StockIssueScreen extends ConsumerStatefulWidget {
  const StockIssueScreen({super.key, this.branchId});

  /// The branch to start on; the user's first branch otherwise.
  final String? branchId;

  @override
  ConsumerState<StockIssueScreen> createState() => _StockIssueScreenState();
}

class _StockIssueScreenState extends ConsumerState<StockIssueScreen> {
  late String? _branchId = widget.branchId;
  String? _receiverId;
  String? _materialId;
  final List<({InventoryItem item, double quantity})> _lines = [];
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The list and the receiver belong to the branch they were entered for.
  void _switchBranch(String? branchId) {
    setState(() {
      _branchId = branchId;
      _receiverId = null;
      _materialId = null;
      _quantity.clear();
      _lines.clear();
      _error = null;
    });
  }

  /// Moves the chosen material and its quantity to the list; false, with the reason shown, when they are not valid.
  bool _addLine(List<InventoryItem> available) {
    final l10n = AppLocalizations.of(context);
    final item = available.where((item) => item.id == _materialId).firstOrNull;
    if (item == null) {
      setState(() => _error = l10n.chooseMaterialFirst);
      return false;
    }

    final quantity = parseQuantity(_quantity.text);
    if (quantity == null || quantity <= 0) {
      setState(() => _error = l10n.quantityInvalid);
      return false;
    }
    if (quantity > item.quantity) {
      setState(() => _error = l10n.onlyInStock(item.name, formatQuantity(item.quantity), item.unit));
      return false;
    }

    setState(() {
      _lines.add((item: item, quantity: quantity));
      _materialId = null;
      _quantity.clear();
      _error = null;
    });
    return true;
  }

  Future<void> _save(String branchId, List<InventoryItem> available) async {
    final l10n = AppLocalizations.of(context);

    // A material chosen but not added yet is what the user means to issue too.
    if ((_materialId != null || _quantity.text.trim().isNotEmpty) && !_addLine(available)) {
      return;
    }

    final receiverId = _receiverId;
    if (receiverId == null || _lines.isEmpty) {
      setState(() => _error = receiverId == null ? l10n.chooseReceiver : l10n.addOneMaterial);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _note.text.trim();
    try {
      await ref.read(inventoryRepositoryProvider).issue(branchId, receiverId, [
        for (final line in _lines) (itemId: line.item.id, quantity: line.quantity),
      ], note: note.isEmpty ? null : note);
      ref.invalidate(inventoryItemsProvider);
      ref.invalidate(stockMovementsProvider);
      ref.invalidate(dailyStockUsageProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.materialsIssued)));
        Navigator.of(context).pop();
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
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.issueMaterials)),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.issueMaterials)),
      body: switch (ref.watch(inventoryItemsProvider(branch.id))) {
        AsyncData(:final value) => _buildForm(
          branch.id,
          value.where((item) => item.isActive && item.quantity > 0).toList(),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(inventoryItemsProvider(branch.id)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildForm(String branchId, List<InventoryItem> available) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final staff = ref.watch(branchStaffProvider(branchId)).value ?? const [];
    final remaining = available.where((item) => !_lines.any((line) => line.item.id == item.id)).toList();
    final chosen = remaining.where((item) => item.id == _materialId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        BranchChips(selected: branchId, includeAll: false, onChanged: _switchBranch),
        if (available.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.nothingInStock, textAlign: TextAlign.center),
          )
        else ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('receiver-$branchId'),
            initialValue: _receiverId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.receivedByField, prefixIcon: const Icon(Icons.person_outline)),
            items: [for (final member in staff) DropdownMenuItem(value: member.id, child: Text(member.name))],
            onChanged: (id) => setState(() => _receiverId = id),
          ),
          const SizedBox(height: 16),
          if (remaining.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              // Rebuilt as the list changes, so it empties after each material is added.
              key: ValueKey('material-$branchId-${_lines.length}'),
              initialValue: _materialId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.materialField,
                prefixIcon: const Icon(Icons.inventory_2_outlined),
              ),
              items: [
                for (final item in remaining)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text('${item.name} (${formatQuantity(item.quantity)} ${item.unit})'),
                  ),
              ],
              onChanged: (id) => setState(() {
                _materialId = id;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.quantityField,
                      suffixText: chosen?.unit,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      helperText: chosen == null
                          ? null
                          : l10n.availableQuantity('${formatQuantity(chosen.quantity)} ${chosen.unit}'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _addLine(remaining),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMaterialLine),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 16),
          Text(l10n.issueListSection(_lines.length), style: theme.textTheme.titleSmall),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(l10n.issueListEmpty, style: theme.textTheme.bodySmall),
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
                      subtitle: Text('${formatQuantity(line.quantity)} ${line.item.unit}'),
                      trailing: IconButton(
                        tooltip: l10n.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => _lines.remove(line)),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLength: 255,
            decoration: InputDecoration(labelText: l10n.issueNoteField, hintText: l10n.issueNoteHint),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(branchId, remaining),
            icon: const Icon(Icons.outbox_outlined),
            label: Text(l10n.issueMaterials),
          ),
        ],
      ],
    );
  }
}
