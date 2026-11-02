import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/reports_repository.dart';
import '../domain/daily_sales.dart';

/// A day's sales for the owner and managers: totals, cars, and the day broken down by service, cashier, washer
/// and hour. One branch or all of them; any day, today by default.
class DailySalesScreen extends ConsumerStatefulWidget {
  const DailySalesScreen({super.key});

  @override
  ConsumerState<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends ConsumerState<DailySalesScreen> {
  /// Null for every branch.
  String? _branchId;
  DateTime _day = DateUtils.dateOnly(DateTime.now());

  String get _dateParam =>
      '${_day.year.toString().padLeft(4, '0')}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}';

  bool get _isToday => DateUtils.isSameDay(_day, DateTime.now());

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2024),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (picked != null) {
      setState(() => _day = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final query = (branchId: _branchId, date: _dateParam);
    final report = ref.watch(dailySalesProvider(query));
    final branchName = branches.where((branch) => branch.id == _branchId).firstOrNull?.name ?? l10n.allBranches;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailySalesTitle),
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
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(dailySalesProvider(query).future),
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                    onPressed: _pickDay,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _isToday ? l10n.today : MaterialLocalizations.of(context).formatMediumDate(_day),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextDay,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _isToday ? null : () => setState(() => _day = _day.add(const Duration(days: 1))),
                ),
              ],
            ),
            if (branches.length > 1)
              Text(branchName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            switch (report) {
              AsyncData(:final value) => _Report(report: value),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(dailySalesProvider(query)),
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

class _Report extends ConsumerWidget {
  const _Report({required this.report});

  final DailySales report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    if (report.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Text(l10n.noSalesThatDay, textAlign: TextAlign.center),
      );
    }

    final maxHour = report.byHour.fold(0, (max, hour) => hour.total > max ? hour.total : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Tiles(
          tiles: [
            (l10n.salesTotal, money.format(report.sales), Icons.payments_outlined),
            (l10n.shiftInvoices, '${report.invoicesCount}', Icons.receipt_long_outlined),
            (l10n.averageTicket, money.format(report.averageTicket), Icons.trending_up),
            (l10n.shiftCashTaken, money.format(report.cashCollected), Icons.point_of_sale_outlined),
            (l10n.shiftDiscounts, money.format(report.discounts), Icons.local_offer_outlined),
            (l10n.vatTotal, money.format(report.vat), Icons.account_balance_outlined),
          ],
        ),
        const SizedBox(height: 8),
        _Tiles(
          tiles: [
            (l10n.carsCheckedIn, '${report.carsCheckedIn}', Icons.directions_car_outlined),
            (l10n.statusDelivered, '${report.carsDelivered}', Icons.key_outlined),
            (l10n.statusCancelled, '${report.carsCancelled}', Icons.cancel_outlined),
            (l10n.carsInQueue, '${report.carsInQueue}', Icons.local_car_wash_outlined),
          ],
        ),
        if (report.byService.isNotEmpty)
          _Section(
            title: l10n.servicesSection,
            rows: [
              for (final service in report.byService)
                ('${service.name} × ${service.quantity}', money.format(service.revenue)),
            ],
          ),
        if (report.byCashier.isNotEmpty)
          _Section(
            title: l10n.byCashier,
            rows: [
              for (final cashier in report.byCashier)
                ('${cashier.name} · ${l10n.invoicesCount(cashier.invoices)}', money.format(cashier.total)),
            ],
          ),
        if (report.byWasher.isNotEmpty)
          _Section(
            title: l10n.washersSection,
            rows: [for (final washer in report.byWasher) (washer.name, l10n.carsCount(washer.cars))],
          ),
        if (report.byHour.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.byHour, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final hour in report.byHour)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            child: Text(
                              MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: hour.hour, minute: 0)),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: maxHour == 0 ? 0 : hour.total / maxHour,
                                minHeight: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(money.formatNumber(hour.total), style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Figures in a grid of small cards, two per row.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.tiles});

  final List<(String, String, IconData)> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, value, icon) in tiles)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text(value, style: theme.textTheme.titleMedium),
                        Text(label, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final (label, value) in rows) ListTile(dense: true, title: Text(label), trailing: Text(value)),
        ],
      ),
    );
  }
}
