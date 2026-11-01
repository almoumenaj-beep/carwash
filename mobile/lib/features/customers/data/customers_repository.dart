import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/customer.dart';

final customersRepositoryProvider = Provider<CustomersRepository>((ref) => CustomersRepository(ref.watch(dioProvider)));

/// Customers matching what was typed (name, phone or plate); the newest when nothing was typed.
final customerSearchProvider = FutureProvider.autoDispose.family<List<Customer>, String>(
  (ref, term) => ref.watch(customersRepositoryProvider).search(term),
);

final customerProvider = FutureProvider.autoDispose.family<Customer, String>(
  (ref, id) => ref.watch(customersRepositoryProvider).find(id),
);

class CustomersRepository {
  CustomersRepository(this._dio);

  final Dio _dio;

  /// The first page (20) of matches, which is what the counter needs while typing.
  Future<List<Customer>> search(String term) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/customers',
        queryParameters: {if (term.trim().isNotEmpty) 'search': term.trim()},
      ),
    );
    return [for (final customer in unwrapData<List>(response)) Customer.fromJson(customer as Map<String, dynamic>)];
  }

  Future<Customer> find(String id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/customers/$id'));
    return Customer.fromJson(unwrapData(response));
  }

  Future<Customer> create(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/customers', data: data));
    return Customer.fromJson(unwrapData(response));
  }

  Future<void> update(String id, Map<String, dynamic> changes) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/customers/$id', data: changes));
  }

  Future<void> delete(String id) async {
    await sendRequest(() => _dio.delete<void>('/customers/$id'));
  }

  Future<void> addVehicle(String customerId, Vehicle vehicle) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/customers/$customerId/vehicles', data: vehicle.toJson()));
  }

  Future<void> updateVehicle(String vehicleId, Vehicle vehicle) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/vehicles/$vehicleId', data: vehicle.toJson()));
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await sendRequest(() => _dio.delete<void>('/vehicles/$vehicleId'));
  }
}
