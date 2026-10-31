import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'problem_message.dart';

/// A full-area error with a retry button.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(problemMessage(context, error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(AppLocalizations.of(context).retry)),
          ],
        ),
      ),
    );
  }
}
