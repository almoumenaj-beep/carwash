import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/money/percent_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../expenses/domain/expense.dart';
import '../data/reports_repository.dart';
import '../domain/financial_reports.dart';
import 'daily_sales_screen.dart';

/// A payment method from the API (`cash`, `cash_drawer`...) in words.
String moneyMethodLabel(AppLocalizations l10n, String method) => switch (method) {
  'cash' => l10n.payCash,
  'cash_drawer' => l10n.payFromDrawer,
  'card' => l10n.payCard,
  'bank_transfer' => l10n.payBankTransfer,
  _ => method,
};

/// The quick periods offered above the reports.
enum _Period { thisMonth, lastMonth, thisYear, custom }

/// Profit and loss, cash flow and profitability for the owner and accountant, over a period at one branch
/// or all of them.
class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends ConsumerState<FinancialReportsScreen> {
  /// Null for every branch.
  String? _branchId;
  _Period _period = _Period.thisMonth;
  late DateTimeRange _range = _rangeFor(_Period.thisMonth);

  DateTimeRange _rangeFor(_Period period) {
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (period) {
      _Period.thisMonth => DateTimeRange(start: DateTime(today.year, today.month), end: today),
      _Period.lastMonth => DateTimeRange(
        start: DateTime(today.year, today.month - 1),
        end: DateTime(today.year, today.month, 0),
      ),
      _Period.thisYear => DateTimeRange(start: DateTime(today.year), end: today),
      _Period.custom => _range,
    };
  }

  Future<void> _choose(_Period period) async {
    if (period != _Period.custom) {
      setState(() {
        _period = period;
        _range = _rangeFor(period);
      });
      return;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2024),
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        _period = _Period.custom;
        _range = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final period = (branchId: _branchId, from: apiDate(_range.start), to: apiDate(_range.end));
    final date = MaterialLocalizations.of(context).formatMediumDate;
    final branchName = branches.where((branch) => branch.id == _branchId).firstOrNull?.name ?? l10n.allBranches;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.financialReportsTitle),
          actions: [
            if (branches.length > 1)
              PopupMenuButton<String>(
                icon: const Icon(Icons.store_outlined),
                initialValue: _branchId ?? '',
                onSelected: (id) => setState(() => _branchId = id.isEmpty ? null : id),
                itemBuilder: (_) => [
                  PopupMenuItem(value: '', child: Text(l10n.allBranches)),
                  for (final branch in branches) PopupMenuItem(value: branch.id, child: Text(branch.name)),
                ],
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final (option, label) in [
                        (_Period.thisMonth, l10n.thisMonth),
                        (_Period.lastMonth, l10n.lastMonth),
                        (_Period.thisYear, l10n.thisYear),
                        (_Period.custom, l10n.customPeriod),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _period == option,
                            onSelected: (_) => _choose(option),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${date(_range.start)} – ${date(_range.end)}${branches.length > 1 ? ' · $branchName' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TabBar(
                  tabs: [
                    Tab(text: l10n.profitLossTab),
                    Tab(text: l10n.cashFlowTab),
                    Tab(text: l10n.profitabilityTab),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _Loaded(
              provider: profitAndLossProvider(period),
              builder: (report) => _ProfitAndLossView(report: report),
            ),
            _Loaded(
              provider: cashFlowProvider(period),
              builder: (report) => _CashFlowView(report: report),
            ),
            _Loaded(
              provider: profitAndLossProvider(period),
              builder: (report) => _ProfitabilityView(report: report),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a report once loaded, with pull to refresh, a spinner while loading and a retry on failure.
class _Loaded<T> extends ConsumerWidget {
  const _Loaded({required this.provider, required this.builder});

  final FutureProvider<T> provider;
  final Widget Function(T report) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(provider.future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          switch (ref.watch(provider)) {
            AsyncData(:final value) => builder(value),
            AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
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

class _ProfitAndLossView extends ConsumerWidget {
  const _ProfitAndLossView({required this.report});

  final ProfitAndLoss report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final colors = Theme.of(context).colorScheme;

    if (report.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Text(l10n.noFiguresInPeriod, textAlign: TextAlign.center),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          color: report.profit < 0 ? colors.errorContainer : colors.primaryContainer,
          child: ListTile(
            leading: Icon(report.profit < 0 ? Icons.trending_down : Icons.trending_up),
            title: Text(report.profit < 0 ? l10n.lossLabel : l10n.profitLabel),
            subtitle: report.marginBps == null ? null : Text(l10n.marginLabel(PercentFormat.format(report.marginBps!))),
            trailing: Text(money.format(report.profit), style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        ReportSection(
          title: l10n.revenueSection,
          rows: [
            (l10n.grossSales, money.format(report.gross)),
            (l10n.shiftDiscounts, '− ${money.format(report.discounts)}'),
            (l10n.vatTotal, '− ${money.format(report.vat)}'),
            (l10n.netSales, money.format(report.netSales)),
          ],
        ),
        ReportSection(
          title: l10n.expensesTotal,
          rows: [
            for (final category in report.expensesByCategory) (category.name, money.format(category.amount)),
            (l10n.totalExpenses, money.format(report.expenses)),
            if (report.owed > 0) (l10n.ofWhichOwed, money.format(report.owed)),
          ],
        ),
        ReportSection(
          title: l10n.profitLabel,
          rows: [
            (l10n.netSales, money.format(report.netSales)),
            (l10n.totalExpenses, '− ${money.format(report.expenses)}'),
            (report.profit < 0 ? l10n.lossLabel : l10n.profitLabel, money.format(report.profit)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l10n.profitLossNote, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _CashFlowView extends ConsumerWidget {
  const _CashFlowView({required this.report});

  final CashFlow report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final colors = Theme.of(context).colorScheme;
    final biggest = report.byDay.fold(0, (max, day) => [max, day.inflow, day.outflow].reduce((a, b) => a > b ? a : b));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportTiles(
          tiles: [
            (l10n.moneyIn, money.format(report.inflow), Icons.south_west),
            (l10n.moneyOut, money.format(report.outflow), Icons.north_east),
            (l10n.netCashFlow, money.format(report.net), Icons.account_balance_outlined),
            (l10n.stillOwed(report.owedCount), money.format(report.owed), Icons.schedule),
          ],
        ),
        if (report.inflowByMethod.isNotEmpty)
          ReportSection(
            title: l10n.moneyIn,
            rows: [
              for (final method in report.inflowByMethod)
                (moneyMethodLabel(l10n, method.name), money.format(method.amount)),
            ],
          ),
        if (report.outflowByMethod.isNotEmpty)
          ReportSection(
            title: l10n.moneyOut,
            rows: [
              for (final method in report.outflowByMethod)
                (moneyMethodLabel(l10n, method.name), money.format(method.amount)),
            ],
          ),
        if (report.byDay.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.byDay, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.square, size: 12, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(l10n.moneyIn, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.square, size: 12, color: colors.error),
                      const SizedBox(width: 4),
                      Text(l10n.moneyOut, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  for (final day in report.byDay)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text(
                              MaterialLocalizations.of(context).formatShortMonthDay(day.date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                for (final (amount, color) in [
                                  (day.inflow, colors.primary),
                                  (day.outflow, colors.error),
                                ])
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 1),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: biggest == 0 ? 0 : amount / biggest,
                                        minHeight: 8,
                                        color: color,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Text(
                              money.formatNumber(day.inflow - day.outflow),
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: day.inflow < day.outflow ? colors.error : null),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l10n.cashFlowNote, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _ProfitabilityView extends ConsumerWidget {
  const _ProfitabilityView({required this.report});

  final ProfitAndLoss report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final theme = Theme.of(context);

    if (report.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Text(l10n.noFiguresInPeriod, textAlign: TextAlign.center),
      );
    }

    Widget section(String title, List<Widget> rows) => Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: theme.textTheme.titleMedium),
          ),
          ...rows,
        ],
      ),
    );
    TextStyle? signed(int amount) => amount < 0 ? TextStyle(color: theme.colorScheme.error) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.byBranch.length > 1)
          section(l10n.byBranch, [
            for (final branch in report.byBranch)
              ListTile(
                dense: true,
                title: Text(branch.name),
                subtitle: Text(
                  '${l10n.netSales} ${money.format(branch.netSales)} · ${l10n.expensesTotal} ${money.format(branch.expenses)}',
                ),
                trailing: Text(money.format(branch.profit), style: signed(branch.profit)),
              ),
          ]),
        if (report.byService.isNotEmpty)
          section(l10n.servicesSection, [
            for (final service in report.byService)
              ListTile(
                dense: true,
                title: Text('${service.name} × ${service.quantity}'),
                subtitle: Text(
                  '${l10n.netSales} ${money.format(service.netRevenue)}'
                  '${service.materials > 0 ? ' · ${l10n.materialsCost} ${money.format(service.materials)}' : ''}',
                ),
                trailing: Text(money.format(service.profit), style: signed(service.profit)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(l10n.serviceProfitNote, style: theme.textTheme.bodySmall),
            ),
          ]),
        if (report.byWasher.isNotEmpty)
          section(l10n.washersSection, [
            for (final washer in report.byWasher)
              ListTile(
                dense: true,
                title: Text(washer.name),
                subtitle: Text(
                  '${l10n.carsCount(washer.cars)}${washer.pay > 0 ? ' · ${l10n.payLabel} ${money.format(washer.pay)}' : ''}',
                ),
                trailing: Text(money.format(washer.netRevenue)),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(l10n.washerProfitNote, style: theme.textTheme.bodySmall),
            ),
          ]),
      ],
    );
  }
}
