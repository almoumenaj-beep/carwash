import 'package:carwash_app/features/shifts/domain/cash_shift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads an open shift with its live till summary', () {
    final shift = CashShift.fromJson({
      'id': 's1',
      'branch_id': 'b1',
      'is_open': true,
      'opened_by': {'id': 'u1', 'name': 'Sara'},
      'opened_at': '2026-11-01T06:00:00+00:00',
      'opening_float': 10000,
      'invoices_count': 2,
      'discounts_total': 250,
      'vat_total': 409,
      'cash_taken': 4500,
      'expected_cash': 14500,
      'counted_cash': null,
      'variance': null,
      'close_note': null,
      'closed_by': null,
      'closed_at': null,
    });

    expect(shift.isOpen, isTrue);
    expect(shift.openedBy.name, 'Sara');
    expect(shift.expectedCash, 14500);
    expect(shift.variance, isNull);
    expect(shift.closedAt, isNull);
  });

  test('reads a closed shift with the drawer counted', () {
    final shift = CashShift.fromJson({
      'id': 's1',
      'branch_id': 'b1',
      'is_open': false,
      'opened_by': {'id': 'u1', 'name': 'Sara'},
      'opened_at': '2026-11-01T06:00:00+00:00',
      'opening_float': 10000,
      'invoices_count': 2,
      'discounts_total': 0,
      'vat_total': 409,
      'cash_taken': 4500,
      'expected_cash': 14500,
      'counted_cash': 14000,
      'variance': -500,
      'close_note': 'Too much change',
      'closed_by': {'id': 'u1', 'name': 'Sara'},
      'closed_at': '2026-11-01T14:00:00+00:00',
    });

    expect(shift.isOpen, isFalse);
    expect(shift.variance, -500);
    expect(shift.closeNote, 'Too much change');
  });
}
