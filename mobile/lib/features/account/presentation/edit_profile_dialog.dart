import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import 'change_password_dialog.dart';

/// Lets the signed-in staff member edit their own email and phone, and change their password. Their name is set
/// by whoever manages staff, so it stays recognisable to everyone else; it shows here read-only.
class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({super.key, required this.me});

  final Me me;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.me.email ?? '');
  late final _phone = TextEditingController(text: widget.me.phone ?? '');
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
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
          .updateProfile(
            email: _email.text.trim().isEmpty ? null : _email.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );
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

  Future<void> _changePassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).passwordChanged;
    final saved = await showDialog<bool>(context: context, builder: (_) => const ChangePasswordDialog());
    if (saved ?? false) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _error is ApiProblem ? _error as ApiProblem : null;
    final emailError = problem?.fieldError('email');
    final phoneError = problem?.fieldError('phone');
    final showGeneralError = _error != null && emailError == null && phoneError == null;

    return AlertDialog(
      title: Text(l10n.editProfile),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: widget.me.name,
              enabled: false,
              decoration: InputDecoration(labelText: l10n.nameField),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.emailField, errorText: emailError),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.phoneField, errorText: phoneError),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_outlined),
                label: Text(l10n.changePassword),
              ),
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
