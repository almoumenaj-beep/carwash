import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../appointments/data/appointments_repository.dart';
import '../../appointments/domain/appointment.dart';
import '../../appointments/presentation/slot_picker.dart';
import '../../auth/application/session_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/domain/catalog.dart';
import '../../customers/data/customers_repository.dart';
import '../../customers/domain/customer.dart';
import '../../expenses/domain/expense.dart';
import '../data/orders_repository.dart';
import 'order_widgets.dart';

/// Checks a car in at [branchId]: a registered car found by plate, phone or name, or a walk-in plate
/// with its size; then the services (priced live), bay, washers and notes.
///
/// With [booking] the same form books the car in for a later time instead of the bay and washers; with an
/// [appointment] it starts from that booking, to check the booked car in or (with [booking]) to change it.
class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key, required this.branchId, this.booking = false, this.appointment});

  final String branchId;
  final bool booking;
  final Appointment? appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final sizes = ref.watch(vehicleSizesProvider);

    return switch ((services, sizes)) {
      (AsyncData(value: final services), AsyncData(value: final sizes)) => _CheckInForm(
        branchId: branchId,
        booking: booking,
        appointment: appointment,
        services: services.where((service) => service.isActive).toList(),
        catalog: {for (final service in services) service.id: service},
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
  const _CheckInForm({
    required this.branchId,
    required this.booking,
    required this.appointment,
    required this.services,
    required this.catalog,
    required this.sizes,
  });

  final String branchId;
  final bool booking;
  final Appointment? appointment;

  /// The active services that can be sold.
  final List<CatalogService> services;

  /// Every service by id (inactive ones too), to price packages from what they include.
  final Map<String, CatalogService> catalog;
  final List<VehicleSize> sizes;

  @override
  ConsumerState<_CheckInForm> createState() => _CheckInFormState();
}

class _CheckInFormState extends ConsumerState<_CheckInForm> {
  final _plate = TextEditingController();
  final _phone = TextEditingController();
  final _name = TextEditingController();
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

  /// The registered car of the booking this form started from, while its plate is left as it was.
  String? _bookedVehicleId;

  /// When booking: the day and the chosen start time (local `YYYY-MM-DDTHH:MM`).
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  String? _startsAt;

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment == null) {
      return;
    }

    _plate.text = appointment.plateNumber ?? '';
    _phone.text = appointment.customerPhone ?? '';
    _name.text = appointment.customerName ?? '';
    _notes.text = appointment.notes ?? '';
    _bookedVehicleId = appointment.vehicleId;
    _sizeId = appointment.vehicleSizeId;
    _serviceIds.addAll(
      appointment.items.map((item) => item.serviceId).where((id) => widget.services.any((service) => service.id == id)),
    );
    if (widget.booking) {
      final startsAt = appointment.startsAt.toLocal();
      _day = DateUtils.dateOnly(startsAt);
      _startsAt =
          '${apiDate(startsAt)}T${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _plate.dispose();
    _phone.dispose();
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSearchCustomers => ref.read(sessionProvider).value?.can(Permissions.customersView) ?? false;

  /// A walk-in who gives a phone number is registered with their car as part of the check-in.
  bool get _canRegisterCustomers => ref.read(sessionProvider).value?.can(Permissions.customersCreate) ?? false;

  void _onPlateChanged(String value) {
    if (_car != null || _bookedVehicleId != null) {
      setState(() {
        _car = null;
        _bookedVehicleId = null;
      });
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

  int? _price(CatalogService service) => service.priceIn(widget.catalog, _sizeId, widget.branchId);

  /// A package takes its own time, or else the time of the services it includes.
  int _minutes(CatalogService service) => service.isPackage && service.durationMinutes == 0
      ? service.packageItemIds.fold(0, (sum, id) => sum + (widget.catalog[id]?.durationMinutes ?? 0))
      : service.durationMinutes;

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
    final phone = _phone.text.trim();
    final name = _name.text.trim();

    final vehicleId = car?.vehicle.id ?? _bookedVehicleId;
    final plate = _plate.text.trim();
    final details = {
      'branch_id': widget.branchId,
      if (vehicleId != null) 'vehicle_id': vehicleId else if (plate.isNotEmpty) 'plate_number': plate,
      'vehicle_size_id': _sizeId,
      'items': [
        for (final service in chosen) {'service_id': service.id},
      ],
      if (notes.isNotEmpty) 'notes': notes,
      if (vehicleId == null && phone.isNotEmpty) ...{
        'customer_phone': phone,
        if (name.isNotEmpty) 'customer_name': name,
      },
    };

    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    try {
      final String done;
      if (widget.booking) {
        final appointments = ref.read(appointmentsRepositoryProvider);
        final booked = widget.appointment == null
            ? await appointments.book({...details, 'starts_at': _startsAt})
            : await appointments.update(widget.appointment!.id, {...details, 'starts_at': _startsAt});
        done = l10n.bookedAt(material.formatTimeOfDay(TimeOfDay.fromDateTime(booked.startsAt.toLocal())));
      } else {
        final order = {...details, 'bay_id': _bayId, 'staff_ids': _staffIds.toList()};
        final checkedIn = widget.appointment == null
            ? await ref.read(ordersRepositoryProvider).checkIn(order)
            : await ref.read(appointmentsRepositoryProvider).checkIn(widget.appointment!.id, order);
        done = l10n.checkedIn(checkedIn.reference);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
        Navigator.of(context).pop(true);
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
    final minutes = chosen.fold<int>(0, (sum, service) => sum + _minutes(service));
    final problem = _problem;
    final knownCar = _car != null || _bookedVehicleId != null;
    final canSubmit = widget.booking
        ? !_saving && _hasMainService && _startsAt != null && (knownCar || _phone.text.trim().isNotEmpty)
        : !_saving && _plate.text.trim().isNotEmpty && _hasMainService && _staffIds.isNotEmpty;
    final appointment = widget.appointment;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.booking
              ? (appointment == null ? l10n.newBooking : l10n.changeBooking)
              : (appointment == null ? l10n.checkInTitle : l10n.checkInBooking),
        ),
      ),
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
          if (_car == null && _bookedVehicleId != null && appointment != null)
            Card(
              margin: const EdgeInsets.only(top: 8),
              child: ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(appointment.customerName ?? appointment.plateNumber ?? ''),
                subtitle: appointment.customerPhone == null
                    ? null
                    : Text(formatPhone(appointment.customerPhone!), textDirection: TextDirection.ltr),
              ),
            ),
          if (!knownCar && _term.length >= 2 && _canSearchCustomers) _KnownCars(term: _term, onPick: _pickCar),
          if (!knownCar && (_canRegisterCustomers || widget.booking)) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.phoneField,
                helperText: widget.booking ? l10n.bookingPhoneHint : l10n.registerWalkInHint,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.customerName, prefixIcon: const Icon(Icons.person_outline)),
            ),
          ],
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
          for (final (title, shown) in [
            (l10n.packagesSection, widget.services.where((service) => service.isPackage)),
            (l10n.servicesSection, widget.services.where((service) => !service.isPackage && !service.isAddon)),
            (l10n.addonsSection, widget.services.where((service) => service.isAddon)),
          ])
            if (shown.isNotEmpty) ...[
              Text(title, style: theme.textTheme.titleSmall),
              for (final service in shown)
                _ServiceTile(
                  service: service,
                  price: _price(service),
                  minutes: _minutes(service),
                  details: service.isPackage
                      ? [
                          service.packageItemIds.map((id) => widget.catalog[id]?.name).whereType<String>().join(' + '),
                          if (service.separatePriceIn(widget.catalog, _sizeId, widget.branchId) case final separate?
                              when _price(service) != null && separate > _price(service)!)
                            l10n.packageSaves(money.format(separate - _price(service)!)),
                        ]
                      : const [],
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
          if (widget.booking)
            SlotPicker(
              branchId: widget.branchId,
              day: _day,
              minutes: minutes,
              appointmentId: appointment?.id,
              selected: _startsAt,
              onDayChanged: (day) => setState(() {
                _day = day;
                _startsAt = null;
              }),
              onPicked: (startsAt) => setState(() => _startsAt = startsAt),
            )
          else ...[
            BayPicker(branchId: widget.branchId, value: _bayId, onChanged: (id) => setState(() => _bayId = id)),
            const SizedBox(height: 16),
            WasherPicker(
              branchId: widget.branchId,
              selected: _staffIds,
              onChanged: (ids) => setState(() => _staffIds = ids),
            ),
          ],
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
                if (!widget.booking && _hasMainService && _staffIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(l10n.chooseWasher, style: TextStyle(color: theme.colorScheme.error)),
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
                      label: Text(widget.booking ? l10n.book : l10n.checkIn),
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
  const _ServiceTile({
    required this.service,
    required this.price,
    required this.minutes,
    required this.details,
    required this.chosen,
    required this.onChanged,
  });

  final CatalogService service;

  /// Null when the service has no price for the chosen size, so it cannot be sold.
  final int? price;
  final int minutes;

  /// Extra lines under the name, e.g. what a package includes and what it saves.
  final List<String> details;
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
      subtitle: Text([...details, l10n.minutesShort(minutes)].join('\n')),
      isThreeLine: details.isNotEmpty,
      secondary: Text(
        price == null ? l10n.unpriced : ref.watch(moneyFormatProvider).format(price),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
