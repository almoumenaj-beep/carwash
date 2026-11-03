import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../customers/domain/customer.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../../orders/presentation/check_in_screen.dart';
import '../data/appointments_repository.dart';
import '../domain/appointment.dart';

String appointmentStatusLabel(AppLocalizations l10n, AppointmentStatus status) => switch (status) {
  AppointmentStatus.booked => l10n.appointmentBooked,
  AppointmentStatus.checkedIn => l10n.appointmentCheckedIn,
  AppointmentStatus.cancelled => l10n.appointmentCancelled,
  AppointmentStatus.noShow => l10n.appointmentNoShow,
};

/// A branch's bookings day by day: book a car in, change or cancel a booking, and check the car in when it arrives.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  String? _branchId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  Future<void> _open(Widget screen, String branchId) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => screen));
    if (changed ?? false) {
      ref.invalidate(appointmentsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(sessionProvider).value;
    final branches = me?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;
    if (branch == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    final query = (branchId: branch.id, date: apiDate(_day));
    final today = DateUtils.dateOnly(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(branches.length > 1 ? '${l10n.appointmentsTitle} · ${branch.name}' : l10n.appointmentsTitle),
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
      ),
      floatingActionButton: (me?.can(Permissions.appointmentsManage) ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _open(CheckInScreen(branchId: branch.id, booking: true), branch.id),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(l10n.newBooking),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(appointmentsProvider(query).future),
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
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      DateUtils.isSameDay(_day, today)
                          ? l10n.today
                          : MaterialLocalizations.of(context).formatMediumDate(_day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _day,
                        firstDate: DateTime(2024),
                        lastDate: today.add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _day = picked);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))),
                ),
              ],
            ),
            switch (ref.watch(appointmentsProvider(query))) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(48),
                child: Text(l10n.noBookingsThatDay, textAlign: TextAlign.center),
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final appointment in value)
                    _AppointmentTile(
                      appointment: appointment,
                      onCheckIn: () => _open(CheckInScreen(branchId: branch.id, appointment: appointment), branch.id),
                      onChange: () =>
                          _open(CheckInScreen(branchId: branch.id, booking: true, appointment: appointment), branch.id),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(appointmentsProvider(query)),
              ),
              _ => const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends ConsumerWidget {
  const _AppointmentTile({required this.appointment, required this.onCheckIn, required this.onChange});

  final Appointment appointment;
  final VoidCallback onCheckIn;
  final VoidCallback onChange;

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() change) async {
    try {
      await change();
      ref.invalidate(appointmentsProvider);
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelBooking),
        content: TextField(
          controller: reason,
          autofocus: true,
          maxLength: 255,
          decoration: InputDecoration(labelText: l10n.cancelReasonField),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.back)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.cancelBooking)),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if ((confirmed ?? false) && context.mounted) {
      await _run(
        context,
        ref,
        () => ref.read(appointmentsRepositoryProvider).cancel(appointment.id, text.isEmpty ? null : text),
      );
    }
  }

  void _actions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.read(sessionProvider).value;
    final canManage = me?.can(Permissions.appointmentsManage) ?? false;
    final canCheckIn = me?.can(Permissions.ordersCreate) ?? false;
    final orderId = appointment.orderId;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (appointment.isBooked && canCheckIn)
              ListTile(
                leading: const Icon(Icons.local_car_wash_outlined),
                title: Text(l10n.checkInBooking),
                onTap: () {
                  Navigator.of(sheet).pop();
                  onCheckIn();
                },
              ),
            if (appointment.isBooked && canManage)
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text(l10n.changeBooking),
                onTap: () {
                  Navigator.of(sheet).pop();
                  onChange();
                },
              ),
            if (appointment.isBooked && canManage && appointment.startsAt.isBefore(DateTime.now()))
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(l10n.markNoShow),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _run(context, ref, () => ref.read(appointmentsRepositoryProvider).noShow(appointment.id));
                },
              ),
            if (appointment.isBooked && canManage)
              ListTile(
                leading: Icon(Icons.event_busy_outlined, color: Theme.of(context).colorScheme.error),
                title: Text(l10n.cancelBooking),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _cancel(context, ref);
                },
              ),
            if (orderId != null)
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(l10n.openOrder),
                onTap: () {
                  Navigator.of(sheet).pop();
                  context.push('/queue/$orderId');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final theme = Theme.of(context);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(appointment.startsAt.toLocal()));
    final who = [
      ?appointment.customerName,
      if (appointment.customerPhone != null) formatPhone(appointment.customerPhone!),
      ?appointment.plateNumber,
    ];
    final faded = appointment.status == AppointmentStatus.cancelled || appointment.status == AppointmentStatus.noShow;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(time, style: theme.textTheme.titleSmall),
              Text(l10n.minutesShort(appointment.minutes), style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        title: Text(
          who.isEmpty ? '—' : who.join(' · '),
          style: faded ? TextStyle(decoration: TextDecoration.lineThrough, color: theme.disabledColor) : null,
        ),
        subtitle: Text(
          [
            appointment.items.map((item) => item.name).join(' + '),
            [
              appointmentStatusLabel(l10n, appointment.status),
              if (appointment.orderNumber != null) '#${appointment.orderNumber}',
              ?appointment.cancelReason,
              money.format(appointment.estimatedTotal),
            ].join(' · '),
            ?appointment.notes,
          ].join('\n'),
        ),
        isThreeLine: true,
        onTap: () => _actions(context, ref),
      ),
    );
  }
}
