import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../data/expenses_repository.dart';
import '../domain/expense.dart';
import 'expense_widgets.dart';

/// Expense categories: add, rename, switch on/off and delete (only when unused), each saved immediately.
class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() change) async {
    try {
      await change();
      ref.invalidate(expenseCategoriesProvider);
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(changeError(context, error, stackTrace))));
      }
    }
  }

  Future<String?> _askName(BuildContext context, {String? initial}) => showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(initial: initial),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(expensesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseCategories)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
        onPressed: () async {
          final name = await _askName(context);
          if (name != null && name.isNotEmpty && context.mounted) {
            await _run(context, ref, () => repository.saveCategory(null, {'name': name}));
          }
        },
      ),
      body: switch (ref.watch(expenseCategoriesProvider)) {
        AsyncData(:final value) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 96),
          itemCount: value.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final ExpenseCategory category = value[index];
            return ListTile(
              title: Text(category.name),
              onTap: () async {
                final name = await _askName(context, initial: category.name);
                if (name != null && name.isNotEmpty && name != category.name && context.mounted) {
                  await _run(context, ref, () => repository.saveCategory(category.id, {'name': name}));
                }
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: category.isActive,
                    onChanged: (active) =>
                        _run(context, ref, () => repository.saveCategory(category.id, {'is_active': active})),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _run(context, ref, () => repository.deleteCategory(category.id)),
                  ),
                ],
              ),
            );
          },
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(expenseCategoriesProvider)),
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
