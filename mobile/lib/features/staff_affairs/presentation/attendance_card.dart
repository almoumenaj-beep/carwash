import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/staff_affairs_repository.dart';

/// Clock in at a branch, or out again, from the home screen. Every staff member uses it for themselves.
class AttendanceCard extends ConsumerStatefulWidget {
  const AttendanceCard({super.key});

  @override
  ConsumerState<AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends ConsumerState<AttendanceCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() change) async {
    setState(() => _busy = true);
    try {
      await change();
      ref.invalidate(myAttendanceProvider);
    } catch (error, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _clockIn() async {
    final branches = ref.read(sessionProvider).value?.branches ?? const [];
    var branchId = branches.length == 1 ? branches.single.id : null;
    if (branches.length > 1) {
      branchId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(AppLocalizations.of(context).clockInAt),
          children: [
            for (final branch in branches)
              SimpleDialogOption(onPressed: () => Navigator.of(context).pop(branch.id), child: Text(branch.name)),
          ],
        ),
      );
    }
    if (branchId != null) {
      await _run(() => ref.read(staffAffairsRepositoryProvider).clockIn(branchId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final record = ref.watch(myAttendanceProvider);
    if (!record.hasValue) {
      return const SizedBox.shrink();
    }

    final open = record.value;
    final since = open == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(open.clockInAt.toLocal()));

    return Card(
      child: ListTile(
        leading: Icon(
          open == null ? Icons.login : Icons.timer_outlined,
          color: open == null ? null : Theme.of(context).colorScheme.primary,
        ),
        title: Text(open == null ? l10n.notClockedIn : l10n.clockedInSince(since!)),
        subtitle: open == null ? null : Text(open.branchName),
        trailing: open == null
            ? FilledButton(onPressed: _busy ? null : _clockIn, child: Text(l10n.clockIn))
            : OutlinedButton(
                onPressed: _busy ? null : () => _run(() => ref.read(staffAffairsRepositoryProvider).clockOut()),
                child: Text(l10n.clockOut),
              ),
      ),
    );
  }
}
