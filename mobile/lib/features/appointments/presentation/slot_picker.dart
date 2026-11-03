import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/domain/expense.dart';
import '../data/appointments_repository.dart';

/// The day of a booking and its start time, from the times a visit of [minutes] still fits at the branch.
class SlotPicker extends ConsumerWidget {
  const SlotPicker({
    super.key,
    required this.branchId,
    required this.day,
    required this.minutes,
    required this.appointmentId,
    required this.selected,
    required this.onDayChanged,
    required this.onPicked,
  });

  final String branchId;
  final DateTime day;

  /// How long the chosen services take; nothing is offered before a service is chosen.
  final int minutes;

  /// The booking being changed, whose own place stays free.
  final String? appointmentId;

  /// The chosen start, local `YYYY-MM-DDTHH:MM`.
  final String? selected;
  final ValueChanged<DateTime> onDayChanged;
  final ValueChanged<String> onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(DateTime.now());
    final query = (branchId: branchId, date: apiDate(day), minutes: minutes, appointmentId: appointmentId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.bookingTimeSection, style: theme.textTheme.titleSmall),
        Row(
          children: [
            IconButton(
              tooltip: l10n.previousDay,
              icon: const Icon(Icons.chevron_left),
              onPressed: DateUtils.isSameDay(day, today)
                  ? null
                  : () => onDayChanged(day.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  DateUtils.isSameDay(day, today)
                      ? l10n.today
                      : MaterialLocalizations.of(context).formatMediumDate(day),
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: day,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    onDayChanged(picked);
                  }
                },
              ),
            ),
            IconButton(
              tooltip: l10n.nextDay,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onDayChanged(day.add(const Duration(days: 1))),
            ),
          ],
        ),
        if (minutes == 0)
          Text(l10n.chooseServicesForTimes, style: theme.textTheme.bodySmall)
        else
          switch (ref.watch(appointmentSlotsProvider(query))) {
            AsyncData(:final value) when value.isEmpty => Text(
              l10n.noFreeTimes,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
            AsyncData(:final value) => Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final slot in value)
                  ChoiceChip(
                    label: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay(
                          hour: int.parse(slot.time.substring(0, 2)),
                          minute: int.parse(slot.time.substring(3)),
                        ),
                      ),
                    ),
                    selected: selected == slot.startsAt,
                    onSelected: (_) => onPicked(slot.startsAt),
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorView(
              error: error,
              onRetry: () => ref.invalidate(appointmentSlotsProvider(query)),
            ),
            _ => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
      ],
    );
  }
}
