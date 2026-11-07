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
  const OrderCustomer({required this.id, required this.name, required this.phone, this.pointsBalance = 0});

  factory OrderCustomer.fromJson(Map<String, dynamic> json) => OrderCustomer(
    id: json['id'] as String,
    name: json['name'] as String?,
    phone: json['phone'] as String,
    pointsBalance: json['points_balance'] as int? ?? 0,
  );

  final String id;
  final String? name;
  final String phone;
  final int pointsBalance;
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
    this.isPackage = false,
    this.components = const [],
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    serviceId: json['service_id'] as String,
    name: json['name'] as String,
    isAddon: json['is_addon'] as bool,
    quantity: json['quantity'] as int,
    unitPrice: json['unit_price'] as int,
    lineTotal: json['line_total'] as int,
    isPackage: json['is_package'] as bool? ?? false,
    components: [
      for (final component in (json['components'] as List?) ?? const [])
        NamedRef.fromJson(component as Map<String, dynamic>),
    ],
  );

  final String id;
  final String serviceId;
  final String name;
  final bool isAddon;
  final int quantity;
  final int unitPrice;
  final int lineTotal;

  final bool isPackage;

  /// The services a package includes (unpriced order items of their own, inspected one by one).
  final List<NamedRef> components;
}

/// The invoice of a paid order, with the cash received.
class OrderInvoice {
  const OrderInvoice({
    this.id = '',
    required this.reference,
    required this.subtotal,
    required this.discountTotal,
    required this.discountReason,
    required this.total,
    required this.vatRateBps,
    required this.vatAmount,
    required this.tendered,
    required this.changeGiven,
    this.paymentMethod = 'cash',
    this.pointsEarned = 0,
  });

  factory OrderInvoice.fromJson(Map<String, dynamic> json) {
    final payments = [for (final payment in json['payments'] as List) payment as Map<String, dynamic>];

    return OrderInvoice(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String,
      subtotal: json['subtotal'] as int,
      discountTotal: json['discount_total'] as int,
      discountReason: json['discount_reason'] as String?,
      total: json['total'] as int,
      vatRateBps: json['vat_rate_bps'] as int,
      vatAmount: json['vat_amount'] as int,
      tendered: payments.fold(0, (sum, payment) => sum + ((payment['tendered'] as int?) ?? (payment['amount'] as int))),
      changeGiven: payments.fold(0, (sum, payment) => sum + (payment['change_given'] as int)),
      paymentMethod: payments.isEmpty ? 'cash' : payments.first['method'] as String? ?? 'cash',
      pointsEarned: json['points_earned'] as int? ?? 0,
    );
  }

  final String id;

  /// E.g. "MAIN-INV-12".
  final String reference;
  final int subtotal;
  final int discountTotal;
  final String? discountReason;
  final int total;
  final int vatRateBps;
  final int vatAmount;
  final int tendered;
  final int changeGiven;

  /// How the invoice was paid (`cash`, `card` or `benefit`).
  final String paymentMethod;
  final int pointsEarned;
}

/// Money given back for an invoice of this order.
class OrderRefund {
  const OrderRefund({required this.reference, required this.amount, required this.reason, required this.refundedAt});

  factory OrderRefund.fromJson(Map<String, dynamic> json) => OrderRefund(
    reference: json['reference'] as String,
    amount: json['amount'] as int,
    reason: json['reason'] as String,
    refundedAt: DateTime.parse(json['refunded_at'] as String),
  );

  final String reference;
  final int amount;
  final String reason;
  final DateTime refundedAt;
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
    this.vehicleId,
    this.refunds = const [],
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
    this.invoice,
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
      vehicleId: json['vehicle_id'] as String?,
      refunds: [
        for (final refund in (json['refunds'] as List?) ?? const [])
          OrderRefund.fromJson(refund as Map<String, dynamic>),
      ],
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
      invoice: json['invoice'] == null ? null : OrderInvoice.fromJson(json['invoice'] as Map<String, dynamic>),
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
  final String? vehicleId;
  final List<OrderRefund> refunds;
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

  /// Set once the order is paid; a car is only handed over after that.
  final OrderInvoice? invoice;

  bool get isPaid => invoice != null;

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

  /// What the quality check goes through: every service, a package's services one by one.
  List<NamedRef> get inspectionPoints => [
    for (final item in items)
      if (item.isPackage) ...item.components else NamedRef(id: item.id, name: item.name),
  ];
}
