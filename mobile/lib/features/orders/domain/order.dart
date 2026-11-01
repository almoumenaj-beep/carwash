/// Where a car is in the wash; mirrors the server's status machine.
enum OrderStatus {
  waiting('waiting'),
  inProgress('in_progress'),
  qualityCheck('qc'),
  ready('ready'),
  delivered('delivered'),
  cancelled('cancelled');

  const OrderStatus(this.apiValue);

  final String apiValue;

  static OrderStatus fromApi(String value) => values.firstWhere((status) => status.apiValue == value);

  /// Still in the wash (shown on the queue).
  bool get isActive => this != delivered && this != cancelled;

  /// Being washed: in a bay, either washing or in quality check.
  bool get isWashing => this == inProgress || this == qualityCheck;

  /// Whether moving to [next] is a step forward, as opposed to sending the car back or cancelling.
  bool isForwardTo(OrderStatus next) => next != cancelled && next.index > index;
}

/// Something referred to by id and name (a bay, a staff member).
class NamedRef {
  const NamedRef({required this.id, required this.name});

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      NamedRef(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;
}

class OrderCustomer {
  const OrderCustomer({required this.id, required this.name, required this.phone});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) =>
      OrderCustomer(id: json['id'] as String, name: json['name'] as String?, phone: json['phone'] as String);

  final String id;
  final String? name;
  final String phone;
}

/// A service on an order, priced when the car was checked in.
class OrderItem {
  const OrderItem({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.isAddon,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    serviceId: json['service_id'] as String,
    name: json['name'] as String,
    isAddon: json['is_addon'] as bool,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as int,
    lineTotal: json['line_total'] as int,
  );

  final String id;
  final String serviceId;
  final String name;
  final bool isAddon;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

/// One inspection at the quality check: whether each service on the order was done properly.
class QualityCheck {
  const QualityCheck({required this.passed, required this.by, required this.at, required this.results});

  factory QualityCheck.fromJson(Map<String, dynamic> json) => QualityCheck(
    passed: json['passed'] as bool,
    by: json['by'] as String?,
    at: DateTime.parse(json['at'] as String),
    results: [
      for (final result in json['results'] as List)
        (name: (result as Map<String, dynamic>)['name'] as String, passed: result['passed'] as bool),
    ],
  );

  final bool passed;
  final String? by;
  final DateTime at;
  final List<({String name, bool passed})> results;
}

/// One step in an order's history.
class StatusChange {
  const StatusChange({required this.from, required this.to, required this.by, required this.reason, required this.at});

  factory StatusChange.fromJson(Map<String, dynamic> json) => StatusChange(
    from: json['from'] == null ? null : OrderStatus.fromApi(json['from'] as String),
    to: OrderStatus.fromApi(json['to'] as String),
    by: json['by'] as String?,
    reason: json['reason'] as String?,
    at: DateTime.parse(json['at'] as String),
  );

  final OrderStatus? from;
  final OrderStatus to;
  final String? by;
  final String? reason;
  final DateTime at;
}

/// A car checked in for washing. Amounts are in minor units (BHD: fils).
class Order {
  const Order({
    required this.id,
    required this.reference,
    required this.branchId,
    required this.status,
    required this.allowedNext,
    required this.customer,
    required this.plateNumber,
    required this.bay,
    required this.staff,
    required this.items,
    required this.subtotal,
    required this.estimatedMinutes,
    required this.notes,
    required this.cancelReason,
    required this.createdBy,
    required this.createdAt,
    required this.startedAt,
    this.qcAt,
    required this.readyAt,
    required this.history,
    this.qualityChecks = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) => json[key] == null ? null : DateTime.parse(json[key] as String);

    return Order(
      id: json['id'] as String,
      reference: json['reference'] as String,
      branchId: json['branch_id'] as String,
      status: OrderStatus.fromApi(json['status'] as String),
      allowedNext: [for (final status in json['allowed_next'] as List) OrderStatus.fromApi(status as String)],
      customer: json['customer'] == null ? null : OrderCustomer.fromJson(json['customer'] as Map<String, dynamic>),
      plateNumber: json['plate_number'] as String,
      bay: json['bay'] == null ? null : NamedRef.fromJson(json['bay'] as Map<String, dynamic>),
      staff: [for (final member in json['staff'] as List) NamedRef.fromJson(member as Map<String, dynamic>)],
      items: [for (final item in json['items'] as List) OrderItem.fromJson(item as Map<String, dynamic>)],
      subtotal: json['subtotal'] as int,
      estimatedMinutes: json['estimated_minutes'] as int,
      notes: json['notes'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      createdBy: NamedRef.fromJson(json['created_by'] as Map<String, dynamic>),
      createdAt: time('created_at')!,
      startedAt: time('started_at'),
      qcAt: time('qc_at'),
      readyAt: time('ready_at'),
      history: [
        for (final change in (json['history'] as List?) ?? const [])
          StatusChange.fromJson(change as Map<String, dynamic>),
      ],
      qualityChecks: [
        for (final check in (json['quality_checks'] as List?) ?? const [])
          QualityCheck.fromJson(check as Map<String, dynamic>),
      ],
    );
  }

  final String id;

  /// Branch code and number, e.g. "MAIN-12".
  final String reference;
  final String branchId;
  final OrderStatus status;

  /// The statuses the server allows next, in its order (forward steps first).
  final List<OrderStatus> allowedNext;

  /// Null for a walk-in who is not registered.
  final OrderCustomer? customer;
  final String plateNumber;
  final NamedRef? bay;
  final List<NamedRef> staff;
  final List<OrderItem> items;
  final int subtotal;
  final int estimatedMinutes;
  final String? notes;
  final String? cancelReason;
  final NamedRef createdBy;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? qcAt;
  final DateTime? readyAt;

  /// Only filled on the order's own page.
  final List<StatusChange> history;

  /// Inspections at the quality check, oldest first; only filled on the order's own page.
  final List<QualityCheck> qualityChecks;

  /// The next step forward, which the queue offers as its main button.
  OrderStatus? get nextStep => allowedNext.where(status.isForwardTo).firstOrNull;

  /// When the current stage began: check-in while waiting, the start of washing, the start of the quality check,
  /// or when it became ready.
  DateTime get stageStartedAt => switch (status) {
    OrderStatus.waiting => createdAt,
    OrderStatus.inProgress => startedAt ?? createdAt,
    OrderStatus.qualityCheck => qcAt ?? startedAt ?? createdAt,
    _ => readyAt ?? createdAt,
  };

  /// "Exterior wash + Air freshener".
  String get servicesSummary => items.map((item) => item.name).join(' + ');
}
