import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../../auth/application/session_controller.dart';
import '../domain/staff_affairs.dart';

final staffAffairsRepositoryProvider = Provider<StaffAffairsRepository>(
  (ref) => StaffAffairsRepository(ref.watch(dioProvider)),
);

final employeesProvider = FutureProvider.autoDispose<List<Employee>>(
  (ref) => ref.watch(staffAffairsRepositoryProvider).employees(),
);

/// The signed-in user's open attendance record, or null when they are not clocked in. Loaded again when
/// another staff member takes over the device ("switch user"), since the home screen stays open.
final myAttendanceProvider = FutureProvider.autoDispose<AttendanceRecord?>((ref) {
  ref.watch(sessionProvider.select((session) => session.value?.id));
  return ref.watch(staffAffairsRepositoryProvider).myAttendance();
});

final branchAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceRecord>, ({String branchId, String date})>(
      (ref, query) => ref.watch(staffAffairsRepositoryProvider).attendance(query.branchId, query.date),
    );

/// A branch's attendance per staff member over a period. Dates are `YYYY-MM-DD`.
final attendanceSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummary, ({String branchId, String from, String to})>(
      (ref, query) => ref.watch(staffAffairsRepositoryProvider).attendanceSummary(query.branchId, query.from, query.to),
    );

final payrollRunsProvider = FutureProvider.autoDispose<List<PayrollRun>>(
  (ref) => ref.watch(staffAffairsRepositoryProvider).payrollRuns(),
);

class StaffAffairsRepository {
  StaffAffairsRepository(this._dio);

  final Dio _dio;

  Future<List<Employee>> employees() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/employees'));
    return [for (final employee in unwrapData<List>(response)) Employee.fromJson(employee as Map<String, dynamic>)];
  }

  Future<void> savePayTerms(
    String userId, {
    required int salary,
    required CommissionType type,
    required int value,
  }) async {
    await sendRequest(
      () => _dio.put<Map<String, dynamic>>(
        '/employees/$userId/pay-terms',
        data: {'monthly_salary': salary, 'commission_type': type.apiValue, 'commission_value': value},
      ),
    );
  }

  Future<AttendanceRecord?> myAttendance() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/attendance/me'));
    final data = response.data!['data'];
    return data == null ? null : AttendanceRecord.fromJson(data as Map<String, dynamic>);
  }

  Future<void> clockIn(String branchId) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/attendance/clock-in', data: {'branch_id': branchId}));
  }

  Future<void> clockOut() async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/attendance/clock-out'));
  }

  Future<AttendanceSummary> attendanceSummary(String branchId, String from, String to) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/attendance/summary',
        queryParameters: {'branch_id': branchId, 'from': from, 'to': to},
      ),
    );
    return AttendanceSummary.fromJson(unwrapData(response));
  }

  Future<List<AttendanceRecord>> attendance(String branchId, String date) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/attendance', queryParameters: {'branch_id': branchId, 'date': date}),
    );
    return [for (final record in unwrapData<List>(response)) AttendanceRecord.fromJson(record as Map<String, dynamic>)];
  }

  Future<List<PayrollRun>> payrollRuns() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/payroll-runs'));
    return [for (final run in unwrapData<List>(response)) PayrollRun.fromJson(run as Map<String, dynamic>)];
  }

  /// Creates the month's draft, or recalculates it.
  Future<PayrollRun> calculatePayroll(int year, int month) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/payroll-runs', data: {'year': year, 'month': month}),
    );
    return PayrollRun.fromJson(unwrapData(response));
  }

  /// Cancels a month's payment recorded by mistake: its expense is removed and the month is a draft again.
  Future<void> cancelPayrollPayment(String runId) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/payroll-runs/$runId/cancel-payment'));
  }

  Future<void> payPayroll(String runId, Map<String, dynamic> data) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/payroll-runs/$runId/pay', data: data));
  }
}
