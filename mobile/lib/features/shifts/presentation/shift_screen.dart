import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/branch_chips.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/shifts_repository.dart';
import '../domain/cash_shift.dart';

/// The cashier's till at a branch: open a shift with the float in the drawer, follow the cash taken, and close
/// it by counting the drawer against what is expected.
class ShiftScreen extends ConsumerStatefulWidget {
  const ShiftScreen({super.key, this.branchId});

  /// The branch to start on (e.g. from checkout); the cashier's first branch otherwise.
  final String? branchId;

  @override
  ConsumerState<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends ConsumerState<ShiftScreen> {
  late String? _branchId = widget.branchId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.shiftTitle)),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    final shift = ref.watch(currentShiftProvider(branch.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shiftTitle)),
      body: Column(
        children: [
          BranchChips(selected: branch.id, includeAll: false, onChanged: (id) => setState(() => _branchId = id)),
          Expanded(
            child: switch (shift) {
              AsyncData(value: null) => _OpenShiftForm(key: ValueKey('open-${branch.id}'), branchId: branch.id),
              AsyncData(value: final CashShift shift) => _OpenShift(key: ValueKey(shift.id), shift: shift),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(currentShiftProvider(branch.id)),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// A money field that accepts Arabic digits and separators.
TextField _amountField(
  MoneyFormat money,
  TextEditingController controller,
  String label, {
  String? error,
  VoidCallback? onChanged,
}) => TextField(
  controller: controller,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
  decoration: InputDecoration(labelText: label, suffixText: money.currency, errorText: error),
  onChanged: onChanged == null ? null : (_) => onChanged(),
);

String? _requestError(BuildContext context, ApiProblem? problem) {
  if (problem == null) {
    return null;
  }
  return problem.errors.values.firstOrNull?.first ?? problemMessage(context, problem);
}

class _OpenShiftForm extends ConsumerStatefulWidget {
  const _OpenShiftForm({super.key, required this.branchId});

  final String branchId;

  @override
  ConsumerState<_OpenShiftForm> createState() => _OpenShiftFormState();
}

class _OpenShiftFormState extends ConsumerState<_OpenShiftForm> {
  final _float = TextEditingController();
  bool _saving = false;
  ApiProblem? _problem;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final money = ref.read(moneyFormatProvider);
    final float = _float.text.trim().isEmpty ? 0 : money.parse(_float.text);
    if (float == null) {
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      await ref.read(shiftsRepositoryProvider).open(widget.branchId, float);
      ref.invalidate(currentShiftProvider(widget.branchId));
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
    final money = ref.watch(moneyFormatProvider);
    final invalid = _float.text.trim().isNotEmpty && money.parse(_float.text) == null;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.point_of_sale_outlined, size: 64),
        const SizedBox(height: 16),
        Text(l10n.noOpenShift, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        _amountField(
          money,
          _float,
          l10n.openingFloatField,
          error: invalid ? l10n.amountInvalid(money.toInput(2500)) : _requestError(context, _problem),
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        Text(l10n.openingFloatHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving || invalid ? null : _open,
          icon: const Icon(Icons.lock_open_outlined),
          label: Text(l10n.openShift),
        ),
      ],
    );
  }
}

class _OpenShift extends ConsumerStatefulWidget {
  const _OpenShift({super.key, required this.shift});

  final CashShift shift;

  @override
  ConsumerState<_OpenShift> createState() => _OpenShiftState();
}

class _OpenShiftState extends ConsumerState<_OpenShift> {
  final _counted = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  ApiProblem? _problem;

  @override
  void dispose() {
    _counted.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _close(int counted) async {
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final note = _note.text.trim();
      final closed = await ref
          .read(shiftsRepositoryProvider)
          .close(widget.shift.id, counted, note: note.isEmpty ? null : note);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => _ClosedDialog(shift: closed),
        );
      }
      ref.invalidate(currentShiftProvider(widget.shift.branchId));
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
    final shift = widget.shift;
    final counted = _counted.text.trim().isEmpty ? null : money.parse(_counted.text);
    final variance = counted == null ? null : counted - shift.expectedCash;
    final noteMissing = variance != null && variance != 0 && _note.text.trim().isEmpty;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(shift.openedAt.toLocal()));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(currentShiftProvider(shift.branchId).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.lock_open_outlined, color: theme.colorScheme.primary),
                  title: Text(l10n.shiftOpenSince(time)),
                  subtitle: Text(shift.openedBy.name),
                ),
                const Divider(height: 1),
                _SummaryRow(label: l10n.openingFloatField, value: money.format(shift.openingFloat)),
                _SummaryRow(label: l10n.shiftInvoices, value: '${shift.invoicesCount}'),
                _SummaryRow(label: l10n.shiftCashTaken, value: money.format(shift.cashTaken)),
                if (shift.cardTaken > 0) _SummaryRow(label: l10n.shiftCardTaken, value: money.format(shift.cardTaken)),
                if (shift.benefitTaken > 0)
                  _SummaryRow(label: l10n.shiftBenefitTaken, value: money.format(shift.benefitTaken)),
                if (shift.cashPaidOut > 0)
                  _SummaryRow(label: l10n.cashPaidOut, value: '- ${money.format(shift.cashPaidOut)}'),
                if (shift.discountsTotal > 0)
                  _SummaryRow(label: l10n.shiftDiscounts, value: money.format(shift.discountsTotal)),
                const Divider(height: 1),
                _SummaryRow(label: l10n.expectedCash, value: money.format(shift.expectedCash), strong: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.closeShift, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _amountField(
            money,
            _counted,
            l10n.countedCashField,
            error: _counted.text.trim().isNotEmpty && counted == null ? l10n.amountInvalid(money.toInput(2500)) : null,
            onChanged: () => setState(() {}),
          ),
          if (variance != null) ...[
            const SizedBox(height: 12),
            Text(
              variance == 0
                  ? l10n.drawerMatches
                  : (variance < 0
                        ? l10n.drawerShort(money.format(-variance))
                        : l10n.drawerOver(money.format(variance))),
              style: theme.textTheme.titleMedium?.copyWith(
                color: variance == 0 ? theme.colorScheme.primary : theme.colorScheme.error,
              ),
            ),
          ],
          if (variance != null && variance != 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 255,
              decoration: InputDecoration(
                labelText: l10n.varianceNoteField,
                errorText: noteMissing ? l10n.fieldRequired : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_requestError(context, _problem) case final error?) ...[
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving || counted == null || noteMissing ? null : () => _close(counted),
            icon: const Icon(Icons.lock_outline),
            label: Text(l10n.closeShift),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? Theme.of(context).textTheme.titleMedium : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ClosedDialog extends ConsumerWidget {
  const _ClosedDialog({required this.shift});

  final CashShift shift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final variance = shift.variance ?? 0;

    return AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 48),
      title: Text(l10n.shiftClosed),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(label: l10n.shiftInvoices, value: '${shift.invoicesCount}'),
          _SummaryRow(label: l10n.shiftCashTaken, value: money.format(shift.cashTaken)),
          if (shift.cardTaken > 0) _SummaryRow(label: l10n.shiftCardTaken, value: money.format(shift.cardTaken)),
          if (shift.benefitTaken > 0)
            _SummaryRow(label: l10n.shiftBenefitTaken, value: money.format(shift.benefitTaken)),
          if (shift.cashPaidOut > 0)
            _SummaryRow(label: l10n.cashPaidOut, value: '- ${money.format(shift.cashPaidOut)}'),
          _SummaryRow(label: l10n.expectedCash, value: money.format(shift.expectedCash)),
          _SummaryRow(label: l10n.countedCashField, value: money.format(shift.countedCash ?? 0)),
          _SummaryRow(
            label: l10n.varianceLabel,
            value: variance == 0 ? l10n.drawerMatches : money.format(variance),
            strong: true,
          ),
        ],
      ),
      actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.done))],
    );
  }
}
