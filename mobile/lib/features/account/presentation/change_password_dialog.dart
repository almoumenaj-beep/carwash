import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';

/// Lets the signed-in staff member change their own password, once they confirm the current one.
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _currentPassword.dispose();
    _password.dispose();
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
      await ref
          .read(sessionProvider.notifier)
          .setPassword(currentPassword: _currentPassword.text, password: _password.text);
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
    final currentPasswordError = problem?.fieldError('current_password');
    final passwordError = problem?.fieldError('password');
    final showGeneralError = _error != null && currentPasswordError == null && passwordError == null;

    return AlertDialog(
      title: Text(l10n.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _currentPassword,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.currentPasswordField, errorText: currentPasswordError),
              validator: (value) => (value == null || value.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.newPasswordField, errorText: passwordError),
              validator: (value) => (value != null && value.length >= 8) ? null : l10n.passwordTooShort,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmation,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.confirmPasswordField),
              validator: (value) => value == _password.text ? null : l10n.passwordsDoNotMatch,
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
