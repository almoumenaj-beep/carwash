/// A day's sales at one branch or all of them, from `/reports/daily-sales`. Amounts are in minor units.
class DailySales {
  const DailySales({
    required this.date,
    required this.invoicesCount,
    required this.gross,
    required this.discounts,
    required this.sales,
    required this.vat,
    required this.cashCollected,
    required this.averageTicket,
    required this.carsCheckedIn,
    required this.carsDelivered,
    required this.carsCancelled,
    required this.carsInQueue,
    required this.byService,
    required this.byCashier,
    required this.byWasher,
    required this.byHour,
  });

  factory DailySales.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>;
    final cars = json['cars'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) => [for (final row in json[key] as List) row as Map<String, dynamic>];

    return DailySales(
      date: DateTime.parse(json['date'] as String),
      invoicesCount: totals['invoices_count'] as int,
      gross: totals['gross'] as int,
      discounts: totals['discounts'] as int,
      sales: totals['sales'] as int,
      vat: totals['vat'] as int,
      cashCollected: totals['cash_collected'] as int,
      averageTicket: totals['average_ticket'] as int,
      carsCheckedIn: cars['checked_in'] as int,
      carsDelivered: cars['delivered'] as int,
      carsCancelled: cars['cancelled'] as int,
      carsInQueue: cars['in_queue'] as int,
      byService: [
        for (final row in rows('by_service'))
          (name: row['name'] as String, quantity: row['quantity'] as int, revenue: row['revenue'] as int),
      ],
      byCashier: [
        for (final row in rows('by_cashier'))
          (name: row['name'] as String, invoices: row['invoices'] as int, total: row['total'] as int),
      ],
      byWasher: [for (final row in rows('by_washer')) (name: row['name'] as String, cars: row['cars'] as int)],
      byHour: [
        for (final row in rows('by_hour'))
          (hour: row['hour'] as int, invoices: row['invoices'] as int, total: row['total'] as int),
      ],
    );
  }

  final DateTime date;
  final int invoicesCount;

  /// Services sold before discounts.
  final int gross;
  final int discounts;

  /// What customers paid (after discounts, VAT included or added per the settings).
  final int sales;
  final int vat;
  final int cashCollected;
  final int averageTicket;
  final int carsCheckedIn;
  final int carsDelivered;
  final int carsCancelled;
  final int carsInQueue;
  final List<({String name, int quantity, int revenue})> byService;
  final List<({String name, int invoices, int total})> byCashier;
  final List<({String name, int cars})> byWasher;

  /// Hours of the day (local time) that had sales.
  final List<({int hour, int invoices, int total})> byHour;

  bool get isEmpty => invoicesCount == 0 && carsCheckedIn == 0;
}
