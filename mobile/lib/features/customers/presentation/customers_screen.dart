import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/can.dart';
import '../../../core/auth/route_permissions.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/customers_repository.dart';
import '../domain/customer.dart';

/// Find a customer by name, phone or plate while typing, or register a new one.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _term = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _term = value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.customerSearchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onSearchChanged('');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Can(
        anyOf: const [Permissions.customersCreate],
        child: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/customers/new');
            ref.invalidate(customerSearchProvider);
          },
          icon: const Icon(Icons.person_add_alt),
          label: Text(l10n.newCustomer),
        ),
      ),
      body: switch (ref.watch(customerSearchProvider(_term))) {
        AsyncData(:final value) when value.isEmpty => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_term.isEmpty ? l10n.noCustomers : l10n.noCustomerMatches, textAlign: TextAlign.center),
          ),
        ),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(customerSearchProvider(_term).future),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _CustomerTile(customer: value[index], term: _term),
          ),
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(customerSearchProvider(_term)),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile({required this.customer, required this.term});

  final Customer customer;
  final String term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasName = customer.name != null && customer.name!.isNotEmpty;

    return ListTile(
      leading: CircleAvatar(child: Text(customer.displayName.characters.first)),
      title: Text(customer.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasName) Text(formatPhone(customer.phone), textDirection: TextDirection.ltr),
          if (customer.vehicles.isNotEmpty)
            Wrap(
              spacing: 6,
              children: [
                for (final vehicle in customer.vehicles)
                  Chip(
                    avatar: const Icon(Icons.directions_car_outlined, size: 16),
                    label: Text(vehicle.plateNumber),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
        ],
      ),
      isThreeLine: hasName && customer.vehicles.isNotEmpty,
      onTap: () async {
        await context.push('/customers/${customer.id}');
        ref.invalidate(customerSearchProvider(term));
      },
    );
  }
}
