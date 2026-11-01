import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money_format.dart';
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
    final l10n = AppLocalizations.of(context);
    final mainServices = services.where((service) => !service.isAddon).toList();
    final addons = services.where((service) => service.isAddon).toList();
    final sections = <(String, List<CatalogService>)>[
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
          for (final service in items) _ServiceTile(service: service),
        ],
      ],
    );
  }
}

class _ServiceTile extends ConsumerWidget {
  const _ServiceTile({required this.service});

  final CatalogService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final lowest = service.lowestPrice;
    final details = [
      if (service.durationMinutes > 0) l10n.minutesShort(service.durationMinutes),
      if (!service.isActive) l10n.inactiveLabel,
    ];

    return ListTile(
      leading: Icon(service.isAddon ? Icons.add_circle_outline : Icons.local_car_wash_outlined),
      title: Text(service.name),
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: Text(
        lowest == null ? l10n.unpriced : l10n.fromPrice(money.format(lowest)),
        style: Theme.of(context).textTheme.labelLarge,
      ),
      onTap: () => context.push('/catalog/services/${service.id}'),
    );
  }
}
