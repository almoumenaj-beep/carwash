import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../data/catalog_repository.dart';

/// One row of a simple catalog list.
typedef _Entry = ({String id, String name, bool isActive, String? subtitle});

/// Vehicle sizes or service categories: add, rename, switch on/off and delete, each saved immediately.
class CatalogEntriesScreen extends ConsumerWidget {
  const CatalogEntriesScreen({super.key, required this.kind});

  final CatalogEntryKind kind;

  AsyncValue<List<_Entry>> _entries(WidgetRef ref, AppLocalizations l10n) => switch (kind) {
    CatalogEntryKind.vehicleSize =>
      ref
          .watch(vehicleSizesProvider)
          .whenData(
            (sizes) => [
              for (final size in sizes) (id: size.id, name: size.name, isActive: size.isActive, subtitle: null),
            ],
          ),
    CatalogEntryKind.serviceCategory =>
      ref
          .watch(serviceCategoriesProvider)
          .whenData(
            (categories) => [
              for (final category in categories)
                (
                  id: category.id,
                  name: category.name,
                  isActive: category.isActive,
                  subtitle: l10n.servicesCount(category.servicesCount),
                ),
            ],
          ),
  };

  void _refresh(WidgetRef ref) {
    ref.invalidate(kind == CatalogEntryKind.vehicleSize ? vehicleSizesProvider : serviceCategoriesProvider);
    ref.invalidate(servicesProvider);
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() change) async {
    try {
      await change();
      _refresh(ref);
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (context.mounted) {
        final message = problem.fieldError('name') ?? problem.errors.values.firstOrNull?.first;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message ?? problemMessage(context, problem))));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, _Entry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteEntryConfirm(entry.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, ref, () => ref.read(catalogRepositoryProvider).deleteEntry(kind, entry.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(catalogRepositoryProvider);
    final isSizes = kind == CatalogEntryKind.vehicleSize;

    return Scaffold(
      appBar: AppBar(title: Text(isSizes ? l10n.sizesTitle : l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(isSizes ? l10n.addSize : l10n.addCategory),
        onPressed: () async {
          final name = await showDialog<String>(context: context, builder: (_) => const _NameDialog());
          if (name != null && name.isNotEmpty && context.mounted) {
            await _run(context, ref, () => repository.createEntry(kind, name));
          }
        },
      ),
      body: switch (_entries(ref, l10n)) {
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final entry = value[index];
            return ListTile(
              title: Text(entry.name),
              subtitle: entry.subtitle == null ? null : Text(entry.subtitle!),
              onTap: () async {
                final name = await showDialog<String>(
                  context: context,
                  builder: (_) => _NameDialog(initial: entry.name),
                );
                if (name != null && name.isNotEmpty && name != entry.name && context.mounted) {
                  await _run(context, ref, () => repository.updateEntry(kind, entry.id, {'name': name}));
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: entry.isActive,
                    onChanged: (active) =>
                        _run(context, ref, () => repository.updateEntry(kind, entry.id, {'is_active': active})),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref, entry),
                  ),
                ],
              ),
            );
          },
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => _refresh(ref)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// Asks for a name; pops with the trimmed name, or null when cancelled.
class _NameDialog extends StatefulWidget {
  const _NameDialog({this.initial});

  final String? initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.nameField),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: Text(l10n.save)),
      ],
    );
  }
}
