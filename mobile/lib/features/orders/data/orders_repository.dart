import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../../branches/domain/branch.dart';
import '../domain/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersRepository(ref.watch(dioProvider)));

/// Which list of a branch's orders: the cars still in the wash, or everything checked in today.
enum QueueScope { active, today }

/// A branch's orders for [QueueScope]; the queue screen refreshes it every few seconds.
final branchOrdersProvider = FutureProvider.autoDispose.family<List<Order>, ({String branchId, QueueScope scope})>(
  (ref, query) => ref.watch(ordersRepositoryProvider).list(query.branchId, query.scope),
);

final orderProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(ordersRepositoryProvider).find(id),
);

/// The active bays of a branch, for choosing where a car is washed.
final branchBaysProvider = FutureProvider.autoDispose.family<List<Bay>, String>(
  (ref, branchId) => ref.watch(ordersRepositoryProvider).bays(branchId),
);

/// The active staff working at a branch, for assigning washers.
final branchStaffProvider = FutureProvider.autoDispose.family<List<NamedRef>, String>(
  (ref, branchId) => ref.watch(ordersRepositoryProvider).staff(branchId),
);

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  Future<List<Order>> list(String branchId, QueueScope scope) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/orders', queryParameters: {'branch_id': branchId, 'scope': scope.name}),
    );
    return [for (final order in unwrapData<List>(response)) Order.fromJson(order as Map<String, dynamic>)];
  }

  Future<Order> find(String id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/orders/$id'));
    return Order.fromJson(unwrapData(response));
  }

  Future<Order> checkIn(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/orders', data: data));
    return Order.fromJson(unwrapData(response));
  }

  Future<Order> update(String id, Map<String, dynamic> changes) async {
    final response = await sendRequest(() => _dio.patch<Map<String, dynamic>>('/orders/$id', data: changes));
    return Order.fromJson(unwrapData(response));
  }

  /// Moves the order on; [reason] is required when cancelling, and [checklist] (order item id → done
  /// properly) when leaving the quality check.
  Future<Order> changeStatus(String id, OrderStatus status, {String? reason, Map<String, bool>? checklist}) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/orders/$id/status',
        data: {
          'status': status.apiValue,
          'reason': ?reason,
          if (checklist != null)
            'checklist': [
              for (final MapEntry(key: itemId, value: passed) in checklist.entries)
                {'item_id': itemId, 'passed': passed},
            ],
        },
      ),
    );
    return Order.fromJson(unwrapData(response));
  }

  /// Takes cash for the order and issues its invoice. A discount is an amount in minor units or a percentage
  /// in basis points (with a reason); [deliver] also hands a ready car over.
  Future<Order> checkout(
    String id, {
    int? discountAmount,
    int? discountPercentBps,
    String? discountReason,
    int? tendered,
    bool deliver = false,
  }) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/orders/$id/checkout',
        data: {
          'method': 'cash',
          'discount_amount': ?discountAmount,
          'discount_percent_bps': ?discountPercentBps,
          'discount_reason': ?discountReason,
          'tendered': ?tendered,
          'deliver': deliver,
        },
      ),
    );
    return Order.fromJson(unwrapData(response));
  }

  Future<List<Bay>> bays(String branchId) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/branches/$branchId/bays'));
    return [for (final bay in unwrapData<List>(response)) Bay.fromJson(bay as Map<String, dynamic>)]
        .where((bay) => bay.isActive)
        .toList();
  }

  Future<List<NamedRef>> staff(String branchId) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/branches/$branchId/staff'));
    return [for (final member in unwrapData<List>(response)) NamedRef.fromJson(member as Map<String, dynamic>)];
  }
}
