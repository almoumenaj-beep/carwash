import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/inventory_repository.dart';
import '../domain/inventory.dart';

/// What one sale of a service uses up; starting a wash takes these out of the branch's stock.
class ServiceMaterialsScreen extends ConsumerWidget {
  const ServiceMaterialsScreen({super.key, required this.serviceId, required this.serviceName});

  final String serviceId;
  final String serviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materials = ref.watch(serviceMaterialsProvider(serviceId));
    final items = ref.watch(inventoryItemsProvider(null));

    return switch ((materials, items)) {
      (AsyncData(value: final materials), AsyncData(value: final items)) => _MaterialsForm(
        serviceId: serviceId,
        serviceName: serviceName,
        initial: materials,
        items: items.where((item) => item.isActive || materials.any((material) => material.itemId == item.id)).toList(),
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () {
            ref.invalidate(serviceMaterialsProvider(serviceId));
            ref.invalidate(inventoryItemsProvider(null));
          },
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _MaterialsForm extends ConsumerStatefulWidget {
  const _MaterialsForm({
    required this.serviceId,
    required this.serviceName,
    required this.initial,
    required this.items,
  });

  final String serviceId;
  final String serviceName;
  final List<ServiceMaterial> initial;
  final List<InventoryItem> items;

  @override
  ConsumerState<_MaterialsForm> createState() => _MaterialsFormState();
}

class _MaterialsFormState extends ConsumerState<_MaterialsForm> {
  /// Material id → typed quantity, in the order added.
  late final Map<String, TextEditingController> _quantities = {
    for (final material in widget.initial)
      material.itemId: TextEditingController(text: formatQuantity(material.quantity)),
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final materials = <({String itemId, double quantity})>[];
    for (final MapEntry(key: itemId, value: controller) in _quantities.entries) {
      final quantity = parseQuantity(controller.text);
      if (quantity == null || quantity <= 0) {
        setState(() => _error = l10n.quantityInvalid);
        return;
      }
      materials.add((itemId: itemId, quantity: quantity));
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(inventoryRepositoryProvider).saveServiceMaterials(widget.serviceId, materials);
      ref.invalidate(serviceMaterialsProvider(widget.serviceId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = changeError(context, error, stackTrace));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final byId = {for (final item in widget.items) item.id: item};
    final available = widget.items.where((item) => !_quantities.containsKey(item.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.serviceMaterials} · ${widget.serviceName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.serviceMaterialsHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final MapEntry(key: itemId, value: controller) in _quantities.entries)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text(byId[itemId]?.name ?? '—')),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.quantityField,
                        suffixText: byId[itemId]?.unit,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _quantities.remove(itemId)?.dispose()),
                  ),
                ],
              ),
            ),
          if (available.isNotEmpty)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PopupMenuButton<InventoryItem>(
                onSelected: (item) => setState(() => _quantities[item.id] = TextEditingController()),
                itemBuilder: (_) => [for (final item in available) PopupMenuItem(value: item, child: Text(item.name))],
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.addMaterialLine, style: TextStyle(color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            )
          else if (widget.items.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(l10n.noMaterials)),
          if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.check), label: Text(l10n.save)),
        ],
      ),
    );
  }
}
