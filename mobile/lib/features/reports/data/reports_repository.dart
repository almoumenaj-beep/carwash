import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/daily_sales.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) => ReportsRepository(ref.watch(dioProvider)));

/// A day's sales; a null branch means every branch the user works in, a null date today.
final dailySalesProvider = FutureProvider.autoDispose.family<DailySales, ({String? branchId, String? date})>(
  (ref, query) => ref.watch(reportsRepositoryProvider).dailySales(branchId: query.branchId, date: query.date),
);

class ReportsRepository {
  ReportsRepository(this._dio);

  final Dio _dio;

  /// [date] as `YYYY-MM-DD` in the car wash's time zone.
  Future<DailySales> dailySales({String? branchId, String? date}) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/reports/daily-sales',
        queryParameters: {'branch_id': ?branchId, 'date': ?date},
      ),
    );
    return DailySales.fromJson(unwrapData(response));
  }
}
