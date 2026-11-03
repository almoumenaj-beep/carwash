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

/// Staff affairs: pay terms and advances, a branch's attendance for a day, and monthly payroll. Each tab shows
/// only to staff with the permission behind it.
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
      if (canView) (Tab(text: l10n.attendanceTab), const _Attendance()),
      if (canView) (Tab(text: l10n.advancesTab), const _Advances()),
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
                title: Row(
                  children: [
                    Flexible(child: Text(employee.name)),
                    if (employee.clockedInAt != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
                    ],
                  ],
                ),
                subtitle: Text(
                  [
                    if (employee.monthlySalary > 0) l10n.salaryLabel(money.format(employee.monthlySalary)),
                    commissionLabel(l10n, money, employee),
                    if (employee.outstandingAdvances > 0) l10n.advancesOwed(money.format(employee.outstandingAdvances)),
                  ].join(' · '),
                ),
                trailing: canManage
                    ? IconButton(
                        tooltip: l10n.giveAdvance,
                        icon: const Icon(Icons.payments_outlined),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _AdvanceDialog(employee: employee),
                        ),
                      )
                    : null,
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
  late CommissionType _type = widget.employee.commissionType;
  late final _value = TextEditingController(
    text: switch (widget.employee.commissionType) {
      CommissionType.none => '',
      CommissionType.perCar => ref.read(moneyFormatProvider).toInput(widget.employee.commissionValue),
      CommissionType.percent => PercentFormat.format(widget.employee.commissionValue),
    },
  );
  String? _error;

  @override
  void dispose() {
    _salary.dispose();
    _value.dispose();
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
          .savePayTerms(widget.employee.id, salary: salary, type: _type, value: value);
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
            TextField(
              controller: _salary,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.monthlySalaryField, suffixText: money.currency),
            ),
            const SizedBox(height: 16),
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

/// Gives an advance, recorded as an expense of a branch and deducted from the next payroll.
class _AdvanceDialog extends ConsumerStatefulWidget {
  const _AdvanceDialog({required this.employee});

  final Employee employee;

  @override
  ConsumerState<_AdvanceDialog> createState() => _AdvanceDialogState();
}

class _AdvanceDialogState extends ConsumerState<_AdvanceDialog> {
  final _amount = TextEditingController();
  ExpensePaymentMethod _method = ExpensePaymentMethod.cash;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(String branchId, String? categoryId) async {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    final amount = money.parse(_amount.text);
    if (amount == null || amount <= 0 || categoryId == null) {
      setState(() => _error = l10n.amountInvalid(money.toInput(2500)));
      return;
    }
    try {
      await ref.read(staffAffairsRepositoryProvider).giveAdvance({
        'user_id': widget.employee.id,
        'branch_id': branchId,
        'amount': amount,
        'expense_category_id': categoryId,
        'payment_method': _method.apiValue,
      });
      ref.invalidate(employeesProvider);
      ref.invalidate(salaryAdvancesProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final categories = ref.watch(expenseCategoriesProvider).value ?? const <ExpenseCategory>[];
    final category = wagesCategory(categories);

    return AlertDialog(
      title: Text('${l10n.giveAdvance} · ${widget.employee.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.amountField, suffixText: money.currency),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final method in ExpensePaymentMethod.values)
                ChoiceChip(
                  label: Text(paymentMethodLabel(l10n, method)),
                  selected: _method == method,
                  onSelected: (_) => setState(() => _method = method),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.advanceHint, style: Theme.of(context).textTheme.bodySmall),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: branches.isEmpty ? null : () => _save(branches.first.id, category?.id),
          child: Text(l10n.save),
        ),
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

class _Attendance extends ConsumerStatefulWidget {
  const _Attendance();

  @override
  ConsumerState<_Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends ConsumerState<_Attendance> {
  String? _branchId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;
    if (branch == null) {
      return Center(child: Text(l10n.noBranchAssigned));
    }

    final records = ref.watch(branchAttendanceProvider((branchId: branch.id, date: apiDate(_day))));
    String time(DateTime at) => MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(at.toLocal()));

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))),
            ),
            Expanded(
              child: Text(
                MaterialLocalizations.of(context).formatMediumDate(_day),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: DateUtils.isSameDay(_day, DateTime.now())
                  ? null
                  : () => setState(() => _day = _day.add(const Duration(days: 1))),
            ),
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
        switch (records) {
          AsyncData(:final value) when value.isEmpty => Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l10n.noAttendance, textAlign: TextAlign.center),
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final record in value)
                ListTile(
                  leading: Icon(record.clockOutAt == null ? Icons.timer_outlined : Icons.check_circle_outline),
                  title: Text(record.userName),
                  subtitle: Text(
                    record.clockOutAt == null
                        ? l10n.stillAtWork(time(record.clockInAt))
                        : '${time(record.clockInAt)} → ${time(record.clockOutAt!)}',
                  ),
                  trailing: Text(l10n.hoursWorked((record.minutes / 60).toStringAsFixed(1))),
                ),
            ],
          ),
          AsyncError(:final error) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(branchAttendanceProvider((branchId: branch.id, date: apiDate(_day)))),
          ),
          _ => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _Advances extends ConsumerWidget {
  const _Advances();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return switch (ref.watch(salaryAdvancesProvider)) {
      AsyncData(:final value) when value.isEmpty => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.noAdvances, textAlign: TextAlign.center),
        ),
      ),
      AsyncData(:final value) => ListView(
        children: [
          for (final advance in value)
            ListTile(
              leading: Icon(advance.isDeducted ? Icons.check_circle_outline : Icons.schedule),
              title: Text(advance.userName),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatMediumDate(advance.givenOn)} · '
                '${advance.isDeducted ? l10n.advanceDeducted : l10n.advanceOutstanding}',
              ),
              trailing: Text(money.format(advance.amount)),
            ),
        ],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(salaryAdvancesProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
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
      ref.invalidate(salaryAdvancesProvider);
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
                          if (line.advances > 0) l10n.advancesDeducted(money.format(line.advances)),
                        ].join(' · '),
                      ),
                      trailing: Text(money.format(line.net), style: Theme.of(context).textTheme.titleSmall),
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
