import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/pin_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/branches/presentation/branch_editor_screen.dart';
import '../../features/branches/presentation/branches_screen.dart';
import '../../features/devices/presentation/devices_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/roles/presentation/role_editor_screen.dart';
import '../../features/roles/presentation/roles_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/staff/presentation/staff_editor_screen.dart';
import '../../features/staff/presentation/staff_screen.dart';
import '../auth/route_permissions.dart';

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

      final me = session.value;

      // The PIN screen serves both signed-out devices and signed-in staff handing over.
      if (location == '/pin') {
        return null;
      }
      if (me == null) {
        return location == '/login' ? null : '/login';
      }
      if (location == '/login' || location == '/splash') {
        return '/';
      }

      // PermissionGuard: sections the user may not open fall back to home (the server would refuse anyway).
      return canOpen(state.uri.path, me) ? null : '/';
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/pin', builder: (_, _) => const PinScreen()),
      GoRoute(
        path: '/roles',
        builder: (_, _) => const RolesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const RoleEditorScreen()),
          GoRoute(
            path: ':roleId',
            builder: (_, state) => RoleEditorScreen(roleId: int.parse(state.pathParameters['roleId']!)),
          ),
        ],
      ),
      GoRoute(
        path: '/staff',
        builder: (_, _) => const StaffScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const StaffEditorScreen()),
          GoRoute(
            path: ':staffId',
            builder: (_, state) => StaffEditorScreen(staffId: state.pathParameters['staffId']),
          ),
        ],
      ),
      GoRoute(path: '/devices', builder: (_, _) => const DevicesScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/branches',
        builder: (_, _) => const BranchesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const BranchEditorScreen()),
          GoRoute(
            path: ':branchId',
            builder: (_, state) => BranchEditorScreen(branchId: state.pathParameters['branchId']),
          ),
        ],
      ),
    ],
  );
});
