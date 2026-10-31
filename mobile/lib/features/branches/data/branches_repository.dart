import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/branch.dart';

final branchesRepositoryProvider = Provider<BranchesRepository>((ref) => BranchesRepository(ref.watch(dioProvider)));

final branchListProvider = FutureProvider.autoDispose<List<Branch>>(
  (ref) => ref.watch(branchesRepositoryProvider).list(),
);

final branchProvider = FutureProvider.autoDispose.family<Branch, String>(
  (ref, id) => ref.watch(branchesRepositoryProvider).find(id),
);

class BranchesRepository {
  BranchesRepository(this._dio);

  final Dio _dio;

  Future<List<Branch>> list() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/branches'));
    return [for (final branch in unwrapData<List>(response)) Branch.fromJson(branch as Map<String, dynamic>)];
  }

  Future<Branch> find(String id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/branches/$id'));
    return Branch.fromJson(unwrapData(response));
  }

  Future<Branch> create(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/branches', data: data));
    return Branch.fromJson(unwrapData(response));
  }

  Future<Branch> update(String id, Map<String, dynamic> changes) async {
    final response = await sendRequest(() => _dio.patch<Map<String, dynamic>>('/branches/$id', data: changes));
    return Branch.fromJson(unwrapData(response));
  }

  Future<Bay> addBay(String branchId, String name) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/branches/$branchId/bays', data: {'name': name}),
    );
    return Bay.fromJson(unwrapData(response));
  }

  Future<Bay> updateBay(String bayId, Map<String, dynamic> changes) async {
    final response = await sendRequest(() => _dio.patch<Map<String, dynamic>>('/bays/$bayId', data: changes));
    return Bay.fromJson(unwrapData(response));
  }
}
