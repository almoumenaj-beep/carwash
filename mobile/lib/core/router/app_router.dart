import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/pin_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final sessionChanges = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => sessionChanges.value++);
  ref.onDispose(sessionChanges.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: sessionChanges,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final location = state.matchedLocation;

      if (!session.hasValue) {
        return location == '/splash' ? null : '/splash';
      }

      final signedIn = session.value != null;

      // The PIN screen serves both signed-out devices and signed-in staff handing over.
      if (location == '/pin') {
        return null;
      }
      if (!signedIn) {
        return location == '/login' ? null : '/login';
      }

      return (location == '/login' || location == '/splash') ? '/' : null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
    ],
  );
});
