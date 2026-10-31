import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';

/// Lets the signed-in staff member set the PIN they use to switch in on shared devices.
class SetPinDialog extends ConsumerStatefulWidget {
  const SetPinDialog({super.key});

  @override
  ConsumerState<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends ConsumerState<SetPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(authRepositoryProvider).setPin(currentPassword: _currentPassword.text, pin: _pin.text);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _error is ApiProblem ? _error as ApiProblem : null;
    final passwordError = problem?.fieldError('current_password');
    final pinError = problem?.fieldError('pin');
    final showGeneralError = _error != null && passwordError == null && pinError == null;
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return AlertDialog(
      title: Text(l10n.setPin),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPassword,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.currentPasswordField, errorText: passwordError),
              validator: (value) => (value == null || value.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: digits,
              decoration: InputDecoration(labelText: l10n.newPinField, errorText: pinError, counterText: ''),
              validator: (value) => RegExp(r'^\d{4,6}$').hasMatch(value ?? '') ? null : l10n.pinMustBeDigits,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmation,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: digits,
              decoration: InputDecoration(labelText: l10n.confirmPinField, counterText: ''),
              validator: (value) => value == _pin.text ? null : l10n.pinsDoNotMatch,
            ),
            if (showGeneralError)
              Text(problemMessage(context, _error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        FilledButton(onPressed: _submitting ? null : _submit, child: Text(l10n.save)),
      ],
    );
  }
}
