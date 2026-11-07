import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money_format.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../memberships/presentation/membership_plans_screen.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';
import 'message_templates_screen.dart';

/// Time zones offered for Gulf car washes; the saved one is always included.
const _gulfTimezones = ['Asia/Bahrain', 'Asia/Riyadh', 'Asia/Kuwait', 'Asia/Qatar', 'Asia/Dubai', 'Asia/Muscat'];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(settingsProvider)) {
      // Kept while reloading, so what is being typed survives a save made elsewhere on this screen.
      AsyncValue(hasValue: true, :final value?) => _SettingsForm(settings: value),
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

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.settings.name);
  late final _vatRate = TextEditingController(text: _formatRate(widget.settings.vatRate));
  late final _vatNumber = TextEditingController(text: widget.settings.vatNumber);
  late final _graceMinutes = TextEditingController(text: widget.settings.appointmentGraceMinutes?.toString());
  late bool _pricesIncludeVat = widget.settings.pricesIncludeVat;
  late bool _pointsEnabled = widget.settings.pointsEnabled;
  late bool _membershipsEnabled = widget.settings.membershipsEnabled;
  late final _pointsEarnAmount = TextEditingController(
    text: ref.read(moneyFormatProvider).toInput(widget.settings.pointsEarnAmount),
  );
  late final _pointsRedeemPoints = TextEditingController(text: '${widget.settings.pointsRedeemPoints}');
  late final _pointsRedeemValue = TextEditingController(
    text: ref.read(moneyFormatProvider).toInput(widget.settings.pointsRedeemValue),
  );
  late final _pointsExpiryMonths = TextEditingController(text: widget.settings.pointsExpiryMonths?.toString() ?? '');
  late String _locale = widget.settings.locale;
  late String _timezone = widget.settings.timezone;
  bool _saving = false;
  ApiProblem? _problem;

  static String _formatRate(double rate) => rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : '$rate';

  @override
  void dispose() {
    _name.dispose();
    _vatRate.dispose();
    _vatNumber.dispose();
    _graceMinutes.dispose();
    _pointsEarnAmount.dispose();
    _pointsRedeemPoints.dispose();
    _pointsRedeemValue.dispose();
    _pointsExpiryMonths.dispose();
    super.dispose();
  }

  /// Saved at once: this switch opens the plans, so nothing should depend on pressing save further down. Goes back
  /// if it could not be saved.
  Future<void> _setMemberships(bool enabled) async {
    setState(() => _membershipsEnabled = enabled);
    try {
      await ref.read(settingsRepositoryProvider).update({'memberships_enabled': enabled});
      ref.invalidate(settingsProvider);
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() {
          _membershipsEnabled = !enabled;
          _problem = problem;
        });
      }
    }
  }

  Future<void> _save() async {
    final money = ref.read(moneyFormatProvider);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });

    try {
      await ref.read(settingsRepositoryProvider).update({
        'name': _name.text.trim(),
        'vat_rate': double.parse(_vatRate.text.trim()),
        'prices_include_vat': _pricesIncludeVat,
        'vat_number': _vatNumber.text.trim().isEmpty ? null : _vatNumber.text.trim(),
        'appointment_grace_minutes': int.tryParse(_graceMinutes.text.trim()),
        'memberships_enabled': _membershipsEnabled,
        'points_enabled': _pointsEnabled,
        if (_pointsEnabled) ...{
          'points_earn_amount': money.parse(_pointsEarnAmount.text),
          'points_redeem_points': int.parse(_pointsRedeemPoints.text.trim()),
          'points_redeem_value': money.parse(_pointsRedeemValue.text),
          'points_expiry_months': int.tryParse(_pointsExpiryMonths.text.trim()),
        },
        'locale': _locale,
        'timezone': _timezone,
      });
      ref.invalidate(settingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final money = ref.watch(moneyFormatProvider);
    final earnPreview = money.parse(_pointsEarnAmount.text);
    final redeemPreview = money.parse(_pointsRedeemValue.text);
    final redeemPointsPreview = int.tryParse(_pointsRedeemPoints.text.trim());
    String? positiveMoney(String? value) => (money.parse(value ?? '') ?? 0) < 1 ? l10n.pointsFieldInvalid : null;
    final timezones = {..._gulfTimezones, widget.settings.timezone}.toList();
    final generalError = _problem != null && _problem!.errors.isEmpty ? problemMessage(context, _problem!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
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
            _Section(
              title: l10n.settingsGeneralSection,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.carWashName, errorText: _problem?.fieldError('name')),
                  validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.currency, helperText: l10n.currencyLocked),
                  child: Text(
                    '${widget.settings.currency} · ${l10n.currencyDecimals(widget.settings.currencyDecimals)}',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _locale,
                  decoration: InputDecoration(labelText: l10n.languageField),
                  items: [
                    DropdownMenuItem(value: 'ar', child: Text(l10n.arabicLanguage)),
                    DropdownMenuItem(value: 'en', child: Text(l10n.englishLanguage)),
                  ],
                  onChanged: (value) => setState(() => _locale = value ?? _locale),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _timezone,
                  decoration: InputDecoration(
                    labelText: l10n.timezoneField,
                    errorText: _problem?.fieldError('timezone'),
                  ),
                  items: [for (final zone in timezones) DropdownMenuItem(value: zone, child: Text(zone))],
                  onChanged: (value) => setState(() => _timezone = value ?? _timezone),
                ),
              ],
            ),
            _Section(
              title: l10n.vatSection,
              children: [
                TextFormField(
                  controller: _vatRate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: InputDecoration(
                    labelText: l10n.vatRate,
                    suffixText: '%',
                    errorText: _problem?.fieldError('vat_rate'),
                  ),
                  validator: (value) {
                    final rate = double.tryParse(value?.trim() ?? '');
                    return rate == null || rate < 0 || rate > 100 ? l10n.vatRateInvalid : null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pricesIncludeVat),
                  value: _pricesIncludeVat,
                  onChanged: (value) => setState(() => _pricesIncludeVat = value),
                ),
                TextFormField(
                  controller: _vatNumber,
                  decoration: InputDecoration(labelText: l10n.vatNumber, errorText: _problem?.fieldError('vat_number')),
                ),
              ],
            ),
            _Section(
              title: l10n.appointmentsTitle,
              children: [
                TextFormField(
                  controller: _graceMinutes,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.graceMinutesField,
                    suffixText: l10n.minutesUnit,
                    helperText: l10n.graceMinutesHint,
                    helperMaxLines: 3,
                    errorText: _problem?.fieldError('appointment_grace_minutes'),
                  ),
                  validator: (value) {
                    final minutes = int.tryParse(value?.trim() ?? '');
                    return (value ?? '').trim().isNotEmpty && (minutes == null || minutes < 5 || minutes > 720)
                        ? l10n.graceMinutesInvalid
                        : null;
                  },
                ),
              ],
            ),
            _Section(
              title: l10n.settingsRewardsSection,
              children: [
                Text(l10n.membershipsTitle, style: theme.textTheme.titleSmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.membershipsEnabledField),
                  subtitle: Text(l10n.membershipsEnabledHint),
                  value: _membershipsEnabled,
                  onChanged: _setMemberships,
                ),
                if (_membershipsEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.card_membership_outlined),
                    title: Text(l10n.membershipPlansTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const MembershipPlansScreen())),
                  ),
                const Divider(height: 32),
                Text(l10n.pointsTitle, style: theme.textTheme.titleSmall),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.pointsEnabledField),
                  subtitle: Text(l10n.pointsEnabledHint),
                  value: _pointsEnabled,
                  onChanged: (value) => setState(() => _pointsEnabled = value),
                ),
                if (_pointsEnabled) ...[
                  TextFormField(
                    controller: _pointsEarnAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.pointsEarnField,
                      suffixText: money.currency,
                      errorText: _problem?.fieldError('points_earn_amount'),
                    ),
                    validator: positiveMoney,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pointsRedeemPoints,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.pointsRedeemPointsField,
                      errorText: _problem?.fieldError('points_redeem_points'),
                    ),
                    validator: (value) => (int.tryParse(value?.trim() ?? '') ?? 0) < 1 ? l10n.pointsFieldInvalid : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pointsRedeemValue,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.pointsRedeemValueField,
                      suffixText: money.currency,
                      errorText: _problem?.fieldError('points_redeem_value'),
                    ),
                    validator: positiveMoney,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pointsExpiryMonths,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.pointsExpiryField,
                      suffixText: l10n.pointsMonthsUnit,
                      helperText: l10n.pointsExpiryHint,
                      helperMaxLines: 2,
                      errorText: _problem?.fieldError('points_expiry_months'),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      final months = int.tryParse(text);
                      return text.isNotEmpty && (months == null || months < 1 || months > 120)
                          ? l10n.pointsExpiryInvalid
                          : null;
                    },
                  ),
                  if (earnPreview != null && redeemPreview != null && redeemPointsPreview != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.pointsRuleSummary(
                        money.format(earnPreview),
                        redeemPointsPreview,
                        money.format(redeemPreview),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ],
            ),
            _Section(
              title: l10n.messageTemplatesTitle,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(l10n.messageTemplatesTitle),
                  subtitle: Text(l10n.messageTemplatesSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => const MessageTemplatesScreen())),
                ),
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

/// One topic of the settings, in its own card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
