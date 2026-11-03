import 'package:carwash_app/features/reports/domain/financial_reports.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a profit and loss with a loss', () {
    final report = ProfitAndLoss.fromJson({
      'from': '2026-11-01',
      'to': '2026-11-15',
      'revenue': {'invoices_count': 2, 'gross': 4500, 'discounts': 250, 'sales': 4250, 'vat': 387, 'net_sales': 3863},
      'expenses': {
        'total': 13000,
        'owed': 3000,
        'by_category': [
          {'id': 'c1', 'name': 'Rent', 'amount': 10000},
        ],
      },
      'profit': -9137,
      'margin_bps': -23652,
      'by_branch': [
        {'id': 'b1', 'name': 'Main', 'net_sales': 3863, 'expenses': 13000, 'profit': -9137},
      ],
      'by_service': [
        {'service_id': 's1', 'name': 'Wash', 'quantity': 2, 'net_revenue': 3454, 'materials': 100, 'profit': 3354},
      ],
      'by_washer': [
        {'id': 'u1', 'name': 'Mahmood', 'cars': 2, 'net_revenue': 3863, 'pay': 0},
      ],
    });

    expect(report.netSales, 3863);
    expect(report.profit, -9137);
    expect(report.expensesByCategory.single.name, 'Rent');
    expect(report.byService.single.materials, 100);
    expect(report.byWasher.single.cars, 2);
    expect(report.isEmpty, isFalse);
  });

  test('reads a cash flow by method and day', () {
    final report = CashFlow.fromJson({
      'inflow': {
        'total': 4250,
        'by_method': [
          {'method': 'cash', 'amount': 4250},
        ],
      },
      'outflow': {
        'total': 20000,
        'by_method': [
          {'method': 'cash_drawer', 'amount': 20000},
        ],
      },
      'net': -15750,
      'owed': {'total': 3000, 'count': 1},
      'by_day': [
        {'date': '2026-11-15', 'inflow': 4250, 'outflow': 20000},
      ],
    });

    expect(report.inflowByMethod.single.name, 'cash');
    expect(report.net, -15750);
    expect(report.owedCount, 1);
    expect(report.byDay.single.date, DateTime(2026, 11, 15));
  });
}
