import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/offers_repository.dart';
import '../domain/offer.dart';

/// The offers shown on the public customer page. The owner adds, edits, switches off and deletes
/// them; the page link at the top is what customers open.
class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);
    final me = ref.watch(sessionProvider).value;
    final slug = me?.slug ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.offersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(context: context, builder: (_) => const _OfferDialog()),
        icon: const Icon(Icons.add),
        label: Text(l10n.addOffer),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.offersPageHint, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                SelectableText(
                  '/w/$slug',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ),
          switch (ref.watch(offersProvider)) {
            AsyncData(:final value) when value.isEmpty => Padding(
              padding: const EdgeInsets.all(32),
              child: Text(l10n.noOffersYet, textAlign: TextAlign.center),
            ),
            AsyncData(:final value) => Column(
              children: [
                for (final offer in value)
                  OfferTile(
                    offer: offer,
                    priceLabel: offer.price == null ? null : money.format(offer.price!),
                    onToggle: (active) async {
                      await ref.read(offersRepositoryProvider).save(id: offer.id, title: offer.title, isActive: active);
                      ref.invalidate(offersProvider);
                    },
                    onEdit: () => showDialog<void>(context: context, builder: (_) => _OfferDialog(offer: offer)),
                    onDelete: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialog) => AlertDialog(
                          title: Text(l10n.deleteOfferTitle),
                          content: Text(l10n.deleteOfferConfirm),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: Text(l10n.back)),
                            FilledButton(onPressed: () => Navigator.of(dialog).pop(true), child: Text(l10n.delete)),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(offersRepositoryProvider).delete(offer.id);
                        ref.invalidate(offersProvider);
                      }
                    },
                  ),
              ],
            ),
            AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(offersProvider)),
            _ => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          },
        ],
      ),
    );
  }
}

class OfferTile extends StatelessWidget {
  const OfferTile({
    super.key,
    required this.offer,
    required this.priceLabel,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Offer offer;
  final String? priceLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      leading: Icon(
        Icons.local_offer_outlined,
        color: offer.isActive ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
      ),
      title: Text(offer.title, style: offer.isActive ? null : TextStyle(color: Theme.of(context).disabledColor)),
      subtitle: Text(
        [
          ?offer.description,
          ?priceLabel,
          if (offer.expiresOn != null) '${l10n.offerExpires} ${offer.expiresOn}',
        ].nonNulls.join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: offer.isActive, onChanged: onToggle),
          PopupMenuButton<String>(
            onSelected: (action) => action == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (menu) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Adds an offer or edits one: title, an optional description, an optional price, an optional expiry day.
class _OfferDialog extends ConsumerStatefulWidget {
  const _OfferDialog({this.offer});

  final Offer? offer;

  @override
  ConsumerState<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends ConsumerState<_OfferDialog> {
  late final _title = TextEditingController(text: widget.offer?.title ?? '');
  late final _description = TextEditingController(text: widget.offer?.description ?? '');
  late final _price = TextEditingController(
    text: widget.offer?.price == null ? '' : ref.read(moneyFormatProvider).toInput(widget.offer!.price!),
  );
  late String? _expiresOn;
  bool _active = true;
  bool _saving = false;
  String? _error;

  bool get _isNew => widget.offer == null;

  @override
  void initState() {
    super.initState();
    _expiresOn = widget.offer?.expiresOn;
    _active = widget.offer?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresOn == null ? now : DateTime.parse(_expiresOn!),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _expiresOn = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final money = ref.read(moneyFormatProvider);
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = l10n.offerTitleMissing);
      return;
    }
    final price = _price.text.trim().isEmpty ? null : money.parse(_price.text);
    if (_price.text.trim().isNotEmpty && price == null) {
      setState(() => _error = l10n.amountInvalid(money.toInput(5)));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(offersRepositoryProvider)
          .save(id: widget.offer?.id, title: title, description: _description.text.trim(), price: price, expiresOn: _expiresOn, isActive: _isNew ? null : _active);
      ref.invalidate(offersProvider);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = changeError(context, error, stackTrace);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return AlertDialog(
      title: Text(_isNew ? l10n.addOffer : l10n.editOffer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _title, decoration: InputDecoration(labelText: l10n.offerTitleField), maxLength: 150),
            TextField(
              controller: _description,
              decoration: InputDecoration(labelText: l10n.offerDescriptionField),
              maxLines: 2,
              maxLength: 1000,
            ),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.offerPriceField, suffixText: money.currency),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(_expiresOn == null ? l10n.offerNoExpiry : '${l10n.offerExpires} $_expiresOn'),
                ),
                TextButton(onPressed: _pickExpiry, child: Text(l10n.offerPickExpiry)),
                if (_expiresOn != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _expiresOn = null),
                  ),
              ],
            ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.offerActiveField),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
      ],
    );
  }
}
