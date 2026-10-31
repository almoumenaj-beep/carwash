import '../../features/auth/domain/me.dart';

/// Permission names used by the app; they mirror the server's catalog.
abstract final class Permissions {
  static const rolesManage = 'roles.manage';
  static const usersManage = 'users.manage';
  static const settingsManage = 'settings.manage';
}

/// Which permissions open each section; holding any one of them is enough.
const routePermissions = <String, List<String>>{
  '/roles': [Permissions.rolesManage, Permissions.usersManage],
  '/staff': [Permissions.usersManage],
  '/devices': [Permissions.usersManage],
  '/settings': [Permissions.settingsManage],
  '/branches': [Permissions.settingsManage],
};

/// Whether [me] may open [location] (a path such as `/staff/42`).
bool canOpen(String location, Me me) {
  for (final MapEntry(key: prefix, value: required) in routePermissions.entries) {
    if (location == prefix || location.startsWith('$prefix/')) {
      return required.any(me.can);
    }
  }

  return true;
}
