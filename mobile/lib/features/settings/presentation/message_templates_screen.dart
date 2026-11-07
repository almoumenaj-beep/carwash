import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/settings_repository.dart';
import '../domain/message_templates.dart';

/// Where the owner writes the WhatsApp messages staff send, with the customer's details as words to insert.
class MessageTemplatesScreen extends ConsumerWidget {
  const MessageTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(settingsProvider)) {
      AsyncValue(hasValue: true, :final value?) => _TemplatesForm(templates: value.messageTemplates),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: () => ref.invalidate(settingsProvider)),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _TemplatesForm extends ConsumerStatefulWidget {
  const _TemplatesForm({required this.templates});

  final MessageTemplates templates;

  @override
  ConsumerState<_TemplatesForm> createState() => _TemplatesFormState();
}

class _TemplatesFormState extends ConsumerState<_TemplatesForm> {
  late final Map<MessageTemplateKind, TextEditingController> _controllers = {
    for (final kind in MessageTemplateKind.values) kind: TextEditingController(text: widget.templates.textOf(kind)),
  };
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Puts the word where the cursor is, or at the end when the field was not touched yet.
  void _insert(TextEditingController controller, MessageToken token) {
    final selection = controller.selection;
    final text = controller.text;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, token.text),
      selection: TextSelection.collapsed(offset: start + token.text.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    final saved = AppLocalizations.of(context).saved;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).update({
        'message_templates': {
          for (final MapEntry(key: kind, value: controller) in _controllers.entries)
            // The default wording is not stored, so it stays the default.
            kind.apiKey: controller.text.trim().isEmpty || controller.text.trim() == kind.defaultText
                ? null
                : controller.text.trim(),
        },
      });
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saved)));
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
    final carWash = ref.watch(settingsProvider).value?.name ?? '';
    final sample = {
      MessageToken.name: l10n.messageSampleName,
      MessageToken.plate: '12345',
      MessageToken.date: MaterialLocalizations.of(context).formatMediumDate(DateTime.now()),
      MessageToken.time: MaterialLocalizations.of(context).formatTimeOfDay(const TimeOfDay(hour: 10, minute: 30)),
      MessageToken.carWash: carWash,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.messageTemplatesTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.messageTemplatesHint, style: theme.textTheme.bodySmall),
          for (final kind in MessageTemplateKind.values) ...[
            const SizedBox(height: 16),
            Text(switch (kind) {
              MessageTemplateKind.ready => l10n.messageTemplateReady,
              MessageTemplateKind.reminder => l10n.messageTemplateReminder,
              MessageTemplateKind.greeting => l10n.messageTemplateGreeting,
            }, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _controllers[kind],
              minLines: 2,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final token in kind.tokens)
                  ActionChip(label: Text(token.text), onPressed: () => _insert(_controllers[kind]!, token)),
              ],
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                dense: true,
                title: Text(l10n.messageTemplatePreview),
                subtitle: Text(
                  MessageTemplates.fill(
                    _controllers[kind]!.text.trim().isEmpty ? kind.defaultText : _controllers[kind]!.text,
                    sample,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.restore),
                label: Text(l10n.messageTemplateRestore),
                onPressed: () => setState(() => _controllers[kind]!.text = kind.defaultText),
              ),
            ),
          ],
          if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }
}
