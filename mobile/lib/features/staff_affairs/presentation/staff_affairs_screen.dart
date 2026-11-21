import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/money/percent_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/staff_affairs_repository.dart';
import '../domain/staff_affairs.dart';

/// Staff affairs: pay terms, ad-hoc daily wages and monthly payroll. Each tab shows only to staff
/// with the permission behind it.
class StaffAffairsScreen extends ConsumerWidget {
  const StaffAffairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(sessionProvider).value;
    final canView = me?.can(Permissions.employeesView) ?? false;
    final canPayroll = me?.can(Permissions.payrollView) ?? false;
    final tabs = [
      if (canView) (Tab(text: l10n.employeesTab), const _Employees()),
      if (canPayroll) (Tab(text: l10n.payrollTab), const _Payroll()),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.staffAffairsTitle),
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final tab in tabs) tab.$1]),
        ),
        body: TabBarView(children: [for (final tab in tabs) tab.$2]),
      ),
    );
  }
}

String commissionLabel(AppLocalizations l10n, MoneyFormat money, Employee employee) =>
    switch (employee.commissionType) {
      CommissionType.none => l10n.noCommission,
      CommissionType.perCar => l10n.commissionPerCar(money.format(employee.commissionValue)),
      CommissionType.percent => l10n.commissionPercent(PercentFormat.format(employee.commissionValue)),
    };

/// The pay line under an employee's name: the monthly salary, or this month's daily wages.
String payLabel(AppLocalizations l10n, MoneyFormat money, Employee employee) => switch (employee.salaryType) {
  SalaryType.monthly => employee.monthlySalary > 0 ? l10n.salaryLabel(money.format(employee.monthlySalary)) : '',
  SalaryType.daily => l10n.dailyWagesThisMonth(money.format(employee.dailyWagesThisMonth)),
};

class _Employees extends ConsumerWidget {
  const _Employees();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final canManage = ref.watch(sessionProvider).value?.can(Permissions.employeesManage) ?? false;

    return switch (ref.watch(employeesProvider)) {
      AsyncData(:final value) => RefreshIndicator(
        onRefresh: () => ref.refresh(employeesProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            for (final employee in value)
              ListTile(
                leading: CircleAvatar(child: Text(employee.name.characters.first)),
                title: Text(employee.name),
                subtitle: Text(
                  [payLabel(l10n, money, employee), commissionLabel(l10n, money, employee)]
                      .where((line) => line.isNotEmpty)
                      .join(' · '),
                ),
                onTap: canManage
                    ? () => showDialog<void>(
                        context: context,
                        builder: (_) => _PayTermsDialog(employee: employee),
                      )
                    : null,
              ),
          ],
        ),
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(employeesProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PayTermsDialog extends ConsumerStatefulWidget {
  const _PayTermsDialog({required this.employee});

  final Employee employee;

  @override
  ConsumerState<_PayTermsDialog> createState() => _PayTermsDialogState();
}

class _PayTermsDialogState extends ConsumerState<_PayTermsDialog> {
  late final _salary = TextEditingController(
    text: ref.read(moneyFormatProvider).toInput(widget.employee.monthlySalary),
  );
  late SalaryType _salaryType = widget.employee.salaryType;
  late CommissionType _type = widget.employee.commissionType;
  late final _value = TextEditingController(
    text: switch (widget.employee.commissionType) {
      CommissionType.none => '',
      CommissionType.perCar => ref.read(moneyFormatProvider).toInput(widget.employee.commissionValue),
      CommissionType.percent => PercentFormat.format(widget.employee.commissionValue),
    },
  );
  late final _dailyWage = TextEditingController();
  bool _recording = false;
  String? _error;

  @override
  void dispose() {
    _salary.dispose();
    _value.dispose();
    _dailyWage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    final salary = _salary.text.trim().isEmpty ? 0 : money.parse(_salary.text);
    final value = switch (_type) {
      CommissionType.none => 0,
      CommissionType.perCar => money.parse(_value.text),
      CommissionType.percent => PercentFormat.parse(_value.text),
    };
    if (salary == null || value == null) {
      setState(() => _error = l10n.amountInvalid(money.toInput(2500)));
      return;
    }
    try {
      await ref
          .read(staffAffairsRepositoryProvider)
          .savePayTerms(widget.employee.id, salary: salary, salaryType: _salaryType, type: _type, value: value);
      ref.invalidate(employeesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    }
  }

  /// Pays a day's wage for a daily-paid employee: asks how it was paid, then records it as a wages expense.
  Future<void> _recordDailyWage() async {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    final amount = money.parse(_dailyWage.text);
    if (amount == null) {
      setState(() => _error = l10n.amountInvalid(money.toInput(10)));
      return;
    }
    final method = await askPaymentMethod(context);
    if (method == null || !mounted) {
      return;
    }
    final branches = ref.read(sessionProvider).value?.branches ?? const <BranchSummary>[];
    if (branches.isEmpty) {
      setState(() => _error = l10n.noBranchAssigned);
      return;
    }
    setState(() => _recording = true);
    try {
      await ref
          .read(staffAffairsRepositoryProvider)
          .recordDailyWage(widget.employee.id, amount: amount, branchId: branches.first.id, paymentMethod: method.apiValue);
      ref.invalidate(employeesProvider);
      _dailyWage.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.dailyWageRecorded)));
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    } finally {
      if (mounted) {
        setState(() => _recording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return AlertDialog(
      title: Text(widget.employee.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<SalaryType>(
              segments: [
                ButtonSegment(value: SalaryType.monthly, label: Text(l10n.salaryTypeMonthly)),
                ButtonSegment(value: SalaryType.daily, label: Text(l10n.salaryTypeDaily)),
              ],
              selected: {_salaryType},
              onSelectionChanged: (selection) => setState(() => _salaryType = selection.single),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salary,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _salaryType == SalaryType.monthly ? l10n.monthlySalaryField : l10n.dailyRateField,
                suffixText: money.currency,
              ),
            ),
            if (_salaryType == SalaryType.daily) ...[
              const SizedBox(height: 16),
              Text(l10n.dailyWageRecordTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dailyWage,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.dailyWageAmountField, suffixText: money.currency),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _recording ? null : _recordDailyWage,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l10n.recordDailyWage),
                  ),
                ],
              ),
            ],
            Text(l10n.commissionField, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<CommissionType>(
              segments: [
                ButtonSegment(value: CommissionType.none, label: Text(l10n.noCommissionShort)),
                ButtonSegment(value: CommissionType.perCar, label: Text(l10n.perCarShort)),
                const ButtonSegment(value: CommissionType.percent, label: Text('%')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) => setState(() {
                _type = selection.single;
                _value.clear();
              }),
            ),
            if (_type != CommissionType.none) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _type == CommissionType.perCar ? l10n.perCarField : l10n.percentOfCarField,
                  suffixText: _type == CommissionType.perCar ? money.currency : '%',
                  helperText: l10n.commissionSplitHint,
                ),
              ),
            ],
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

/// The category wages are recorded under: "Wages" (or the Arabic default) when it exists, else the first one.
ExpenseCategory? wagesCategory(List<ExpenseCategory> categories) {
  final active = categories.where((category) => category.isActive).toList();
  return active
          .where((category) => category.name.contains('رواتب') || category.name.toLowerCase().contains('wage'))
          .firstOrNull ??
      active.firstOrNull;
}

class _Payroll extends ConsumerStatefulWidget {
  const _Payroll();

  @override
  ConsumerState<_Payroll> createState() => _PayrollState();
}

class _PayrollState extends ConsumerState<_Payroll> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() change) async {
    setState(() => _busy = true);
    try {
      await change();
      ref.invalidate(payrollRunsProvider);
      ref.invalidate(employeesProvider);
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

  Future<void> _calculate({required bool lastMonth}) async {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - (lastMonth ? 1 : 0));
    await _run(() => ref.read(staffAffairsRepositoryProvider).calculatePayroll(month.year, month.month));
  }

  /// Asks first, since it takes the payment back out of the expenses.
  Future<void> _cancelPayment(PayrollRun run) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.cancelPayrollPayment),
        content: Text(l10n.cancelPayrollPaymentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.back)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.cancelPayrollPayment)),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => ref.read(staffAffairsRepositoryProvider).cancelPayrollPayment(run.id));
    }
  }

  Future<void> _pay(PayrollRun run) async {
    final l10n = AppLocalizations.of(context);
    final method = await askPaymentMethod(context);
    if (method == null || !mounted) {
      return;
    }
    final branches = ref.read(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final category = wagesCategory(await ref.read(expenseCategoriesProvider.future));
    if (branches.isEmpty || category == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.unexpectedError)));
      }
      return;
    }
    await _run(
      () => ref.read(staffAffairsRepositoryProvider).payPayroll(run.id, {
        'branch_id': branches.first.id,
        'expense_category_id': category.id,
        'payment_method': method.apiValue,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final canRun = ref.watch(sessionProvider).value?.can(Permissions.payrollRun) ?? false;
    final canCancelPayment = canRun && (ref.watch(sessionProvider).value?.can(Permissions.expensesApprove) ?? false);

    return switch (ref.watch(payrollRunsProvider)) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (canRun)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _calculate(lastMonth: false),
                    icon: const Icon(Icons.calculate_outlined),
                    label: Text(l10n.calculateThisMonth),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _calculate(lastMonth: true),
                    child: Text(l10n.calculateLastMonth),
                  ),
                ],
              ),
            ),
          if (value.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noPayroll, textAlign: TextAlign.center),
            ),
          for (final run in value)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ExpansionTile(
                initiallyExpanded: !run.isPaid,
                leading: Icon(run.isPaid ? Icons.check_circle_outline : Icons.edit_note),
                title: Text('${run.month}/${run.year}'),
                subtitle: Text(run.isPaid ? l10n.payrollPaid : l10n.payrollDraft),
                trailing: Text(money.format(run.totalNet), style: Theme.of(context).textTheme.titleSmall),
                children: [
                  for (final line in run.lines)
                    ListTile(
                      dense: true,
                      title: Text(line.name),
                      subtitle: Text(
                        [
                          l10n.salaryLabel(money.format(line.baseSalary)),
                          if (line.carsCount > 0) l10n.carsCount(line.carsCount),
                          if (line.commission > 0) l10n.commissionAmount(money.format(line.commission)),
                        ].join(' · '),
                      ),
                      trailing: Text(money.format(line.net), style: Theme.of(context).textTheme.titleSmall),
                    ),
                  if (run.isPaid && canCancelPayment)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : () => _cancelPayment(run),
                        icon: const Icon(Icons.undo),
                        label: Text(l10n.cancelPayrollPayment),
                      ),
                    ),
                  if (!run.isPaid && canRun)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton.icon(
                        onPressed: _busy || run.lines.isEmpty ? null : () => _pay(run),
                        icon: const Icon(Icons.payments_outlined),
                        label: Text(l10n.payPayroll),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(payrollRunsProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
