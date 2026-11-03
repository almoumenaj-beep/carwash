import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/equipment_repository.dart';
import '../domain/equipment.dart';

/// The category maintenance is recorded under: "Maintenance" (or the Arabic default) when it exists, else the first one.
ExpenseCategory? maintenanceCategory(List<ExpenseCategory> categories) {
  final active = categories.where((category) => category.isActive).toList();
  return active
          .where((category) => category.name.contains('صيانة') || category.name.toLowerCase().contains('maint'))
          .firstOrNull ??
      active.firstOrNull;
}

/// A date row that opens a date picker; past dates only.
class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.value, required this.onChanged, this.onClear});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_outlined),
      title: Text(label),
      subtitle: Text(value == null ? l10n.notSet : MaterialLocalizations.of(context).formatMediumDate(value!)),
      trailing: value != null && onClear != null ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
      onTap: () async {
        final today = DateUtils.dateOnly(DateTime.now());
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? today,
          firstDate: DateTime(2000),
          lastDate: today,
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
    );
  }
}

/// Adds a piece of equipment, or edits [equipment].
class EquipmentEditorScreen extends ConsumerStatefulWidget {
  const EquipmentEditorScreen({super.key, this.equipment});

  final Equipment? equipment;

  @override
  ConsumerState<EquipmentEditorScreen> createState() => _EquipmentEditorScreenState();
}

class _EquipmentEditorScreenState extends ConsumerState<EquipmentEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.equipment?.name);
  late final _serial = TextEditingController(text: widget.equipment?.serialNumber);
  late final _cost = TextEditingController(
    text: widget.equipment?.purchaseCost == null
        ? ''
        : ref.read(moneyFormatProvider).toInput(widget.equipment!.purchaseCost!),
  );
  late final _interval = TextEditingController(text: widget.equipment?.maintenanceIntervalDays?.toString());
  late final _notes = TextEditingController(text: widget.equipment?.notes);
  late DateTime? _purchasedOn = widget.equipment?.purchasedOn;
  late String? _branchId = widget.equipment?.branchId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _serial.dispose();
    _cost.dispose();
    _interval.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _text(TextEditingController controller) => controller.text.trim().isEmpty ? null : controller.text.trim();

  Future<void> _save(String branchId) async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final money = ref.read(moneyFormatProvider);
    final data = {
      'branch_id': branchId,
      'name': _name.text.trim(),
      'serial_number': _text(_serial),
      'purchased_on': _purchasedOn == null ? null : apiDate(_purchasedOn!),
      'purchase_cost': _text(_cost) == null ? null : money.parse(_cost.text),
      'maintenance_interval_days': _text(_interval) == null ? null : int.parse(_interval.text.trim()),
      'notes': _text(_notes),
    };

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(equipmentRepositoryProvider);
      if (widget.equipment == null) {
        await repository.create(data);
      } else {
        await repository.update(widget.equipment!.id, data);
      }
      ref.invalidate(equipmentProvider);
      if (mounted) {
        Navigator.of(context).pop();
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
    final money = ref.watch(moneyFormatProvider);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(widget.equipment == null ? l10n.addEquipment : l10n.editEquipment)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: widget.equipment == null,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.equipmentNameField, hintText: l10n.equipmentNameHint),
              validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            if (branches.length > 1)
              DropdownButtonFormField<String>(
                initialValue: branch?.id,
                decoration: InputDecoration(labelText: l10n.branchField),
                items: [for (final option in branches) DropdownMenuItem(value: option.id, child: Text(option.name))],
                onChanged: (id) => setState(() => _branchId = id),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _interval,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.maintenanceIntervalField,
                suffixText: l10n.daysUnit,
                helperText: l10n.maintenanceIntervalHint,
              ),
              validator: (value) {
                final days = int.tryParse((value ?? '').trim());
                return (value ?? '').trim().isNotEmpty && (days == null || days < 1 || days > 3650)
                    ? l10n.maintenanceIntervalInvalid
                    : null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _serial,
              maxLength: 100,
              decoration: InputDecoration(labelText: l10n.serialNumberField),
            ),
            _DateTile(
              label: l10n.purchaseDateField,
              value: _purchasedOn,
              onChanged: (date) => setState(() => _purchasedOn = date),
              onClear: () => setState(() => _purchasedOn = null),
            ),
            TextFormField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
              decoration: InputDecoration(labelText: l10n.purchaseCostField, suffixText: money.currency),
              validator: (value) => (value ?? '').trim().isNotEmpty && money.parse(value!) == null
                  ? l10n.amountInvalid(money.toInput(2500))
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              maxLength: 255,
              decoration: InputDecoration(labelText: l10n.notesField),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

/// Records periodic maintenance or a repair on [equipment]; a cost is recorded as an expense, paid or owed.
class MaintenanceEditorScreen extends ConsumerStatefulWidget {
  const MaintenanceEditorScreen({super.key, required this.equipment});

  final Equipment equipment;

  @override
  ConsumerState<MaintenanceEditorScreen> createState() => _MaintenanceEditorScreenState();
}

class _MaintenanceEditorScreenState extends ConsumerState<MaintenanceEditorScreen> {
  late MaintenanceKind _kind = widget.equipment.status == EquipmentStatus.outOfService
      ? MaintenanceKind.repair
      : MaintenanceKind.periodic;
  DateTime _performedOn = DateUtils.dateOnly(DateTime.now());
  final _description = TextEditingController();
  final _cost = TextEditingController();
  String? _categoryId;
  String? _supplierId;
  ExpensePaymentMethod? _method = ExpensePaymentMethod.cash;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _save(int cost, String? categoryId) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(equipmentRepositoryProvider).recordMaintenance(widget.equipment.id, {
        'kind': _kind.apiValue,
        'performed_on': apiDate(_performedOn),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'cost': cost,
        if (cost > 0) ...{
          'expense_category_id': categoryId,
          'supplier_id': _supplierId,
          'payment_method': _method?.apiValue,
        },
      });
      ref.invalidate(equipmentProvider);
      ref.invalidate(maintenancesProvider(widget.equipment.id));
      if (mounted) {
        Navigator.of(context).pop();
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
    final money = ref.watch(moneyFormatProvider);
    final categories = ref.watch(expenseCategoriesProvider).value ?? const <ExpenseCategory>[];
    final suppliers = ref.watch(suppliersProvider).value ?? const <Supplier>[];
    final categoryId = _categoryId ?? maintenanceCategory(categories)?.id;
    final cost = _cost.text.trim().isEmpty ? 0 : money.parse(_cost.text);

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.recordMaintenance} · ${widget.equipment.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<MaintenanceKind>(
            segments: [
              ButtonSegment(
                value: MaintenanceKind.periodic,
                icon: const Icon(Icons.event_repeat),
                label: Text(l10n.periodicMaintenance),
              ),
              ButtonSegment(
                value: MaintenanceKind.repair,
                icon: const Icon(Icons.handyman_outlined),
                label: Text(l10n.repairMaintenance),
              ),
            ],
            selected: {_kind},
            onSelectionChanged: (selection) => setState(() => _kind = selection.single),
          ),
          const SizedBox(height: 8),
          Text(
            _kind == MaintenanceKind.periodic ? l10n.periodicMaintenanceHint : l10n.repairMaintenanceHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          _DateTile(
            label: l10n.maintenanceDateField,
            value: _performedOn,
            onChanged: (date) => setState(() => _performedOn = date),
          ),
          TextField(
            controller: _description,
            maxLength: 255,
            decoration: InputDecoration(labelText: l10n.whatWasDoneField),
          ),
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
            decoration: InputDecoration(
              labelText: l10n.maintenanceCostField,
              suffixText: money.currency,
              helperText: l10n.maintenanceCostHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (cost != null && cost > 0) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: categoryId,
              decoration: InputDecoration(labelText: l10n.expenseCategory),
              items: [
                for (final category in categories.where((category) => category.isActive))
                  DropdownMenuItem(value: category.id, child: Text(category.name)),
              ],
              onChanged: (id) => setState(() => _categoryId = id),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _supplierId,
              decoration: InputDecoration(labelText: l10n.supplierField),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noSupplier)),
                for (final supplier in suppliers.where((supplier) => supplier.isActive))
                  DropdownMenuItem(value: supplier.id, child: Text(supplier.name)),
              ],
              onChanged: (id) => setState(() => _supplierId = id),
            ),
            const SizedBox(height: 12),
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
          ],
          if (cost == null)
            Text(l10n.amountInvalid(money.toInput(2500)), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving || cost == null || (cost > 0 && categoryId == null)
                ? null
                : () => _save(cost, categoryId),
            icon: const Icon(Icons.check),
            label: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
