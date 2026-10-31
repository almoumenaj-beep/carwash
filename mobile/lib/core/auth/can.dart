import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';

/// Shows [child] only when the signed-in user holds at least one of [anyOf].
///
/// Hiding is for a cleaner screen only: the server enforces every permission and answers 403.
class Can extends ConsumerWidget {
  const Can({super.key, required this.anyOf, required this.child, this.otherwise = const SizedBox.shrink()});

  final List<String> anyOf;
  final Widget child;
  final Widget otherwise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    final allowed = me != null && anyOf.any(me.can);

    return allowed ? child : otherwise;
  }
}
