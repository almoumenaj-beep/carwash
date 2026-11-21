import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/staff_affairs.dart';

final staffAffairsRepositoryProvider = Provider<StaffAffairsRepository>(
  (ref) => StaffAffairsRepository(ref.watch(dioProvider)),
);

final employeesProvider = FutureProvider.autoDispose<List<Employee>>(
  (ref) => ref.watch(staffAffairsRepositoryProvider).employees(),
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
    required SalaryType salaryType,
    required CommissionType type,
    required int value,
  }) async {
    await sendRequest(
      () => _dio.put<Map<String, dynamic>>(
        '/employees/$userId/pay-terms',
        data: {
          'monthly_salary': salary,
          'salary_type': salaryType.apiValue,
          'commission_type': type.apiValue,
          'commission_value': value,
        },
      ),
    );
  }

  /// Pays a daily wage: records it as a wages expense linked to the employee.
  Future<void> recordDailyWage(String userId, {required int amount, required String branchId, required String paymentMethod}) async {
    await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/employees/$userId/daily-wages',
        data: {'amount': amount, 'branch_id': branchId, 'payment_method': paymentMethod},
      ),
    );
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
