import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/can.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/orders_repository.dart';
import '../domain/order.dart';
import 'order_widgets.dart';

/// The live queue of a branch: cars waiting, being washed, in quality check and ready, plus everything checked in
/// today.
/// Refreshes on its own every few seconds so several devices stay in step.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  /// How often the queue is fetched again while it is open.
  static const refreshEvery = Duration(seconds: 15);

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  String? _branchId;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(QueueScreen.refreshEvery, (_) => _reload());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _reload() {
    final branchId = _branchId;
    if (branchId == null || !mounted) {
      return;
    }
    for (final scope in QueueScope.values) {
      ref.invalidate(branchOrdersProvider((branchId: branchId, scope: scope)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final branches = ref.watch(sessionProvider).value?.branches ?? const <BranchSummary>[];
    final branch = branches.where((branch) => branch.id == _branchId).firstOrNull ?? branches.firstOrNull;
    _branchId = branch?.id;

    if (branch == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.queueTitle)),
        body: Center(child: Text(l10n.noBranchAssigned)),
      );
    }

    final active = ref.watch(branchOrdersProvider((branchId: branch.id, scope: QueueScope.active)));
    final orders = active.value ?? const <Order>[];
    final waiting = orders.where((order) => order.status == OrderStatus.waiting).toList();
    final washing = orders.where((order) => order.status == OrderStatus.inProgress).toList();
    final inQualityCheck = orders.where((order) => order.status == OrderStatus.qualityCheck).toList();
    final ready = orders.where((order) => order.status == OrderStatus.ready).toList();

    Widget activeList(List<Order> shown) => _OrderList(
      orders: active.hasValue ? shown : null,
      error: active.hasValue ? null : active.error,
      onReload: _reload,
    );

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(branches.length > 1 ? '${l10n.queueTitle} · ${branch.name}' : l10n.queueTitle),
          actions: [
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
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '${l10n.statusWaiting} (${waiting.length})'),
              Tab(text: '${l10n.queueTabWashing} (${washing.length})'),
              Tab(text: '${l10n.statusQualityCheck} (${inQualityCheck.length})'),
              Tab(text: '${l10n.statusReady} (${ready.length})'),
              Tab(text: l10n.queueTabToday),
            ],
          ),
        ),
        floatingActionButton: Can(
          anyOf: const [Permissions.ordersCreate],
          child: FloatingActionButton.extended(
            onPressed: () async {
              await context.push('/queue/new?branch=${branch.id}');
              _reload();
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.checkIn),
          ),
        ),
        body: TabBarView(
          children: [
            activeList(waiting),
            activeList(washing),
            activeList(inQualityCheck),
            activeList(ready),
            _TodayList(branchId: branch.id, onReload: _reload),
          ],
        ),
      ),
    );
  }
}

class _TodayList extends ConsumerWidget {
  const _TodayList({required this.branchId, required this.onReload});

  final String branchId;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(branchOrdersProvider((branchId: branchId, scope: QueueScope.today)));

    return _OrderList(
      orders: today.value,
      error: today.hasValue ? null : today.error,
      onReload: onReload,
      showStatus: true,
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders, required this.error, required this.onReload, this.showStatus = false});

  /// Null while loading for the first time.
  final List<Order>? orders;
  final Object? error;
  final VoidCallback onReload;

  /// On the "today" tab the status is shown instead of the next-step button.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorView(error: error!, onRetry: onReload);
    }

    final orders = this.orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: orders.isEmpty
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Text(AppLocalizations.of(context).queueEmpty, textAlign: TextAlign.center),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: orders.length,
              itemBuilder: (context, index) =>
                  _OrderCard(order: orders[index], onChanged: onReload, showStatus: showStatus),
            ),
    );
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  const _OrderCard({required this.order, required this.onChanged, required this.showStatus});

  final Order order;
  final VoidCallback onChanged;
  final bool showStatus;

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _moving = false;

  Future<void> _move(OrderStatus next) async {
    setState(() => _moving = true);
    final moved = await moveOrder(context, ref, widget.order, next);
    if (mounted) {
      setState(() => _moving = false);
    }
    if (moved != null) {
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final order = widget.order;
    final next = order.nextStep;
    final canPay = ref.watch(sessionProvider).value?.can(Permissions.posCheckout) ?? false;
    final customer = order.customer;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/queue/${order.id}');
          widget.onChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.plateNumber,
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(order.reference, style: theme.textTheme.labelMedium),
                  const Spacer(),
                  if (widget.showStatus)
                    StatusChip(status: order.status)
                  else
                    _Elapsed(minutes: minutesSince(order.stageStartedAt)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                customer == null ? l10n.walkIn : (customer.name ?? customer.phone),
                style: theme.textTheme.bodyMedium,
              ),
              Text(order.servicesSummary, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (order.bay != null) _Info(icon: Icons.garage_outlined, text: order.bay!.name),
                  if (order.staff.isNotEmpty)
                    _Info(
                      icon: Icons.person_outline,
                      text: order.staff.map((member) => member.name).join(l10n.listSeparator),
                    ),
                  _Info(
                    icon: order.isPaid ? Icons.check_circle_outline : Icons.payments_outlined,
                    text: order.isPaid
                        ? '${l10n.paidBadge} ${money.format(order.invoice!.total)}'
                        : money.format(order.subtotal),
                  ),
                ],
              ),
              if (!widget.showStatus &&
                  next == null &&
                  order.status == OrderStatus.ready &&
                  !order.isPaid &&
                  canPay) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await context.push('/checkout/${order.id}');
                      widget.onChanged();
                    },
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(l10n.payAndDeliver),
                  ),
                ),
              ],
              if (!widget.showStatus && next != null && canMoveTo(ref, next)) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _moving ? null : () => _move(next),
                    child: Text(actionLabel(l10n, order.status, next)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Elapsed extends StatelessWidget {
  const _Elapsed({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final late = minutes >= 30;
    final color = late ? Theme.of(context).colorScheme.error : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 16, color: color),
        const SizedBox(width: 4),
        Text(AppLocalizations.of(context).elapsedMinutes(minutes), style: TextStyle(color: color)),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
