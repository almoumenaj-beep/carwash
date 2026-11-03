import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/equipment.dart';

final equipmentRepositoryProvider = Provider<EquipmentRepository>((ref) => EquipmentRepository(ref.watch(dioProvider)));

/// Equipment at every branch the user works in, what is due for maintenance first.
final equipmentProvider = FutureProvider.autoDispose<List<Equipment>>(
  (ref) => ref.watch(equipmentRepositoryProvider).list(),
);

final maintenancesProvider = FutureProvider.autoDispose.family<List<Maintenance>, String>(
  (ref, equipmentId) => ref.watch(equipmentRepositoryProvider).maintenances(equipmentId),
);

class EquipmentRepository {
  EquipmentRepository(this._dio);

  final Dio _dio;

  Future<List<Equipment>> list() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/equipment'));
    return [for (final item in unwrapData<List>(response)) Equipment.fromJson(item as Map<String, dynamic>)];
  }

  Future<void> create(Map<String, dynamic> data) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/equipment', data: data));
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/equipment/$id', data: data));
  }

  Future<List<Maintenance>> maintenances(String equipmentId) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/equipment/$equipmentId/maintenances'));
    return [for (final item in unwrapData<List>(response)) Maintenance.fromJson(item as Map<String, dynamic>)];
  }

  Future<void> recordMaintenance(String equipmentId, Map<String, dynamic> data) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/equipment/$equipmentId/maintenances', data: data));
  }
}
