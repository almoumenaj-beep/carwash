import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../../shifts/data/shifts_repository.dart';
import '../data/reports_repository.dart';
import '../domain/daily_sales.dart';

/// Cashier shifts the system closed by itself, whose drawer nobody has counted yet. They stay on the report
/// until the owner or a manager enters the cash actually counted.
class UncountedShiftsCard extends ConsumerWidget {
  const UncountedShiftsCard({super.key, required this.shifts});

  final List<UncountedShift> shifts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final money = ref.watch(moneyFormatProvider);
    final me = ref.watch(sessionProvider).value;
    final canCount = (me?.can(Permissions.posCloseShift) ?? false) && (me?.can(Permissions.reportsSales) ?? false);
    final date = MaterialLocalizations.of(context).formatMediumDate;

    return Card(
      color: colors.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(Icons.warning_amber_outlined, color: colors.onErrorContainer),
            title: Text(l10n.uncountedShiftsTitle, style: TextStyle(color: colors.onErrorContainer)),
          ),
          for (final shift in shifts)
            ListTile(
              textColor: colors.onErrorContainer,
              title: Text('${shift.openedBy} · ${shift.branchName}'),
              subtitle: Text(
                '${date(shift.closedAt.toLocal())}\n${l10n.expectedCash}: ${money.format(shift.expectedCash)}',
              ),
              isThreeLine: true,
              trailing: canCount
                  ? FilledButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => _CountDialog(shift: shift),
                      ),
                      child: Text(l10n.enterCount),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

class _CountDialog extends ConsumerStatefulWidget {
  const _CountDialog({required this.shift});

  final UncountedShift shift;

  @override
  ConsumerState<_CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends ConsumerState<_CountDialog> {
  final _counted = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save(int counted) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = _note.text.trim();
      await ref.read(shiftsRepositoryProvider).count(widget.shift.id, counted, note: note.isEmpty ? null : note);
      ref.invalidate(dailySalesProvider);
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
    final colors = Theme.of(context).colorScheme;
    final money = ref.watch(moneyFormatProvider);
    final expected = widget.shift.expectedCash;
    final counted = _counted.text.trim().isEmpty ? null : money.parse(_counted.text);
    final variance = counted == null ? null : counted - expected;
    final noteMissing = variance != null && variance != 0 && _note.text.trim().isEmpty;

    return AlertDialog(
      title: Text(l10n.enterCount),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${l10n.expectedCash}: ${money.format(expected)}'),
            const SizedBox(height: 12),
            TextField(
              controller: _counted,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
              decoration: InputDecoration(labelText: l10n.countedCashField, suffixText: money.currency),
              onChanged: (_) => setState(() {}),
            ),
            if (variance != null) ...[
              const SizedBox(height: 8),
              Text(
                variance == 0
                    ? l10n.drawerMatches
                    : (variance < 0
                          ? l10n.drawerShort(money.format(-variance))
                          : l10n.drawerOver(money.format(variance))),
                style: TextStyle(color: variance == 0 ? colors.primary : colors.error),
              ),
            ],
            if (variance != null && variance != 0) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _note,
                maxLength: 255,
                decoration: InputDecoration(labelText: l10n.varianceNoteField),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_error != null) Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _saving || counted == null || noteMissing ? null : () => _save(counted),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
