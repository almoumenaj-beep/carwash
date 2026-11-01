import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money_format.dart';
import '../../../core/money/percent_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog.dart';

/// The service menu: services grouped by category, then add-ons, with their starting price.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final services = ref.watch(servicesProvider);
    final categories = ref.watch(serviceCategoriesProvider);

    void refresh() {
      ref.invalidate(servicesProvider);
      ref.invalidate(serviceCategoriesProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        actions: [
          IconButton(
            tooltip: l10n.categoriesTitle,
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push('/catalog/categories'),
          ),
          IconButton(
            tooltip: l10n.sizesTitle,
            icon: const Icon(Icons.directions_car_outlined),
            onPressed: () => context.push('/catalog/sizes'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/catalog/services/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newService),
      ),
      body: switch ((services, categories)) {
        (AsyncData(value: final services), AsyncData()) when services.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.noServices, textAlign: TextAlign.center),
          ),
        ),
        (AsyncData(value: final services), AsyncData(value: final categories)) => RefreshIndicator(
          onRefresh: () async => refresh(),
          child: _Menu(services: services, categories: categories),
        ),
        (AsyncError(:final error), _) || (_, AsyncError(:final error)) => ErrorView(error: error, onRetry: refresh),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.services, required this.categories});

  final List<CatalogService> services;
  final List<ServiceCategory> categories;

  @override
  Widget build(BuildContext context) {
    final catalog = {for (final service in services) service.id: service};
    final l10n = AppLocalizations.of(context);
    final packages = services.where((service) => service.isPackage).toList();
    final mainServices = services.where((service) => !service.isAddon && !service.isPackage).toList();
    final addons = services.where((service) => service.isAddon).toList();
    final sections = <(String, List<CatalogService>)>[
      (l10n.packagesSection, packages),
      for (final category in categories)
        (category.name, mainServices.where((service) => service.categoryId == category.id).toList()),
      (l10n.noCategory, mainServices.where((service) => service.categoryId == null).toList()),
      (l10n.addonsSection, addons),
    ].where((section) => section.$2.isNotEmpty).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final (title, items) in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final service in items) _ServiceTile(service: service, catalog: catalog),
        ],
      ],
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service, required this.catalog});

  final CatalogService service;

  /// Every service by id, to price packages from their services.
  final Map<String, CatalogService> catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final lowest = service.isPackage ? null : service.lowestPrice;
    final details = [
      if (service.isPackage) service.packageItemIds.map((id) => catalog[id]?.name).whereType<String>().join(' + '),
      if (service.durationMinutes > 0) l10n.minutesShort(service.durationMinutes),
      if (!service.isActive) l10n.inactiveLabel,
    ];

    return ListTile(
      leading: Icon(
        service.isPackage
            ? Icons.redeem_outlined
            : (service.isAddon ? Icons.add_circle_outline : Icons.local_car_wash_outlined),
      ),
      title: Text(service.name),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: Text(
        service.isPackage
            ? packageDiscountLabel(l10n, money, service)
            : (lowest == null ? l10n.unpriced : l10n.fromPrice(money.format(lowest))),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: () => context.push('/catalog/services/${service.id}'),
    );
  }
}

/// "15% off" or "1.000 BHD off" for a package.
String packageDiscountLabel(AppLocalizations l10n, MoneyFormat money, CatalogService package) => l10n.discountOff(
  package.packageDiscountType == 'amount'
      ? money.format(package.packageDiscountValue)
      : '${PercentFormat.format(package.packageDiscountValue)}%',
);
