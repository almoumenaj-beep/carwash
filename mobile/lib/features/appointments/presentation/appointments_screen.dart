import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/branch_chips.dart';
import '../../../core/whatsapp/open_whatsapp.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../customers/domain/customer.dart';
import '../../expenses/domain/expense.dart';
import '../../settings/data/settings_repository.dart';
import '../../settings/domain/message_templates.dart';
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

/// The colour a booking's status is shown in; a booking still waiting after its time shows as late.
Color appointmentStatusColor(BuildContext context, AppointmentStatus status, {bool late = false}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final MaterialColor color = late
      ? Colors.orange
      : switch (status) {
          AppointmentStatus.booked => Colors.blue,
          AppointmentStatus.checkedIn => Colors.green,
          AppointmentStatus.cancelled => Colors.grey,
          AppointmentStatus.noShow => Colors.red,
        };
  return dark ? color.shade300 : color.shade700;
}

/// What the list is narrowed to: every booking, one status, or those running late.
typedef _Filter = ({AppointmentStatus? status, bool late});

/// A branch's bookings day by day: book a car in, confirm, change or cancel a booking, and check the car in
/// when it arrives. The day's bookings can be narrowed to one status.
class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  String? _branchId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  _Filter _filter = (status: null, late: false);

  Future<void> _open(Widget screen) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => screen));
    if (changed ?? false) {
      ref.invalidate(appointmentsProvider);
    }
  }

  void _moveTo(DateTime day) => setState(() {
    _day = day;
    _filter = (status: null, late: false);
  });

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
      appBar: AppBar(title: Text(l10n.appointmentsTitle)),
      floatingActionButton: (me?.can(Permissions.appointmentsManage) ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _open(CheckInScreen(branchId: branch.id, booking: true)),
              icon: const Icon(Icons.event_available_outlined),
              label: Text(l10n.newBooking),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(appointmentsProvider(query).future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            BranchChips(
              selected: branch.id,
              includeAll: false,
              onChanged: (id) => setState(() {
                _branchId = id;
                _filter = (status: null, late: false);
              }),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: l10n.previousDay,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _moveTo(_day.subtract(const Duration(days: 1))),
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
                        _moveTo(picked);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _moveTo(_day.add(const Duration(days: 1))),
                ),
              ],
            ),
            switch (ref.watch(appointmentsProvider(query))) {
              AsyncData(:final value) when value.isEmpty => Padding(
                padding: const EdgeInsets.all(48),
                child: Text(l10n.noBookingsThatDay, textAlign: TextAlign.center),
              ),
              AsyncData(:final value) => _DayList(
                appointments: value,
                filter: _filter,
                onFilter: (filter) => setState(() => _filter = filter),
                onCheckIn: (appointment) => _open(CheckInScreen(branchId: branch.id, appointment: appointment)),
                onChange: (appointment) =>
                    _open(CheckInScreen(branchId: branch.id, booking: true, appointment: appointment)),
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

/// The day's bookings under chips counting each status (and those running late), which narrow the list.
class _DayList extends StatelessWidget {
  const _DayList({
    required this.appointments,
    required this.filter,
    required this.onFilter,
    required this.onCheckIn,
    required this.onChange,
  });

  final List<Appointment> appointments;
  final _Filter filter;
  final ValueChanged<_Filter> onFilter;
  final ValueChanged<Appointment> onCheckIn;
  final ValueChanged<Appointment> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final late = appointments.where((appointment) => appointment.isLateAt(now)).length;
    final shown = appointments.where(
      (appointment) =>
          filter.late ? appointment.isLateAt(now) : filter.status == null || appointment.status == filter.status,
    );

    Widget chip(String label, int count, _Filter value, Color? color) => Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: FilterChip(
        avatar: color == null ? null : Icon(Icons.circle, size: 10, color: color),
        label: Text('$label ($count)'),
        selected: filter == value,
        showCheckmark: false,
        onSelected: (_) => onFilter(value),
      ),
    );

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              chip(l10n.allFilter, appointments.length, (status: null, late: false), null),
              // In the order a booking moves through: booked, late, arrived, then the two ways it ends early.
              for (final (status, isLate) in [
                (AppointmentStatus.booked, false),
                (null, true),
                (AppointmentStatus.checkedIn, false),
                (AppointmentStatus.noShow, false),
                (AppointmentStatus.cancelled, false),
              ])
                if ((isLate ? late : appointments.where((appointment) => appointment.status == status).length)
                    case final count when count > 0)
                  chip(isLate ? l10n.appointmentLate : appointmentStatusLabel(l10n, status!), count, (
                    status: status,
                    late: isLate,
                  ), appointmentStatusColor(context, status ?? AppointmentStatus.booked, late: isLate)),
            ],
          ),
        ),
        for (final appointment in shown)
          _AppointmentTile(
            appointment: appointment,
            onCheckIn: () => onCheckIn(appointment),
            onChange: () => onChange(appointment),
          ),
      ],
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
    final hasActions =
        (appointment.isOpen && canCheckIn) ||
        (appointment.isOpen && canManage) ||
        (appointment.isOpen && appointment.customerPhone != null) ||
        (appointment.isLateAt(DateTime.now()) && canManage) ||
        orderId != null;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(l10n.noBookingActions, textAlign: TextAlign.center),
              ),
            if (appointment.isOpen && canCheckIn)
              ListTile(
                leading: const Icon(Icons.local_car_wash_outlined),
                title: Text(l10n.checkInBooking),
                onTap: () {
                  Navigator.of(sheet).pop();
                  onCheckIn();
                },
              ),
            if (appointment.isOpen && appointment.customerPhone != null)
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(l10n.whatsAppRemind),
                onTap: () {
                  final material = MaterialLocalizations.of(context);
                  final startsAt = appointment.startsAt.toLocal();
                  Navigator.of(sheet).pop();
                  openWhatsApp(
                    context,
                    appointment.customerPhone!,
                    (ref.read(settingsProvider).value?.messageTemplates ?? const MessageTemplates()).render(
                      MessageTemplateKind.reminder,
                      {
                        MessageToken.name: appointment.customerName ?? '',
                        MessageToken.plate: appointment.plateNumber ?? '',
                        MessageToken.date: material.formatMediumDate(startsAt),
                        MessageToken.time: material.formatTimeOfDay(TimeOfDay.fromDateTime(startsAt)),
                        MessageToken.carWash: me?.carWashName ?? '',
                      },
                    ),
                  );
                },
              ),
            if (appointment.isOpen && canManage)
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: Text(l10n.changeBooking),
                onTap: () {
                  Navigator.of(sheet).pop();
                  onChange();
                },
              ),
            if (appointment.isLateAt(DateTime.now()) && canManage)
              ListTile(
                leading: const Icon(Icons.person_off_outlined),
                title: Text(l10n.markNoShow),
                onTap: () {
                  Navigator.of(sheet).pop();
                  _run(context, ref, () => ref.read(appointmentsRepositoryProvider).noShow(appointment.id));
                },
              ),
            if (appointment.isOpen && canManage)
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
    // Loads the message templates ahead of the WhatsApp reminder.
    ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(appointment.startsAt.toLocal()));
    final who = [
      ?appointment.customerName,
      if (appointment.customerPhone != null) formatPhone(appointment.customerPhone!),
      ?appointment.plateNumber,
    ];
    final faded = appointment.status == AppointmentStatus.cancelled || appointment.status == AppointmentStatus.noShow;
    final late = appointment.isLateAt(DateTime.now());
    final statusColor = appointmentStatusColor(context, appointment.status, late: late);
    final details = [
      if (appointment.orderNumber != null) '#${appointment.orderNumber}',
      ?appointment.cancelReason,
      money.format(appointment.estimatedTotal),
    ];

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
        subtitle: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${appointment.items.map((item) => item.name).join(' + ')}\n'),
              TextSpan(
                text:
                    '● ${appointmentStatusLabel(l10n, appointment.status)}'
                    '${late ? ' · ${l10n.appointmentLate}' : ''}',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ' · ${details.join(' · ')}'),
              if (appointment.notes != null) TextSpan(text: '\n${appointment.notes}'),
            ],
          ),
        ),
        isThreeLine: true,
        onTap: () => _actions(context, ref),
      ),
    );
  }
}
