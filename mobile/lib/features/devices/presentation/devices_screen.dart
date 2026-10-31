import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../data/devices_repository.dart';

/// Devices signed in to the car wash; a lost one can be revoked to end its session immediately.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesTitle)),
      body: switch (ref.watch(devicesProvider)) {
        AsyncData(:final value) when value.isEmpty => Center(child: Text(l10n.noDevices)),
        AsyncData(:final value) => RefreshIndicator(
          onRefresh: () => ref.refresh(devicesProvider.future),
          child: ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) => _DeviceTile(device: value[index]),
          ),
        ),
        AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(devicesProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  const _DeviceTile({required this.device});

  final RegisteredDevice device;

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.revokeDeviceConfirm(device.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.revokeDevice)),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(devicesRepositoryProvider).revoke(device.id);
      ref.invalidate(devicesProvider);
    } on ApiProblem catch (problem) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problemMessage(context, problem))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final lastLogin = device.lastLoginAt == null ? null : DateFormat.yMMMd(locale).add_jm().format(device.lastLoginAt!);

    return ListTile(
      leading: Icon(device.platform == 'web' ? Icons.laptop : Icons.smartphone),
      title: Text(device.name),
      subtitle: lastLogin == null ? null : Text(l10n.lastSignIn(lastLogin)),
      trailing: device.isRevoked
          ? Chip(label: Text(l10n.revoked))
          : TextButton(onPressed: () => _revoke(context, ref), child: Text(l10n.revokeDevice)),
    );
  }
}
