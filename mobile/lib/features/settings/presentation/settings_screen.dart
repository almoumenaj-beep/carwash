import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../data/settings_repository.dart';
import '../domain/app_settings.dart';

/// Time zones offered for Gulf car washes; the saved one is always included.
const _gulfTimezones = ['Asia/Bahrain', 'Asia/Riyadh', 'Asia/Kuwait', 'Asia/Qatar', 'Asia/Dubai', 'Asia/Muscat'];

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(settingsProvider)) {
      AsyncData(:final value) => _SettingsForm(settings: value),
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
  late bool _pricesIncludeVat = widget.settings.pricesIncludeVat;
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
    super.dispose();
  }

  Future<void> _save() async {
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
        'locale': _locale,
        'timezone': _timezone,
      });
      ref.invalidate(settingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
      }
    } on ApiProblem catch (problem) {
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
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.carWashName, errorText: _problem?.fieldError('name')),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: InputDecoration(labelText: l10n.currency, helperText: l10n.currencyLocked),
              child: Text('${widget.settings.currency} · ${l10n.currencyDecimals(widget.settings.currencyDecimals)}'),
            ),
            const SizedBox(height: 24),
            Text(l10n.vatSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),
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
              decoration: InputDecoration(labelText: l10n.timezoneField, errorText: _problem?.fieldError('timezone')),
              items: [for (final zone in timezones) DropdownMenuItem(value: zone, child: Text(zone))],
              onChanged: (value) => setState(() => _timezone = value ?? _timezone),
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
