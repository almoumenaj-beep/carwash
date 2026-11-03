import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/daily_sales.dart';
import '../domain/financial_reports.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) => ReportsRepository(ref.watch(dioProvider)));

/// A day's sales; a null branch means every branch the user works in, a null date today.
final dailySalesProvider = FutureProvider.autoDispose.family<DailySales, ({String? branchId, String? date})>(
  (ref, query) => ref.watch(reportsRepositoryProvider).dailySales(branchId: query.branchId, date: query.date),
);

/// A period's figures; a null branch means every branch the user works in. Dates are `YYYY-MM-DD`.
typedef ReportPeriod = ({String? branchId, String from, String to});

final profitAndLossProvider = FutureProvider.autoDispose.family<ProfitAndLoss, ReportPeriod>(
  (ref, period) => ref.watch(reportsRepositoryProvider).profitAndLoss(period),
);

final cashFlowProvider = FutureProvider.autoDispose.family<CashFlow, ReportPeriod>(
  (ref, period) => ref.watch(reportsRepositoryProvider).cashFlow(period),
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

  Future<ProfitAndLoss> profitAndLoss(ReportPeriod period) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/reports/profit-loss', queryParameters: _query(period)),
    );
    return ProfitAndLoss.fromJson(unwrapData(response));
  }

  Future<CashFlow> cashFlow(ReportPeriod period) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/reports/cash-flow', queryParameters: _query(period)),
    );
    return CashFlow.fromJson(unwrapData(response));
  }

  Map<String, dynamic> _query(ReportPeriod period) => {
    'branch_id': ?period.branchId,
    'from': period.from,
    'to': period.to,
  };
}
