/// What the customer pays at the till, worked out like the server (amounts in minor units, VAT rounded half up).
class CheckoutTotals {
  const CheckoutTotals({required this.subtotal, required this.discount, required this.vat, required this.total});

  /// [discountAmount] in minor units, or [discountPercentBps] (1000 = 10%) of [subtotal]; never more than it.
  /// Prices that include VAT have it extracted; otherwise it is added on top.
  factory CheckoutTotals.of({
    required int subtotal,
    int discountAmount = 0,
    int? discountPercentBps,
    required int vatRateBps,
    required bool pricesIncludeVat,
  }) {
    final requested = discountPercentBps == null
        ? discountAmount
        : (2 * subtotal * discountPercentBps + 10000) ~/ 20000;
    final discount = requested.clamp(0, subtotal);
    final amount = subtotal - discount;

    if (pricesIncludeVat) {
      final divisor = 10000 + vatRateBps;
      final vat = (2 * amount * vatRateBps + divisor) ~/ (2 * divisor);
      return CheckoutTotals(subtotal: subtotal, discount: discount, vat: vat, total: amount);
    }

    final vat = (2 * amount * vatRateBps + 10000) ~/ 20000;
    return CheckoutTotals(subtotal: subtotal, discount: discount, vat: vat, total: amount + vat);
  }

  final int subtotal;
  final int discount;
  final int vat;
  final int total;

  /// The discount as a share of [subtotal] in basis points, to compare with the cashier's limit.
  int get discountBps => subtotal == 0 ? 0 : (discount * 10000 + subtotal - 1) ~/ subtotal;
}
