import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../expenses/presentation/expense_widgets.dart';
import '../data/memberships_repository.dart';
import '../domain/membership.dart';

/// The memberships the owner offers. Changing one leaves those already sold as they were.
class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

  void _edit(BuildContext context, [MembershipPlan? plan]) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _PlanEditor(plan: plan)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final money = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membershipPlansTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addMembershipPlan),
      ),
      body: switch (ref.watch(membershipPlansProvider)) {
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.membershipPlansHint, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (value.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.noMembershipPlans, textAlign: TextAlign.center),
              ),
            for (final plan in value)
              ListTile(
                leading: const Icon(Icons.card_membership_outlined),
                textColor: plan.isActive ? null : Theme.of(context).disabledColor,
                title: Text(plan.name),
                subtitle: Text(
                  [
                    money.format(plan.price),
                    plan.washes == null ? l10n.membershipUnlimited : l10n.membershipWashes(plan.washes!),
                    l10n.membershipValidity(plan.validityDays),
                    plan.forOneCar ? l10n.membershipForOneCar : l10n.membershipForCustomer,
                    if (!plan.isActive) l10n.membershipPlanOff,
                  ].join(' · '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _edit(context, plan),
              ),
          ],
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(membershipPlansProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PlanEditor extends ConsumerStatefulWidget {
  const _PlanEditor({required this.plan});

  final MembershipPlan? plan;

  @override
  ConsumerState<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends ConsumerState<_PlanEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name);
  late final _price = TextEditingController(
    text: widget.plan == null ? '' : ref.read(moneyFormatProvider).toInput(widget.plan!.price),
  );
  late final _washes = TextEditingController(text: widget.plan?.washes?.toString() ?? '');
  late final _validity = TextEditingController(text: widget.plan?.validityDays.toString() ?? '');
  late bool _unlimited = widget.plan != null && widget.plan!.washes == null;
  late bool _forOneCar = widget.plan?.forOneCar ?? false;
  late bool _isActive = widget.plan?.isActive ?? true;
  late final Set<String> _serviceIds = {...?widget.plan?.serviceIds};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _washes.dispose();
    _validity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_serviceIds.isEmpty) {
      setState(() => _error = l10n.membershipChooseServices);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final data = {
      'name': _name.text.trim(),
      'price': ref.read(moneyFormatProvider).parse(_price.text),
      'washes': _unlimited ? null : int.parse(_washes.text.trim()),
      'validity_days': int.parse(_validity.text.trim()),
      'scope': _forOneCar ? 'vehicle' : 'customer',
      'service_ids': _serviceIds.toList(),
      'is_active': _isActive,
    };
    try {
      final repository = ref.read(membershipsRepositoryProvider);
      final plan = widget.plan;
      await (plan == null ? repository.createPlan(data) : repository.updatePlan(plan.id, data));
      ref.invalidate(membershipPlansProvider);
      if (mounted) {
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
    final money = ref.watch(moneyFormatProvider);
    final services = ref.watch(servicesProvider);
    String? wholeNumber(String? value) => (int.tryParse(value?.trim() ?? '') ?? 0) < 1 ? l10n.pointsFieldInvalid : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.plan == null ? l10n.addMembershipPlan : widget.plan!.name)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.nameField, hintText: l10n.membershipNameHint),
              validator: (value) => (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.membershipPriceField, suffixText: money.currency),
              validator: (value) => (money.parse(value ?? '') ?? 0) < 1 ? l10n.pointsFieldInvalid : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.membershipUnlimited),
              value: _unlimited,
              onChanged: (value) => setState(() => _unlimited = value),
            ),
            if (!_unlimited)
              TextFormField(
                controller: _washes,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l10n.membershipWashesField),
                validator: wholeNumber,
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _validity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l10n.membershipValidityField),
              validator: wholeNumber,
            ),
            const SizedBox(height: 16),
            Text(l10n.membershipScopeField, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: false, label: Text(l10n.membershipForCustomer)),
                ButtonSegment(value: true, label: Text(l10n.membershipForOneCar)),
              ],
              selected: {_forOneCar},
              onSelectionChanged: (selection) => setState(() => _forOneCar = selection.single),
            ),
            const SizedBox(height: 16),
            Text(l10n.membershipServicesField, style: theme.textTheme.titleSmall),
            switch (services) {
              AsyncData(:final value) => Column(
                children: [
                  for (final service in value.where((service) => service.isActive))
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(service.name),
                      value: _serviceIds.contains(service.id),
                      onChanged: (on) => setState(() {
                        if (on ?? false) {
                          _serviceIds.add(service.id);
                        } else {
                          _serviceIds.remove(service.id);
                        }
                      }),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(servicesProvider)),
              _ => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            },
            if (widget.plan != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.membershipPlanOn),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            if (_error != null) Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ),
      ),
    );
  }
}
