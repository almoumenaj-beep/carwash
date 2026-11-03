import 'package:carwash_app/features/inventory/domain/inventory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a material with its stock', () {
    final item = InventoryItem.fromJson({
      'id': 'i1',
      'name': 'Shampoo',
      'unit': 'L',
      'unit_cost': 1250,
      'min_stock': 2,
      'quantity': 1.5,
      'is_low': true,
      'is_active': true,
    });

    expect(item.quantity, 1.5);
    expect(item.minStock, 2.0);
    expect(item.isLow, isTrue);
  });

  test('reads a stock movement', () {
    final movement = StockMovement.fromJson({
      'id': 'm1',
      'branch_id': 'b1',
      'item': {'id': 'i1', 'name': 'Shampoo', 'unit': 'L'},
      'reason': 'consumption',
      'change': -0.25,
      'balance': 9.75,
      'order_id': 'o1',
      'purchase_id': null,
      'note': null,
      'by': 'Ali',
      'at': '2026-11-03T09:00:00+00:00',
    });

    expect(movement.reason, StockMovementReason.consumption);
    expect(movement.change, -0.25);
    expect(movement.balance, 9.75);
  });

  test('typed quantities accept Arabic digits and up to three decimals', () {
    expect(parseQuantity('2.5'), 2.5);
    expect(parseQuantity('٠٫٢٥'), 0.25);
    expect(parseQuantity('3'), 3.0);
    expect(parseQuantity('1.2345'), isNull);
    expect(parseQuantity('-1'), isNull);
    expect(parseQuantity(''), isNull);
  });

  test('quantities are shown without trailing zeros', () {
    expect(formatQuantity(2), '2');
    expect(formatQuantity(0.25), '0.25');
    expect(formatQuantity(100.5), '100.5');
    expect(formatQuantity(-8.5), '-8.5');
  });
}
