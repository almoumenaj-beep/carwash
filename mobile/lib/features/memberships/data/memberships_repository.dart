import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/membership.dart';

final membershipsRepositoryProvider = Provider<MembershipsRepository>(
  (ref) => MembershipsRepository(ref.watch(dioProvider)),
);

final membershipPlansProvider = FutureProvider.autoDispose<List<MembershipPlan>>(
  (ref) => ref.watch(membershipsRepositoryProvider).plans(),
);

final customerMembershipsProvider = FutureProvider.autoDispose.family<List<CustomerMembership>, String>(
  (ref, customerId) => ref.watch(membershipsRepositoryProvider).ofCustomer(customerId),
);

class MembershipsRepository {
  MembershipsRepository(this._dio);

  final Dio _dio;

  Future<List<MembershipPlan>> plans() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/membership-plans'));
    return [for (final plan in unwrapData<List>(response)) MembershipPlan.fromJson(plan as Map<String, dynamic>)];
  }

  Future<void> createPlan(Map<String, dynamic> data) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/membership-plans', data: data));
  }

  Future<void> updatePlan(String id, Map<String, dynamic> data) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/membership-plans/$id', data: data));
  }

  Future<List<CustomerMembership>> ofCustomer(String customerId) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/customers/$customerId/memberships'));
    return [
      for (final membership in unwrapData<List>(response))
        CustomerMembership.fromJson(membership as Map<String, dynamic>),
    ];
  }

  Future<void> sell(
    String customerId, {
    required String planId,
    required String branchId,
    required String method,
    String? vehicleId,
  }) async {
    await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/customers/$customerId/memberships',
        data: {'membership_plan_id': planId, 'branch_id': branchId, 'method': method, 'vehicle_id': ?vehicleId},
      ),
    );
  }

  /// Stops a membership; no money is returned.
  Future<void> cancel(String membershipId) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/customer-memberships/$membershipId/cancel'));
  }
}
