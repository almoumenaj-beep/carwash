import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/customers_repository.dart';
import '../domain/customer.dart';

/// A customer's points balance; opens their movements in a sheet.
class PointsCard extends StatelessWidget {
  const PointsCard({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.stars_outlined),
        title: Text(l10n.customerPointsTitle),
        subtitle: Text(l10n.pointsBalance(customer.pointsBalance)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _PointsHistory(customerId: customer.id),
        ),
      ),
    );
  }
}

class _PointsHistory extends ConsumerWidget {
  const _PointsHistory({required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final date = MaterialLocalizations.of(context).formatMediumDate;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => switch (ref.watch(customerPointsProvider(customerId))) {
        AsyncData(:final value) when value.isEmpty => Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.noPointsYet, textAlign: TextAlign.center),
        ),
        AsyncData(:final value) => ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            for (final movement in value)
              ListTile(
                title: Text(switch (movement.type) {
                  'earned' => l10n.pointsMovementEarned,
                  'redeemed' => l10n.pointsMovementRedeemed,
                  'refund' => l10n.pointsMovementRefund,
                  _ => l10n.pointsMovementExpired,
                }),
                subtitle: Text(
                  [
                    date(movement.createdAt.toLocal()),
                    ?movement.branchName,
                    ?movement.invoiceReference,
                    ?movement.createdBy,
                  ].join(' · '),
                ),
                trailing: Text(
                  movement.points > 0 ? '+${movement.points}' : '${movement.points}',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(customerPointsProvider(customerId)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
