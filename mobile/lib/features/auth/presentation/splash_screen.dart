import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_view.dart';
import '../application/session_controller.dart';

/// Shown while the saved session is checked, or when the server cannot be reached at start-up.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: session.hasError
          ? ErrorView(error: session.error!, onRetry: () => ref.invalidate(sessionProvider))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
