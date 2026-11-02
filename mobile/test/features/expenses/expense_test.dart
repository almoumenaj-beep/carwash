import 'package:carwash_app/features/expenses/domain/expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> expenseJson({String? method = 'cash'}) => {
    'id': 'e1',
    'branch_id': 'b1',
    'category': {'id': 'c1', 'name': 'Rent'},
    'supplier': {'id': 's1', 'name': 'Landlord'},
    'amount': 450000,
    'spent_on': '2026-11-01',
    'description': 'Shop rent',
    'is_paid': method != null,
    'payment_method': method,
    'paid_at': null,
    'is_recurring': true,
    'created_by': {'id': 'u1', 'name': 'Owner'},
  };

  test('reads a paid expense', () {
    final expense = Expense.fromJson(expenseJson(method: 'cash_drawer'));

    expect(expense.isPaid, isTrue);
    expect(expense.paymentMethod, ExpensePaymentMethod.cashDrawer);
    expect(expense.category.name, 'Rent');
    expect(expense.supplier?.name, 'Landlord');
    expect(expense.isRecurring, isTrue);
  });

  test('an expense without a payment method is still owed', () {
    final expense = Expense.fromJson(expenseJson(method: null));

    expect(expense.isPaid, isFalse);
    expect(expense.paymentMethod, isNull);
  });

  test('reads a recurring expense and formats API dates', () {
    final schedule = RecurringExpense.fromJson({
      'id': 'r1',
      'branch_id': 'b1',
      'category': {'id': 'c1', 'name': 'Rent'},
      'supplier': null,
      'amount': 450000,
      'description': null,
      'frequency': 'monthly',
      'next_due_on': '2026-12-01',
      'is_active': true,
    });

    expect(schedule.frequency, RecurrenceFrequency.monthly);
    expect(schedule.nextDueOn, DateTime(2026, 12, 1));
    expect(apiDate(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
