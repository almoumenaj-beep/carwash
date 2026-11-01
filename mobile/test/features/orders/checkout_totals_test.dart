import 'package:carwash_app/features/orders/domain/checkout_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VAT is extracted from prices that include it, as on the server', () {
    final totals = CheckoutTotals.of(subtotal: 2500, vatRateBps: 1000, pricesIncludeVat: true);

    expect(totals.total, 2500);
    expect(totals.vat, 227);
  });

  test('VAT is added on top when prices exclude it', () {
    final totals = CheckoutTotals.of(subtotal: 2500, vatRateBps: 1000, pricesIncludeVat: false);

    expect(totals.vat, 250);
    expect(totals.total, 2750);
  });

  test('a discount comes off before VAT, as an amount or a percentage', () {
    final percent = CheckoutTotals.of(
      subtotal: 2500,
      discountPercentBps: 1000,
      vatRateBps: 1000,
      pricesIncludeVat: true,
    );
    expect(percent.discount, 250);
    expect(percent.total, 2250);
    expect(percent.vat, 205);
    expect(percent.discountBps, 1000);

    final amount = CheckoutTotals.of(subtotal: 2500, discountAmount: 300, vatRateBps: 1000, pricesIncludeVat: true);
    expect(amount.total, 2200);
    expect(amount.discountBps, 1200);
  });

  test('a discount never takes the total below zero', () {
    expect(CheckoutTotals.of(subtotal: 2500, discountAmount: 9000, vatRateBps: 1000, pricesIncludeVat: true).total, 0);
  });
}
