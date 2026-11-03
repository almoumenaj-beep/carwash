import 'package:carwash_app/features/expenses/domain/expense.dart';
import 'package:carwash_app/features/staff_affairs/domain/staff_affairs.dart';
import 'package:carwash_app/features/staff_affairs/presentation/staff_affairs_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads an employee with pay terms, advances and attendance', () {
    final employee = Employee.fromJson({
      'id': 'u1',
      'name': 'Mahmood',
      'roles': ['Washer'],
      'monthly_salary': 150000,
      'commission_type': 'per_car',
      'commission_value': 500,
      'outstanding_advances': 20000,
      'clocked_in_at': '2026-11-03T08:00:00+03:00',
    });

    expect(employee.commissionType, CommissionType.perCar);
    expect(employee.commissionValue, 500);
    expect(employee.outstandingAdvances, 20000);
    expect(employee.clockedInAt, isNotNull);
  });

  test('reads a payroll run with its lines', () {
    final run = PayrollRun.fromJson({
      'id': 'r1',
      'year': 2026,
      'month': 10,
      'status': 'draft',
      'total_net': 135000,
      'paid_at': null,
      'lines': [
        {
          'user': {'id': 'u1', 'name': 'Mahmood'},
          'base_salary': 150000,
          'cars_count': 10,
          'commission': 5000,
          'advances': 20000,
          'net': 135000,
        },
      ],
    });

    expect(run.isPaid, isFalse);
    expect(run.lines.single.name, 'Mahmood');
    expect(run.lines.single.net, 135000);
  });

  test('records wages under the wages category when there is one', () {
    const rent = ExpenseCategory(id: 'c1', name: 'إيجار', isActive: true);
    const wages = ExpenseCategory(id: 'c2', name: 'رواتب وأجور', isActive: true);
    const oldWages = ExpenseCategory(id: 'c3', name: 'Wages', isActive: false);

    expect(wagesCategory([rent, wages])?.id, 'c2');
    expect(wagesCategory([rent, oldWages])?.id, 'c1');
    expect(wagesCategory([]), isNull);
  });
}
