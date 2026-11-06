/// A material kept in stock, with what the selected branch (or all of the user's branches) holds.
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitCost,
    required this.minStock,
    required this.quantity,
    required this.isLow,
    required this.isActive,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    unit: json['unit'] as String,
    unitCost: json['unit_cost'] as int,
    minStock: (json['min_stock'] as num).toDouble(),
    quantity: (json['quantity'] as num).toDouble(),
    isLow: json['is_low'] as bool,
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String name;

  /// E.g. "L", "kg", "pc".
  final String unit;

  /// The last purchase price per unit, in minor units.
  final int unitCost;
  final double minStock;
  final double quantity;

  /// At or below [minStock].
  final bool isLow;
  final bool isActive;
}

/// Why a branch's stock changed.
enum StockMovementReason {
  purchase,
  consumption,
  count,
  issue,
  reversal,
  cancellation;

  static StockMovementReason fromApi(String value) => values.firstWhere((reason) => reason.name == value);
}

/// One change to a branch's stock, with the balance after it.
class StockMovement {
  const StockMovement({
    required this.itemName,
    required this.unit,
    required this.reason,
    required this.change,
    required this.balance,
    required this.note,
    required this.by,
    required this.receivedBy,
    required this.at,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>;
    return StockMovement(
      itemName: item['name'] as String,
      unit: item['unit'] as String,
      reason: StockMovementReason.fromApi(json['reason'] as String),
      change: (json['change'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      note: json['note'] as String?,
      by: json['by'] as String?,
      receivedBy: json['received_by'] as String?,
      at: DateTime.parse(json['at'] as String),
    );
  }

  final String itemName;
  final String unit;
  final StockMovementReason reason;
  final double change;
  final double balance;
  final String? note;
  final String? by;

  /// Who received materials issued by hand.
  final String? receivedBy;
  final DateTime at;
}

/// Materials bought and received at a branch.
class Purchase {
  const Purchase({
    required this.id,
    required this.supplierName,
    required this.purchasedOn,
    required this.total,
    required this.isPaid,
    required this.lines,
    this.isCancelled = false,
    this.cancelledBy,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'] as String,
    supplierName: (json['supplier'] as Map<String, dynamic>?)?['name'] as String?,
    purchasedOn: DateTime.parse(json['purchased_on'] as String),
    total: json['total'] as int,
    isPaid: json['is_paid'] as bool,
    isCancelled: json['is_cancelled'] as bool? ?? false,
    cancelledBy: json['cancelled_by'] as String?,
    lines: [
      for (final line in json['lines'] as List)
        (
          name: ((line as Map<String, dynamic>)['item'] as Map<String, dynamic>)['name'] as String,
          unit: (line['item'] as Map<String, dynamic>)['unit'] as String,
          quantity: (line['quantity'] as num).toDouble(),
          unitCost: line['unit_cost'] as int,
          lineTotal: line['line_total'] as int,
        ),
    ],
  );

  final String id;
  final String? supplierName;
  final DateTime purchasedOn;
  final int total;

  /// False while it is owed to the supplier.
  final bool isPaid;

  /// Recorded by mistake: its quantities and expense were taken back.
  final bool isCancelled;
  final String? cancelledBy;
  final List<({String name, String unit, double quantity, int unitCost, int lineTotal})> lines;
}

/// What left a branch's stock on one day.
class DailyStockUsage {
  const DailyStockUsage({required this.totalCost, required this.items, required this.issues});

  factory DailyStockUsage.fromJson(Map<String, dynamic> json) => DailyStockUsage(
    totalCost: json['total_cost'] as int,
    items: [
      for (final row in json['items'] as List)
        (
          name: ((row as Map<String, dynamic>)['item'] as Map<String, dynamic>)['name'] as String,
          unit: (row['item'] as Map<String, dynamic>)['unit'] as String,
          washes: (row['washes'] as num).toDouble(),
          issued: (row['issued'] as num).toDouble(),
          total: (row['total'] as num).toDouble(),
          cost: row['cost'] as int,
        ),
    ],
    issues: [
      for (final row in json['issues'] as List)
        (
          id: (row as Map<String, dynamic>)['id'] as String,
          name: (row['item'] as Map<String, dynamic>)['name'] as String,
          unit: (row['item'] as Map<String, dynamic>)['unit'] as String,
          quantity: (row['quantity'] as num).toDouble(),
          isCancelled: row['is_cancelled'] as bool,
          cancelledBy: row['cancelled_by'] as String?,
          note: row['note'] as String?,
          by: row['by'] as String?,
          receivedBy: row['received_by'] as String?,
          at: DateTime.parse(row['at'] as String),
        ),
    ],
  );

  /// At today's material costs, in minor units.
  final int totalCost;

  /// Per material: what was issued to staff and anything washes used.
  final List<({String name, String unit, double washes, double issued, double total, int cost})> items;

  /// Each material issued to staff, latest first.
  final List<
    ({
      String id,
      String name,
      String unit,
      double quantity,
      bool isCancelled,
      String? cancelledBy,
      String? note,
      String? by,
      String? receivedBy,
      DateTime at,
    })
  >
  issues;
}

/// How much of a material one sale of a service uses.
class ServiceMaterial {
  const ServiceMaterial({required this.itemId, required this.name, required this.unit, required this.quantity});

  factory ServiceMaterial.fromJson(Map<String, dynamic> json) => ServiceMaterial(
    itemId: json['inventory_item_id'] as String,
    name: json['name'] as String,
    unit: json['unit'] as String,
    quantity: (json['quantity'] as num).toDouble(),
  );

  final String itemId;
  final String name;
  final String unit;
  final double quantity;
}

/// A typed quantity ("2.5", "٠٫٢٥") as a number with at most three decimals; null when it is not one.
double? parseQuantity(String input) {
  final normalised = input
      .trim()
      .replaceAll('٫', '.')
      .replaceAll(',', '.')
      .replaceAllMapped(RegExp('[٠-٩]'), (match) => '${match[0]!.codeUnitAt(0) - 0x0660}');
  if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(normalised)) {
    return null;
  }
  return double.parse(normalised);
}

/// A quantity without trailing zeros: 2.0 → "2", 0.25 → "0.25".
String formatQuantity(double quantity) {
  final text = quantity.toStringAsFixed(3);
  return text.contains('.') ? text.replaceFirst(RegExp(r'\.?0+$'), '') : text;
}
