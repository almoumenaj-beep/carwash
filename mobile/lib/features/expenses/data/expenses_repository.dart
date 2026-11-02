import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/expense.dart';

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) => ExpensesRepository(ref.watch(dioProvider)));

/// Expenses of a branch (null: every branch) in a period, or every owed one when [unpaid]; with their total.
final expensesProvider = FutureProvider.autoDispose
    .family<({List<Expense> expenses, int total}), ({String? branchId, String? from, String? to, bool unpaid})>(
      (ref, query) => ref.watch(expensesRepositoryProvider).list(query),
    );

final expenseCategoriesProvider = FutureProvider.autoDispose<List<ExpenseCategory>>(
  (ref) => ref.watch(expensesRepositoryProvider).categories(),
);

final suppliersProvider = FutureProvider.autoDispose<List<Supplier>>(
  (ref) => ref.watch(expensesRepositoryProvider).suppliers(),
);

final recurringExpensesProvider = FutureProvider.autoDispose<List<RecurringExpense>>(
  (ref) => ref.watch(expensesRepositoryProvider).recurring(),
);

class ExpensesRepository {
  ExpensesRepository(this._dio);

  final Dio _dio;

  Future<({List<Expense> expenses, int total})> list(
    ({String? branchId, String? from, String? to, bool unpaid}) query,
  ) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: {
          'branch_id': ?query.branchId,
          'from': ?query.from,
          'to': ?query.to,
          if (query.unpaid) 'status': 'unpaid',
        },
      ),
    );
    return (
      expenses: [for (final expense in unwrapData<List>(response)) Expense.fromJson(expense as Map<String, dynamic>)],
      total: response.data!['total'] as int,
    );
  }

  Future<Expense> record(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/expenses', data: data));
    return Expense.fromJson(unwrapData(response));
  }

  Future<void> pay(String id, ExpensePaymentMethod method) async {
    await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/expenses/$id/pay', data: {'payment_method': method.apiValue}),
    );
  }

  Future<void> delete(String id) async {
    await sendRequest(() => _dio.delete<void>('/expenses/$id'));
  }

  Future<List<ExpenseCategory>> categories() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/expense-categories'));
    return [
      for (final category in unwrapData<List>(response)) ExpenseCategory.fromJson(category as Map<String, dynamic>),
    ];
  }

  Future<void> saveCategory(String? id, Map<String, dynamic> data) async {
    await sendRequest(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('/expense-categories', data: data)
          : _dio.patch<Map<String, dynamic>>('/expense-categories/$id', data: data),
    );
  }

  Future<void> deleteCategory(String id) async {
    await sendRequest(() => _dio.delete<void>('/expense-categories/$id'));
  }

  Future<List<Supplier>> suppliers() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/suppliers'));
    return [for (final supplier in unwrapData<List>(response)) Supplier.fromJson(supplier as Map<String, dynamic>)];
  }

  Future<void> saveSupplier(String? id, Map<String, dynamic> data) async {
    await sendRequest(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('/suppliers', data: data)
          : _dio.patch<Map<String, dynamic>>('/suppliers/$id', data: data),
    );
  }

  Future<List<RecurringExpense>> recurring() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/recurring-expenses'));
    return [
      for (final schedule in unwrapData<List>(response)) RecurringExpense.fromJson(schedule as Map<String, dynamic>),
    ];
  }

  Future<void> saveRecurring(String? id, Map<String, dynamic> data) async {
    await sendRequest(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('/recurring-expenses', data: data)
          : _dio.patch<Map<String, dynamic>>('/recurring-expenses/$id', data: data),
    );
  }

  Future<void> deleteRecurring(String id) async {
    await sendRequest(() => _dio.delete<void>('/recurring-expenses/$id'));
  }
}
