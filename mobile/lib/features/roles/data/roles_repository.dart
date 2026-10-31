import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/role.dart';

final rolesRepositoryProvider = Provider<RolesRepository>((ref) => RolesRepository(ref.watch(dioProvider)));

/// The car wash's roles. Labels are translated, so the list is refetched when the language changes.
final rolesProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(rolesRepositoryProvider).roles();
});

final roleProvider = FutureProvider.autoDispose.family<Role, int>((ref, id) {
  ref.watch(localeProvider);
  return ref.watch(rolesRepositoryProvider).role(id);
});

final permissionCatalogProvider = FutureProvider.autoDispose<List<PermissionModule>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(rolesRepositoryProvider).permissionCatalog();
});

class RolesRepository {
  RolesRepository(this._dio);

  final Dio _dio;

  Future<List<Role>> roles() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/roles'));
    return [for (final role in unwrapData<List>(response)) Role.fromJson(role as Map<String, dynamic>)];
  }

  Future<Role> role(int id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/roles/$id'));
    return Role.fromJson(unwrapData(response));
  }

  Future<List<PermissionModule>> permissionCatalog() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/permissions'));
    return [for (final module in unwrapData<List>(response)) PermissionModule.fromJson(module as Map<String, dynamic>)];
  }

  Future<Role> create({required String name, required Set<String> permissions}) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/roles', data: {'name': name, 'permissions': permissions.toList()}),
    );
    return Role.fromJson(unwrapData(response));
  }

  Future<void> rename(int id, String name) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/roles/$id', data: {'name': name}));
  }

  Future<void> syncPermissions(int id, Set<String> permissions) async {
    await sendRequest(
      () => _dio.put<Map<String, dynamic>>('/roles/$id/permissions', data: {'permissions': permissions.toList()}),
    );
  }

  Future<void> delete(int id) async {
    await sendRequest(() => _dio.delete<void>('/roles/$id'));
  }
}
