import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/catalog.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(dioProvider)));

final vehicleSizesProvider = FutureProvider.autoDispose<List<VehicleSize>>(
  (ref) => ref.watch(catalogRepositoryProvider).sizes(),
);

final serviceCategoriesProvider = FutureProvider.autoDispose<List<ServiceCategory>>(
  (ref) => ref.watch(catalogRepositoryProvider).categories(),
);

final servicesProvider = FutureProvider.autoDispose<List<CatalogService>>(
  (ref) => ref.watch(catalogRepositoryProvider).services(),
);

final serviceProvider = FutureProvider.autoDispose.family<CatalogService, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).service(id),
);

/// Which simple catalog list an entry belongs to; maps to its API path.
enum CatalogEntryKind {
  vehicleSize('/vehicle-sizes'),
  serviceCategory('/service-categories');

  const CatalogEntryKind(this.path);

  final String path;
}

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<VehicleSize>> sizes() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/vehicle-sizes'));
    return [for (final size in unwrapData<List>(response)) VehicleSize.fromJson(size as Map<String, dynamic>)];
  }

  Future<List<ServiceCategory>> categories() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/service-categories'));
    return [
      for (final category in unwrapData<List>(response)) ServiceCategory.fromJson(category as Map<String, dynamic>),
    ];
  }

  Future<void> createEntry(CatalogEntryKind kind, String name) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>(kind.path, data: {'name': name}));
  }

  Future<void> updateEntry(CatalogEntryKind kind, String id, Map<String, dynamic> changes) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('${kind.path}/$id', data: changes));
  }

  Future<void> deleteEntry(CatalogEntryKind kind, String id) async {
    await sendRequest(() => _dio.delete<void>('${kind.path}/$id'));
  }

  Future<List<CatalogService>> services() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/services'));
    return [for (final service in unwrapData<List>(response)) CatalogService.fromJson(service as Map<String, dynamic>)];
  }

  Future<CatalogService> service(String id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/services/$id'));
    return CatalogService.fromJson(unwrapData(response));
  }

  Future<CatalogService> createService(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/services', data: data));
    return CatalogService.fromJson(unwrapData(response));
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/services/$id', data: data));
  }

  Future<void> deleteService(String id) async {
    await sendRequest(() => _dio.delete<void>('/services/$id'));
  }
}
