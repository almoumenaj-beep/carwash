import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/can.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';
import 'expense_categories_screen.dart';
import 'expense_editor_screen.dart';
import 'expense_widgets.dart';
import 'recurring_expense_editor_screen.dart';

/// Expenses in four tabs: this month's (or last month's), what is still owed, suppliers with their balances,
/// and recurring expenses. Recording needs expenses.create; paying and managing need expenses.approve.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  /// 0 for this month, 1 for last month.
  int _monthsBack = 0;

  void _refreshAll() {
    ref.invalidate(expensesProvider);
    ref.invalidate(suppliersProvider);
    ref.invalidate(recurringExpensesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canApprove = ref.watch(sessionProvider).value?.can(Permissions.expensesApprove) ?? false;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.expensesTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.expensesTitle),
              Tab(text: l10n.owedTab),
              Tab(text: l10n.suppliersTab),
              Tab(text: l10n.recurringTab),
            ],
          ),
        ),
        floatingActionButton: Can(
          anyOf: const [Permissions.expensesCreate],
          child: FloatingActionButton.extended(
            onPressed: () async {
              final saved = await Navigator.of(context)
                  .push<bool>(MaterialPageRoute(builder: (_) => const ExpenseEditorScreen()));
              if (saved == true) {
                _refreshAll();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.newExpense),
          ),
        ),
        body: TabBarView(
          children: [
            _ExpenseList(
              unpaid: false,
              showCategories: canApprove,
              monthsBack: _monthsBack,
              onMonthChanged: (back) => setState(() => _monthsBack = back),
              onChanged: _refreshAll,
            ),
            _ExpenseList(unpaid: true, monthsBack: 0, onMonthChanged: null, onChanged: _refreshAll),
            _Suppliers(canManage: canApprove),
            _Recurring(canManage: canApprove),
          ],
        ),
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({
    required this.unpaid,
    required this.monthsBack,
    required this.onMonthChanged,
    required this.onChanged,
    this.showCategories = false,
  });

  final bool unpaid;

  /// Whether to offer managing the categories above the list.
  final bool showCategories;
  final int monthsBack;
  final ValueChanged<int>? onMonthChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final now = DateTime.now();
    final first = DateTime(now.year, now.month - monthsBack);
    final last = monthsBack == 0 ? DateUtils.dateOnly(now) : DateTime(now.year, now.month - monthsBack + 1, 0);
    final query = (
      branchId: null,
      from: unpaid ? null : apiDate(first),
      to: unpaid ? null : apiDate(last),
      unpaid: unpaid,
    );
    final result = ref.watch(expensesProvider(query));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(expensesProvider(query).future),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (showCategories)
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.manageCategories),
                subtitle: Text(l10n.manageCategoriesHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const ExpenseCategoriesScreen())),
              ),
            ),
          if (onMonthChanged != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(l10n.thisMonth)),
                  ButtonSegment(value: 1, label: Text(l10n.lastMonth)),
                ],
                selected: {monthsBack},
                onSelectionChanged: (selection) => onMonthChanged!(selection.single),
              ),
            ),
          switch (result) {
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  title: Text(
                    unpaid ? l10n.totalOwed : l10n.totalSpent,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: Text(money.format(value.total), style: Theme.of(context).textTheme.titleMedium),
                ),
                if (value.expenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(unpaid ? l10n.nothingOwed : l10n.noExpenses, textAlign: TextAlign.center),
                  ),
                for (final expense in value.expenses) _ExpenseTile(expense: expense, onChanged: onChanged),
              ],
            ),
            AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(expensesProvider(query))),
            _ => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({required this.expense, required this.onChanged});

  final Expense expense;
  final VoidCallback onChanged;

  Future<void> _run(BuildContext context, Future<void> Function() change) async {
    try {
      await change();
      onChanged();
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final canApprove = ref.watch(sessionProvider).value?.can(Permissions.expensesApprove) ?? false;
    final repository = ref.read(expensesRepositoryProvider);
    final details = [
      MaterialLocalizations.of(context).formatMediumDate(expense.spentOn),
      ?expense.supplier?.name,
      paymentMethodLabel(l10n, expense.paymentMethod),
      if (expense.isRecurring) l10n.recurringBadge,
      if (expense.source == 'purchase') l10n.sourcePurchase,
      if (expense.source == 'payroll') l10n.sourcePayroll,
      if (expense.source == 'maintenance') l10n.sourceMaintenance,
      ?expense.description,
    ];

    return ListTile(
      leading: Icon(
        expense.isPaid ? Icons.receipt_outlined : Icons.schedule,
        color: expense.isPaid ? null : Theme.of(context).colorScheme.error,
      ),
      title: Text(expense.category.name),
      subtitle: Text(details.join(' · ')),
      trailing: Text(money.format(expense.amount), style: Theme.of(context).textTheme.titleSmall),
      // An expense from a purchase, payroll or maintenance is managed from there.
      onLongPress: !canApprove || expense.source != null
          ? null
          : () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text(l10n.deleteEntryConfirm(expense.category.name)),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
                    FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await _run(context, () => repository.delete(expense.id));
              }
            },
      onTap: expense.isPaid || !canApprove
          ? null
          : () async {
              final method = await askPaymentMethod(context);
              if (method != null && context.mounted) {
                await _run(context, () => repository.pay(expense.id, method));
              }
            },
    );
  }
}

class _Suppliers extends ConsumerWidget {
  const _Suppliers({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final suppliers = ref.watch(suppliersProvider);

    Future<void> edit(Supplier? supplier) async {
      final saved = await showDialog<bool>(
        context: context,
        builder: (_) => _SupplierDialog(supplier: supplier),
      );
      if (saved == true) {
        ref.invalidate(suppliersProvider);
      }
    }

    return switch (suppliers) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (canManage)
            ListTile(leading: const Icon(Icons.add), title: Text(l10n.addSupplier), onTap: () => edit(null)),
          if (value.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noSuppliers, textAlign: TextAlign.center),
            ),
          for (final supplier in value)
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(supplier.isActive ? supplier.name : '${supplier.name} (${l10n.inactiveLabel})'),
              subtitle: supplier.phone == null ? null : Text(supplier.phone!, textDirection: TextDirection.ltr),
              trailing: supplier.owed > 0
                  ? Text(
                      l10n.owedAmount(money.format(supplier.owed)),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                  : null,
              onTap: canManage ? () => edit(supplier) : null,
            ),
        ],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(suppliersProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _SupplierDialog extends ConsumerStatefulWidget {
  const _SupplierDialog({required this.supplier});

  final Supplier? supplier;

  @override
  ConsumerState<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends ConsumerState<_SupplierDialog> {
  late final _name = TextEditingController(text: widget.supplier?.name);
  late final _phone = TextEditingController(text: widget.supplier?.phone);
  late bool _active = widget.supplier?.isActive ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await ref.read(expensesRepositoryProvider).saveSupplier(widget.supplier?.id, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'is_active': _active,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
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

    return AlertDialog(
      title: Text(widget.supplier == null ? l10n.addSupplier : widget.supplier!.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.nameField),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l10n.phoneField),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.activeSwitch),
            value: _active,
            onChanged: (value) => setState(() => _active = value),
          ),
          if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

class _Recurring extends ConsumerWidget {
  const _Recurring({required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final schedules = ref.watch(recurringExpensesProvider);

    Future<void> edit(RecurringExpense? schedule) async {
      final saved = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => RecurringExpenseEditorScreen(schedule: schedule)));
      if (saved == true) {
        ref.invalidate(recurringExpensesProvider);
      }
    }

    return switch (schedules) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (canManage)
            ListTile(leading: const Icon(Icons.add), title: Text(l10n.addRecurring), onTap: () => edit(null)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l10n.recurringHint, style: Theme.of(context).textTheme.bodySmall),
          ),
          if (value.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noRecurring, textAlign: TextAlign.center),
            ),
          for (final schedule in value)
            ListTile(
              leading: Icon(schedule.isActive ? Icons.event_repeat : Icons.pause_circle_outline),
              title: Text(schedule.description ?? schedule.category.name),
              subtitle: Text(
                [
                  frequencyLabel(l10n, schedule.frequency),
                  l10n.nextDue(MaterialLocalizations.of(context).formatMediumDate(schedule.nextDueOn)),
                  ?schedule.supplier?.name,
                ].join(' · '),
              ),
              trailing: Text(money.format(schedule.amount)),
              onTap: canManage ? () => edit(schedule) : null,
            ),
        ],
      ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(recurringExpensesProvider)),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
