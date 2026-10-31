import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';

final isTrustedDeviceProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(authRepositoryProvider).isTrustedDevice(),
);

/// Email/phone and password sign-in. Offers PIN switching once this device has been trusted.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
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
      await ref.read(sessionProvider.notifier).signIn(login: _login.text.trim(), password: _password.text);
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
    final theme = Theme.of(context);
    final problem = _error is ApiProblem ? _error as ApiProblem : null;
    final loginError = problem?.fieldError('login');
    final passwordError = problem?.fieldError('password');
    final showGeneralError = _error != null && loginError == null && passwordError == null;
    String? required(String? value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null;

    return Scaffold(
      appBar: AppBar(actions: const [LanguageButton()]),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.local_car_wash, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(l10n.signInTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(l10n.signInSubtitle, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('login-field'),
                      controller: _login,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: InputDecoration(
                        labelText: l10n.loginField,
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: loginError,
                      ),
                      validator: required,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('password-field'),
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: l10n.passwordField,
                        prefixIcon: const Icon(Icons.lock_outline),
                        errorText: passwordError,
                      ),
                      validator: required,
                    ),
                    if (showGeneralError) ...[
                      const SizedBox(height: 16),
                      Text(
                        problemMessage(context, _error!),
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('sign-in-button'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.signInButton),
                    ),
                    if (ref.watch(isTrustedDeviceProvider).value ?? false) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.go('/pin'),
                        icon: const Icon(Icons.pin_outlined),
                        label: Text(l10n.switchUserWithPin),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
