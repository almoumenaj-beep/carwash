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

/// Issues the day's materials to a staff member: who receives them, and a quantity beside each material in stock,
/// left empty for those not taken.
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
  final Map<String, TextEditingController> _quantities = {};
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  TextEditingController _quantityOf(InventoryItem item) => _quantities.putIfAbsent(item.id, TextEditingController.new);

  /// Quantities and the receiver belong to the branch they were entered for.
  void _switchBranch(String? branchId) {
    setState(() {
      _branchId = branchId;
      _receiverId = null;
      _error = null;
      for (final controller in _quantities.values) {
        controller.clear();
      }
    });
  }

  Future<void> _save(String branchId, List<InventoryItem> items) async {
    final l10n = AppLocalizations.of(context);
    final lines = <({String itemId, double quantity})>[];
    for (final item in items) {
      final typed = _quantityOf(item).text.trim();
      if (typed.isEmpty) {
        continue;
      }
      final quantity = parseQuantity(typed);
      if (quantity == null || quantity <= 0) {
        setState(() => _error = '${item.name}: ${l10n.quantityInvalid}');
        return;
      }
      if (quantity > item.quantity) {
        setState(() => _error = l10n.onlyInStock(item.name, formatQuantity(item.quantity), item.unit));
        return;
      }
      lines.add((itemId: item.id, quantity: quantity));
    }

    final receiverId = _receiverId;
    if (receiverId == null || lines.isEmpty) {
      setState(() => _error = receiverId == null ? l10n.chooseReceiver : l10n.enterIssueQuantities);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final note = _note.text.trim();
    try {
      await ref.read(inventoryRepositoryProvider).issue(branchId, receiverId, lines, note: note.isEmpty ? null : note);
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
    final theme = Theme.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.issueMaterials)),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    final staff = ref.watch(branchStaffProvider(branch.id)).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.issueMaterials)),
      body: switch (ref.watch(inventoryItemsProvider(branch.id))) {
        AsyncData(:final value) => () {
          final available = value.where((item) => item.isActive && item.quantity > 0).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              BranchChips(selected: branch.id, includeAll: false, onChanged: _switchBranch),
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l10n.nothingInStock, textAlign: TextAlign.center),
                )
              else ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey('receiver-${branch.id}'),
                  initialValue: _receiverId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.receivedByField,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  items: [for (final member in staff) DropdownMenuItem(value: member.id, child: Text(member.name))],
                  onChanged: (id) => setState(() => _receiverId = id),
                ),
                const SizedBox(height: 16),
                Text(l10n.issueQuantitiesSection, style: theme.textTheme.titleSmall),
                Text(l10n.issueQuantitiesHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                for (final item in available)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              Text(
                                l10n.availableQuantity('${formatQuantity(item.quantity)} ${item.unit}'),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _quantityOf(item),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(suffixText: item.unit, isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.issueNoteField, hintText: l10n.issueNoteHint),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(branch.id, available),
                  icon: const Icon(Icons.outbox_outlined),
                  label: Text(l10n.issueMaterials),
                ),
              ],
            ],
          );
        }(),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(inventoryItemsProvider(branch.id)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
