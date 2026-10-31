import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/language_button.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';
import '../domain/me.dart';

final deviceStaffProvider = FutureProvider.autoDispose<List<DeviceStaff>>(
  (ref) => ref.watch(authRepositoryProvider).deviceStaff(),
);

/// Quick switch on a shared device: pick who is working, enter their PIN.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final _pin = TextEditingController();
  DeviceStaff? _selected;
  bool _submitting = false;
  Object? _error;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final staff = _selected;
    if (staff == null || _pin.text.length < 4) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(sessionProvider.notifier).pinSignIn(userId: staff.id, pin: _pin.text);
      if (mounted) {
        context.go('/');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
        _pin.clear();
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pinTitle), actions: const [LanguageButton()]),
      body: switch (ref.watch(deviceStaffProvider)) {
        AsyncData(:final value) when value.isEmpty => _NoStaffWithPin(onUsePassword: () => context.go('/login')),
        AsyncData(:final value) => _buildPicker(context, value),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(deviceStaffProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  Widget _buildPicker(BuildContext context, List<DeviceStaff> staff) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final problem = _error is ApiProblem ? _error as ApiProblem : null;
    final pinError = problem?.fieldError('pin');

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final member in staff)
                    ChoiceChip(
                      avatar: CircleAvatar(child: Text(member.name.characters.first)),
                      label: Text(member.name),
                      selected: _selected?.id == member.id,
                      onSelected: (_) => setState(() {
                        _selected = member;
                        _error = null;
                        _pin.clear();
                      }),
                    ),
                ],
              ),
              if (_selected != null) ...[
                const SizedBox(height: 24),
                TextField(
                  key: const Key('pin-field'),
                  controller: _pin,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 12),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.pinField, errorText: pinError, counterText: ''),
                ),
                if (_error != null && pinError == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    problemMessage(context, _error!),
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.pinSignInButton),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.go('/login'), child: Text(l10n.signInWithPassword)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoStaffWithPin extends StatelessWidget {
  const _NoStaffWithPin({required this.onUsePassword});

  final VoidCallback onUsePassword;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.noStaffWithPin, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onUsePassword, child: Text(l10n.signInWithPassword)),
          ],
        ),
      ),
    );
  }
}
