import 'package:carwash_app/features/reports/domain/daily_sales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a day of sales with its breakdowns', () {
    final report = DailySales.fromJson({
      'branch_id': null,
      'date': '2026-11-02',
      'totals': {
        'invoices_count': 2,
        'gross': 4500,
        'discounts': 250,
        'sales': 4250,
        'vat': 387,
        'cash_collected': 4250,
        'average_ticket': 2125,
      },
      'cars': {'checked_in': 4, 'delivered': 0, 'cancelled': 1, 'in_queue': 3},
      'by_service': [
        {'name': 'Exterior wash', 'quantity': 2, 'revenue': 4000},
      ],
      'by_cashier': [
        {'id': 'u1', 'name': 'Sara', 'invoices': 2, 'total': 4250},
      ],
      'by_washer': [
        {'id': 'u2', 'name': 'Ali', 'cars': 3},
      ],
      'by_hour': [
        {'hour': 9, 'invoices': 2, 'total': 4250},
      ],
    });

    expect(report.date, DateTime(2026, 11, 2));
    expect(report.sales, 4250);
    expect(report.carsInQueue, 3);
    expect(report.byService.single.quantity, 2);
    expect(report.byCashier.single.name, 'Sara');
    expect(report.byWasher.single.cars, 3);
    expect(report.byHour.single.hour, 9);
    expect(report.isEmpty, isFalse);
  });
}
