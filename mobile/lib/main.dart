import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/application/session_controller.dart';

void main() {
  runApp(
    ProviderScope(
      // Failed requests surface to the user with a retry button instead of retrying silently.
      retry: (retryCount, error) => null,
      overrides: [
        unauthorizedHandlerProvider.overrideWith(
          (ref) => () => ref.read(sessionProvider.notifier).expire(),
        ),
      ],
      child: const CarWashApp(),
    ),
  );
}
