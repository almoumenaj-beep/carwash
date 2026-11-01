import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/me.dart';
import '../../settings/data/settings_repository.dart';
import '../../staff/data/staff_repository.dart';
import '../data/catalog_repository.dart';
import '../domain/catalog.dart';

/// The key of the "every size" price in the price field maps.
const _allSizes = '';

/// Adds a service ([serviceId] null) or edits one, with its general and branch prices.
class ServiceEditorScreen extends ConsumerWidget {
  const ServiceEditorScreen({super.key, this.serviceId});

  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = serviceId == null ? const AsyncData<CatalogService?>(null) : ref.watch(serviceProvider(serviceId!));
    final sizes = ref.watch(vehicleSizesProvider);
    final categories = ref.watch(serviceCategoriesProvider);
    final branches = ref.watch(branchesProvider);

    void retry() {
      ref.invalidate(vehicleSizesProvider);
      ref.invalidate(serviceCategoriesProvider);
      ref.invalidate(branchesProvider);
      if (serviceId != null) {
        ref.invalidate(serviceProvider(serviceId!));
      }
    }

    return switch ((service, sizes, categories, branches)) {
      (
        AsyncData(value: final service),
        AsyncData(value: final sizes),
        AsyncData(value: final categories),
        AsyncData(value: final branches),
      ) =>
        _ServiceForm(
          key: ValueKey(service?.id),
          service: service,
          sizes: sizes,
          categories: categories,
          branches: branches,
        ),
      (AsyncError(:final error), _, _, _) ||
      (_, AsyncError(:final error), _, _) ||
      (_, _, AsyncError(:final error), _) ||
      (_, _, _, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: retry),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({
    super.key,
    required this.service,
    required this.sizes,
    required this.categories,
    required this.branches,
  });

  final CatalogService? service;
  final List<VehicleSize> sizes;
  final List<ServiceCategory> categories;
  final List<BranchSummary> branches;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.service?.name);
  late final _description = TextEditingController(text: widget.service?.description);
  late final _duration = TextEditingController(text: '${widget.service?.durationMinutes ?? 0}');
  late String? _categoryId = widget.service?.categoryId;
  late bool _isAddon = widget.service?.isAddon ?? false;
  late bool _isActive = widget.service?.isActive ?? true;
  late bool _samePriceForAllSizes;

  /// Price fields keyed by size id ([_allSizes] for every size); [_branchPrices] per branch id.
  final Map<String, TextEditingController> _generalPrices = {};
  final Map<String, Map<String, TextEditingController>> _branchPrices = {};
  bool _saving = false;
  ApiProblem? _problem;

  bool get _isNew => widget.service == null;

  @override
  void initState() {
    super.initState();

    final money = ref.read(moneyFormatProvider);
    final keys = [_allSizes, for (final size in widget.sizes) size.id];
    for (final key in keys) {
      _generalPrices[key] = TextEditingController();
    }
    for (final branch in widget.branches) {
      _branchPrices[branch.id] = {for (final key in keys) key: TextEditingController()};
    }

    for (final price in widget.service?.prices ?? const <ServicePrice>[]) {
      final key = price.vehicleSizeId ?? _allSizes;
      final field = price.branchId == null ? _generalPrices[key] : _branchPrices[price.branchId]?[key];
      field?.text = money.toInput(price.price);
    }

    final hasPerSizePrices = widget.service?.prices.any((price) => price.vehicleSizeId != null) ?? false;
    _samePriceForAllSizes = !hasPerSizePrices && (widget.service?.generalPrice(null) != null || _isAddon);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _duration.dispose();
    for (final field in [..._generalPrices.values, for (final prices in _branchPrices.values) ...prices.values]) {
      field.dispose();
    }
    super.dispose();
  }

  List<String> get _priceKeys => _samePriceForAllSizes ? [_allSizes] : [for (final size in widget.sizes) size.id];

  /// Only the fields of the current mode are sent; an empty branch field falls back to the general price.
  List<Map<String, dynamic>> _collectPrices(MoneyFormat money) => [
    for (final key in _priceKeys)
      if (_generalPrices[key]!.text.trim().isNotEmpty)
        ServicePrice(
          vehicleSizeId: key == _allSizes ? null : key,
          branchId: null,
          price: money.parse(_generalPrices[key]!.text)!,
        ).toJson(),
    for (final MapEntry(key: branchId, value: fields) in _branchPrices.entries)
      for (final key in _priceKeys)
        if (fields[key]!.text.trim().isNotEmpty)
          ServicePrice(
            vehicleSizeId: key == _allSizes ? null : key,
            branchId: branchId,
            price: money.parse(fields[key]!.text)!,
          ).toJson(),
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });

    final data = {
      'name': _name.text.trim(),
      'service_category_id': _categoryId,
      'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
      'duration_minutes': int.tryParse(_duration.text.trim()) ?? 0,
      'is_addon': _isAddon,
      'is_active': _isActive,
      'prices': _collectPrices(ref.read(moneyFormatProvider)),
    };

    final repository = ref.read(catalogRepositoryProvider);
    try {
      if (_isNew) {
        await repository.createService(data);
      } else {
        await repository.updateService(widget.service!.id, data);
        ref.invalidate(serviceProvider(widget.service!.id));
      }
      ref.invalidate(servicesProvider);
      ref.invalidate(serviceCategoriesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() => _problem = problem);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final service = widget.service!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteEntryConfirm(service.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(catalogRepositoryProvider).deleteService(service.id);
      ref.invalidate(servicesProvider);
      ref.invalidate(serviceCategoriesProvider);
      if (mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        final message = problem.fieldError('service') ?? problemMessage(context, problem);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final includesVat = ref.watch(settingsProvider).value?.pricesIncludeVat ?? true;
    final fieldErrors = {'name', 'service_category_id', 'description', 'duration_minutes'};
    final pricesError = _problem?.errors.entries.where((entry) => entry.key.startsWith('prices')).firstOrNull;
    final hasKnownError = _problem != null && (_problem!.errors.keys.any(fieldErrors.contains) || pricesError != null);
    final generalError = _problem != null && !hasKnownError ? problemMessage(context, _problem!) : null;

    String? validateAmount(String? value) => value == null || value.trim().isEmpty || money.parse(value) != null
        ? null
        : l10n.amountInvalid(money.toInput(2500));

    Widget priceField(TextEditingController controller, String label, {String? hint}) => TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٠-٩٫٬]'))],
      decoration: InputDecoration(labelText: label, hintText: hint, suffixText: money.currency),
      validator: validateAmount,
    );

    String sizeLabel(String key) {
      if (key == _allSizes) {
        return l10n.priceAllSizes;
      }
      final size = widget.sizes.firstWhere((size) => size.id == key);
      return size.isActive ? size.name : '${size.name} (${l10n.inactiveLabel})';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newService : widget.service!.name),
        actions: [
          if (!_isNew) IconButton(tooltip: l10n.delete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.check),
        label: Text(l10n.save),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.serviceName, errorText: _problem?.fieldError('name')),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _categoryId,
              decoration: InputDecoration(labelText: l10n.categoryField),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noCategory)),
                for (final category in widget.categories)
                  DropdownMenuItem(value: category.id, child: Text(category.name)),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.durationField,
                errorText: _problem?.fieldError('duration_minutes'),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 2,
              decoration: InputDecoration(labelText: l10n.descriptionField),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.isAddon),
              value: _isAddon,
              onChanged: (value) => setState(() => _isAddon = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.serviceActive),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const Divider(height: 32),
            Text(l10n.pricesSection, style: theme.textTheme.titleMedium),
            Text(includesVat ? l10n.pricesIncludeVatHint : l10n.pricesExcludeVatHint, style: theme.textTheme.bodySmall),
            if (pricesError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(pricesError.value.first, style: TextStyle(color: theme.colorScheme.error)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.samePriceAllSizes),
              value: _samePriceForAllSizes,
              onChanged: (value) => setState(() => _samePriceForAllSizes = value),
            ),
            for (final key in _priceKeys) ...[
              priceField(_generalPrices[key]!, sizeLabel(key)),
              const SizedBox(height: 12),
            ],
            if (widget.branches.length > 1 ||
                _branchPrices.values.any((fields) => fields.values.any((f) => f.text.isNotEmpty)))
              for (final branch in widget.branches)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(l10n.branchPricesFor(branch.name)),
                  subtitle: Text(l10n.branchPricesHint),
                  initiallyExpanded: _branchPrices[branch.id]!.values.any((field) => field.text.isNotEmpty),
                  children: [
                    for (final key in _priceKeys) ...[
                      priceField(
                        _branchPrices[branch.id]![key]!,
                        sizeLabel(key),
                        hint: _generalPrices[key]!.text.isEmpty ? null : _generalPrices[key]!.text,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
            if (generalError != null) ...[
              const SizedBox(height: 12),
              Text(generalError, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
