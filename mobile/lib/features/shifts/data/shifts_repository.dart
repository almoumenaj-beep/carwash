import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/cash_shift.dart';

final shiftsRepositoryProvider = Provider<ShiftsRepository>((ref) => ShiftsRepository(ref.watch(dioProvider)));

/// The signed-in cashier's open shift at a branch, or null when they have none.
final currentShiftProvider = FutureProvider.autoDispose.family<CashShift?, String>(
  (ref, branchId) => ref.watch(shiftsRepositoryProvider).current(branchId),
);

/// Every open shift of the signed-in cashier's, at every branch. Used to make sure they close their
/// cashier before clocking out or signing out.
final myOpenShiftsProvider = FutureProvider.autoDispose<List<CashShift>>(
  (ref) => ref.watch(shiftsRepositoryProvider).mine(),
);

/// Recent shifts at a branch, newest first. Used to flag one the system had to close automatically.
final recentShiftsProvider = FutureProvider.autoDispose.family<List<CashShift>, String>(
  (ref, branchId) => ref.watch(shiftsRepositoryProvider).recent(branchId),
);

class ShiftsRepository {
  ShiftsRepository(this._dio);

  final Dio _dio;

  Future<CashShift?> current(String branchId) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/shifts/current', queryParameters: {'branch_id': branchId}),
    );
    final data = response.data!['data'];
    return data == null ? null : CashShift.fromJson(data as Map<String, dynamic>);
  }

  Future<List<CashShift>> mine() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/shifts/mine'));
    return [for (final shift in unwrapData<List>(response)) CashShift.fromJson(shift as Map<String, dynamic>)];
  }

  Future<List<CashShift>> recent(String branchId) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/shifts', queryParameters: {'branch_id': branchId}),
    );
    return [for (final shift in unwrapData<List>(response)) CashShift.fromJson(shift as Map<String, dynamic>)];
  }

  Future<CashShift> open(String branchId, int openingFloat) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/shifts', data: {'branch_id': branchId, 'opening_float': openingFloat}),
    );
    return CashShift.fromJson(unwrapData(response));
  }

  /// Closes the shift with the cash counted; [note] is required when the drawer does not match.
  Future<CashShift> close(String shiftId, int countedCash, {String? note}) async {
    final response = await sendRequest(
      () =>
          _dio.post<Map<String, dynamic>>('/shifts/$shiftId/close', data: {'counted_cash': countedCash, 'note': ?note}),
    );
    return CashShift.fromJson(unwrapData(response));
  }
}
