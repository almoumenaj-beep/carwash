import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../../settings/data/settings_repository.dart';
import '../data/customers_repository.dart';
import '../domain/customer.dart';
import 'points_card.dart';

/// Registers a customer ([customerId] null) with their cars, or shows/edits one.
/// Read-only for staff who may only view customers.
class CustomerEditorScreen extends ConsumerWidget {
  const CustomerEditorScreen({super.key, this.customerId});

  final String? customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = customerId == null ? const AsyncData<Customer?>(null) : ref.watch(customerProvider(customerId!));
    final sizes = ref.watch(vehicleSizesProvider);

    void retry() {
      ref.invalidate(vehicleSizesProvider);
      if (customerId != null) {
        ref.invalidate(customerProvider(customerId!));
      }
    }

    return switch ((customer, sizes)) {
      (AsyncData(value: final customer), AsyncData(value: final sizes)) => _CustomerForm(
        key: ValueKey(customer?.id),
        customer: customer,
        sizes: sizes,
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: retry),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({super.key, required this.customer, required this.sizes});

  final Customer? customer;
  final List<VehicleSize> sizes;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.customer == null ? '' : formatPhone(widget.customer!.phone));
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _notes = TextEditingController(text: widget.customer?.notes);
  late bool _marketingConsent = widget.customer?.marketingConsent ?? false;

  /// Cars of a customer being registered; saved together with the customer.
  final List<Vehicle> _newVehicles = [];
  bool _saving = false;
  ApiProblem? _problem;

  bool get _isNew => widget.customer == null;

  bool get _canEdit {
    final me = ref.read(sessionProvider).value;
    return me != null && me.can(_isNew ? Permissions.customersCreate : Permissions.customersUpdate);
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });

    final data = {
      'phone': _phone.text.trim(),
      'name': _optional(_name),
      'email': _optional(_email),
      'notes': _optional(_notes),
      'marketing_consent': _marketingConsent,
    };

    final repository = ref.read(customersRepositoryProvider);
    try {
      if (_isNew) {
        final customer = await repository.create({
          ...data,
          'vehicles': [for (final vehicle in _newVehicles) vehicle.toJson()],
        });
        if (mounted) {
          context.pushReplacement('/customers/${customer.id}');
        }
      } else {
        await repository.update(widget.customer!.id, data);
        ref.invalidate(customerProvider(widget.customer!.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
        }
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() => _problem = problem);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final customer = widget.customer!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteEntryConfirm(customer.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _run(() => ref.read(customersRepositoryProvider).delete(customer.id), thenPop: true);
  }

  /// Runs a change to an existing customer's cars or record, then refreshes or leaves.
  Future<void> _run(Future<void> Function() change, {bool thenPop = false}) async {
    try {
      await change();
      if (!_isNew) {
        ref.invalidate(customerProvider(widget.customer!.id));
      }
      if (thenPop && mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        final message = problem.errors.values.firstOrNull?.first ?? problemMessage(context, problem);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _editVehicle({Vehicle? vehicle, int? newIndex}) async {
    final result = await showDialog<Vehicle>(
      context: context,
      builder: (_) => _VehicleDialog(vehicle: vehicle, sizes: widget.sizes),
    );
    if (result == null || !mounted) {
      return;
    }

    final repository = ref.read(customersRepositoryProvider);
    if (_isNew) {
      setState(() => newIndex == null ? _newVehicles.add(result) : _newVehicles[newIndex] = result);
    } else if (vehicle?.id == null) {
      await _run(() => repository.addVehicle(widget.customer!.id, result));
    } else {
      await _run(() => repository.updateVehicle(vehicle!.id!, result));
    }
  }

  Future<void> _removeVehicle(Vehicle vehicle, int index) async {
    if (_isNew) {
      setState(() => _newVehicles.removeAt(index));
      return;
    }

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteEntryConfirm(vehicle.plateNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => ref.read(customersRepositoryProvider).deleteVehicle(vehicle.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(sessionProvider).value;
    final canEdit = _canEdit;
    final canDelete = !_isNew && (me?.can(Permissions.customersDelete) ?? false);
    final vehicles = _isNew ? _newVehicles : widget.customer!.vehicles;
    final vehicleError = _problem?.errors.entries.where((entry) => entry.key.startsWith('vehicles')).firstOrNull;
    final knownFields = {'phone', 'name', 'email', 'notes'};
    final hasKnownError = _problem != null && (_problem!.errors.keys.any(knownFields.contains) || vehicleError != null);
    final generalError = _problem != null && !hasKnownError ? problemMessage(context, _problem!) : null;

    String sizeName(String? id) => widget.sizes.where((size) => size.id == id).firstOrNull?.name ?? l10n.sizeUnknown;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newCustomer : widget.customer!.displayName),
        actions: [
          if (canDelete) IconButton(tooltip: l10n.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            )
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _phone,
              enabled: canEdit,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: l10n.phoneField,
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: _problem?.fieldError('phone'),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              enabled: canEdit,
              decoration: InputDecoration(labelText: l10n.customerName, errorText: _problem?.fieldError('name')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: canEdit,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailField, errorText: _problem?.fieldError('email')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              enabled: canEdit,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.notesField),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.marketingConsent),
              subtitle: Text(l10n.marketingConsentHint),
              value: _marketingConsent,
              onChanged: canEdit ? (value) => setState(() => _marketingConsent = value) : null,
            ),
            if (widget.customer case final customer? when ref.watch(settingsProvider).value?.pointsEnabled ?? false)
              PointsCard(customer: customer),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: Text(l10n.vehiclesSection, style: theme.textTheme.titleMedium)),
                if (canEdit)
                  TextButton.icon(
                    onPressed: () => _editVehicle(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addVehicle),
                  ),
              ],
            ),
            if (vehicleError != null) Text(vehicleError.value.first, style: TextStyle(color: theme.colorScheme.error)),
            if (vehicles.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noVehicles))
            else
              Card(
                child: Column(
                  children: [
                    for (final (index, vehicle) in vehicles.indexed)
                      ListTile(
                        leading: const Icon(Icons.directions_car_outlined),
                        title: Text(vehicle.plateNumber),
                        subtitle: Text(
                          [
                            sizeName(vehicle.vehicleSizeId),
                            vehicle.description,
                          ].where((part) => part.isNotEmpty).join(' · '),
                        ),
                        onTap: canEdit ? () => _editVehicle(vehicle: vehicle, newIndex: _isNew ? index : null) : null,
                        // A car not saved yet is just removed from the form; a saved one needs customers.delete.
                        trailing: (_isNew && canEdit) || canDelete
                            ? IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeVehicle(vehicle, index),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            if (generalError != null) ...[
              const SizedBox(height: 12),
              Text(generalError, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Asks for a car's plate, size and description; pops with the car, or null when cancelled.
class _VehicleDialog extends StatefulWidget {
  const _VehicleDialog({required this.vehicle, required this.sizes});

  final Vehicle? vehicle;
  final List<VehicleSize> sizes;

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _plate = TextEditingController(text: widget.vehicle?.plateNumber);
  late final _make = TextEditingController(text: widget.vehicle?.make);
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late final _color = TextEditingController(text: widget.vehicle?.color);
  late String? _sizeId = widget.vehicle?.vehicleSizeId;

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _color.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sizes = widget.sizes.where((size) => size.isActive || size.id == _sizeId).toList();

    return AlertDialog(
      title: Text(widget.vehicle == null ? l10n.addVehicle : widget.vehicle!.plateNumber),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _plate,
                autofocus: widget.vehicle == null,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l10n.plateNumber),
                validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _sizeId,
                decoration: InputDecoration(labelText: l10n.vehicleSize),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.sizeUnknown)),
                  for (final size in sizes) DropdownMenuItem(value: size.id, child: Text(size.name)),
                ],
                onChanged: (value) => setState(() => _sizeId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _make,
                decoration: InputDecoration(labelText: l10n.vehicleMake),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _model,
                decoration: InputDecoration(labelText: l10n.vehicleModel),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _color,
                decoration: InputDecoration(labelText: l10n.vehicleColor),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              Vehicle(
                id: widget.vehicle?.id,
                plateNumber: _plate.text.trim(),
                vehicleSizeId: _sizeId,
                make: _optional(_make),
                model: _optional(_model),
                color: _optional(_color),
              ),
            );
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
