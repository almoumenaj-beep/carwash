import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../data/orders_repository.dart';
import 'order_widgets.dart';

/// Checks a car in at [branchId]: a registered car found by plate, phone or name, or a walk-in plate
/// with its size; then the services (priced live), bay, washers and notes.
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key, required this.branchId});

  final String branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final sizes = ref.watch(vehicleSizesProvider);

    return switch ((services, sizes)) {
      (AsyncData(value: final services), AsyncData(value: final sizes)) => _CheckInForm(
        branchId: branchId,
        services: services.where((service) => service.isActive).toList(),
        sizes: sizes.where((size) => size.isActive).toList(),
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(servicesProvider);
            ref.invalidate(vehicleSizesProvider);
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

/// A registered car and its owner, offered while the plate is typed.
typedef _KnownCar = ({Customer customer, Vehicle vehicle});

class _CheckInForm extends ConsumerStatefulWidget {
  const _CheckInForm({required this.branchId, required this.services, required this.sizes});

  final String branchId;
  final List<CatalogService> services;
  final List<VehicleSize> sizes;

  @override
  ConsumerState<_CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<_CheckInForm> {
  final _plate = TextEditingController();
  final _notes = TextEditingController();
  Timer? _debounce;
  String _term = '';

  _KnownCar? _car;
  String? _sizeId;

  /// Chosen services in the order they were picked.
  final Set<String> _serviceIds = {};
  String? _bayId;
  Set<String> _staffIds = {};
  bool _saving = false;
  ApiProblem? _problem;

  @override
  void dispose() {
    _debounce?.cancel();
    _plate.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSearchCustomers => ref.read(sessionProvider).value?.can(Permissions.customersView) ?? false;

  void _onPlateChanged(String value) {
    if (_car != null) {
      setState(() => _car = null);
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _term = value.trim()));
  }

  void _pickCar(_KnownCar car) {
    setState(() {
      _car = car;
      _plate.text = car.vehicle.plateNumber;
      _term = '';
      _sizeId = car.vehicle.vehicleSizeId ?? _sizeId;
      _dropUnpriced();
    });
  }

  void _pickSize(String sizeId) {
    setState(() {
      _sizeId = sizeId;
      _dropUnpriced();
    });
  }

  int? _price(CatalogService service) => service.priceFor(_sizeId, widget.branchId);

  /// A different size can leave a chosen service without a price; it cannot be sold then.
  void _dropUnpriced() {
    _serviceIds.removeWhere((id) => _price(widget.services.firstWhere((service) => service.id == id)) == null);
  }

  List<CatalogService> get _chosen => [
    for (final id in _serviceIds) widget.services.firstWhere((service) => service.id == id),
  ];

  bool get _hasMainService => _chosen.any((service) => !service.isAddon);

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _problem = null;
    });

    final chosen = _chosen..sort((a, b) => (a.isAddon ? 1 : 0) - (b.isAddon ? 1 : 0));
    final car = _car;
    final notes = _notes.text.trim();

    try {
      final order = await ref.read(ordersRepositoryProvider).checkIn({
        'branch_id': widget.branchId,
        if (car != null) 'vehicle_id': car.vehicle.id else 'plate_number': _plate.text.trim(),
        'vehicle_size_id': _sizeId,
        'items': [
          for (final service in chosen) {'service_id': service.id},
        ],
        'bay_id': _bayId,
        'staff_ids': _staffIds.toList(),
        if (notes.isNotEmpty) 'notes': notes,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).checkedIn(order.reference))));
        context.pop();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final chosen = _chosen;
    final total = chosen.fold<int>(0, (sum, service) => sum + (_price(service) ?? 0));
    final minutes = chosen.fold<int>(0, (sum, service) => sum + service.durationMinutes);
    final problem = _problem;
    final canSubmit = !_saving && _plate.text.trim().isNotEmpty && _hasMainService;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _plate,
            onChanged: _onPlateChanged,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.plateNumber,
              hintText: _canSearchCustomers ? l10n.customerSearchHint : null,
              prefixIcon: const Icon(Icons.directions_car_outlined),
            ),
          ),
          if (_car != null) _ChosenCar(car: _car!),
          if (_car == null && _term.length >= 2 && _canSearchCustomers) _KnownCars(term: _term, onPick: _pickCar),
          const SizedBox(height: 16),
          Text(l10n.vehicleSize, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final size in widget.sizes)
                ChoiceChip(label: Text(size.name), selected: _sizeId == size.id, onSelected: (_) => _pickSize(size.id)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (title, addons) in [(l10n.servicesSection, false), (l10n.addonsSection, true)]) ...[
            Text(title, style: theme.textTheme.titleSmall),
            for (final service in widget.services.where((service) => service.isAddon == addons))
              _ServiceTile(
                service: service,
                price: _price(service),
                chosen: _serviceIds.contains(service.id),
                onChanged: (on) => setState(() => on ? _serviceIds.add(service.id) : _serviceIds.remove(service.id)),
              ),
            const SizedBox(height: 8),
          ],
          if (_sizeId == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.chooseSizeForPrices, style: theme.textTheme.bodySmall),
            ),
          BayPicker(branchId: widget.branchId, value: _bayId, onChanged: (id) => setState(() => _bayId = id)),
          const SizedBox(height: 16),
          WasherPicker(
            branchId: widget.branchId,
            selected: _staffIds,
            onChanged: (ids) => setState(() => _staffIds = ids),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 2,
            maxLength: 1000,
            decoration: InputDecoration(labelText: l10n.notesField),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (problem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      problem.errors.isEmpty
                          ? problemMessage(context, problem)
                          : problem.errors.values.map((messages) => messages.first).toSet().join('\n'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                if (chosen.isNotEmpty && !_hasMainService)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l10n.chooseMainService, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l10n.orderTotal}: ${money.format(total)}', style: theme.textTheme.titleMedium),
                          if (minutes > 0) Text(l10n.aboutMinutes(minutes), style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: canSubmit ? _submit : null,
                      icon: _saving
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(l10n.checkIn),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChosenCar extends StatelessWidget {
  const _ChosenCar({required this.car});

  final _KnownCar car;

  @override
  Widget build(BuildContext context) {
    final description = car.vehicle.description;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: Text(car.customer.displayName),
        subtitle: Text(
          [formatPhone(car.customer.phone), if (description.isNotEmpty) description].join(' · '),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}

/// Registered cars matching what was typed: cars whose plate matches, or else every car of the matching
/// customers (when a phone number or name was typed).
class _KnownCars extends ConsumerWidget {
  const _KnownCars({required this.term, required this.onPick});

  final String term;
  final ValueChanged<_KnownCar> onPick;

  static String _plateKey(String plate) => plate.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z؀-ۿ]'), '');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerSearchProvider(term)).value ?? const <Customer>[];
    final cars = [
      for (final customer in customers)
        for (final vehicle in customer.vehicles) (customer: customer, vehicle: vehicle),
    ];
    final key = _plateKey(term);
    final byPlate = cars.where((car) => key.isNotEmpty && _plateKey(car.vehicle.plateNumber).contains(key)).toList();
    final shown = (byPlate.isEmpty ? cars : byPlate).take(6).toList();

    if (shown.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(AppLocalizations.of(context).matchingCars, style: Theme.of(context).textTheme.labelLarge),
          ),
          for (final car in shown)
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: Text(car.vehicle.plateNumber, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
              subtitle: Text(car.customer.displayName),
              onTap: () => onPick(car),
            ),
        ],
      ),
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service, required this.price, required this.chosen, required this.onChanged});

  final CatalogService service;

  /// Null when the service has no price for the chosen size, so it cannot be sold.
  final int? price;
  final bool chosen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final price = this.price;

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: chosen,
      onChanged: price == null ? null : (on) => onChanged(on ?? false),
      title: Text(service.name),
      subtitle: Text(l10n.minutesShort(service.durationMinutes)),
      secondary: Text(
        price == null ? l10n.unpriced : ref.watch(moneyFormatProvider).format(price),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
