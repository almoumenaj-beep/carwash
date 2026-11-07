/// Whether a piece of equipment can be used; retired equipment keeps its history but is never due.
enum EquipmentStatus {
  inService('in_service'),
  outOfService('out_of_service'),
  retired('retired');

  const EquipmentStatus(this.apiValue);

  final String apiValue;

  static EquipmentStatus fromApi(String value) => values.firstWhere((status) => status.apiValue == value);
}

/// Periodic maintenance restarts the schedule; a repair puts broken equipment back in service.
enum MaintenanceKind {
  periodic('periodic'),
  repair('repair');

  const MaintenanceKind(this.apiValue);

  final String apiValue;

  static MaintenanceKind fromApi(String value) => values.firstWhere((kind) => kind.apiValue == value);
}

/// A report that a piece of equipment broke, and why.
class Breakdown {
  const Breakdown({required this.reason, required this.reportedAt, required this.reportedBy});

  factory Breakdown.fromJson(Map<String, dynamic> json) => Breakdown(
    reason: json['reason'] as String,
    reportedAt: DateTime.parse(json['reported_at'] as String),
    reportedBy: (json['reported_by'] as Map<String, dynamic>)['name'] as String,
  );

  final String reason;
  final DateTime reportedAt;
  final String reportedBy;
}

/// A machine or tool at a branch with its periodic maintenance schedule.
class Equipment {
  const Equipment({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.name,
    required this.serialNumber,
    required this.purchasedOn,
    required this.purchaseCost,
    required this.status,
    required this.maintenanceIntervalDays,
    required this.lastMaintainedOn,
    required this.nextMaintenanceOn,
    required this.daysUntilMaintenance,
    required this.isDue,
    required this.notes,
    this.breakdownReason,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null ? null : DateTime.parse(json[key] as String);
    final branch = json['branch'] as Map<String, dynamic>;

    return Equipment(
      id: json['id'] as String,
      branchId: branch['id'] as String,
      branchName: branch['name'] as String,
      name: json['name'] as String,
      serialNumber: json['serial_number'] as String?,
      purchasedOn: date('purchased_on'),
      purchaseCost: json['purchase_cost'] as int?,
      status: EquipmentStatus.fromApi(json['status'] as String),
      maintenanceIntervalDays: json['maintenance_interval_days'] as int?,
      lastMaintainedOn: date('last_maintained_on'),
      nextMaintenanceOn: date('next_maintenance_on'),
      daysUntilMaintenance: json['days_until_maintenance'] as int?,
      isDue: json['is_due'] as bool,
      notes: json['notes'] as String?,
      breakdownReason: json['breakdown_reason'] as String?,
    );
  }

  final String id;
  final String branchId;
  final String branchName;
  final String name;
  final String? serialNumber;
  final DateTime? purchasedOn;

  /// Minor units.
  final int? purchaseCost;
  final EquipmentStatus status;

  /// Null when it has no periodic maintenance.
  final int? maintenanceIntervalDays;
  final DateTime? lastMaintainedOn;
  final DateTime? nextMaintenanceOn;

  /// Negative once overdue; null when nothing is scheduled.
  final int? daysUntilMaintenance;
  final bool isDue;
  final String? notes;

  /// Why it broke, while it is out of service.
  final String? breakdownReason;
}

/// Maintenance done on a piece of equipment.
class Maintenance {
  const Maintenance({
    required this.id,
    required this.kind,
    required this.performedOn,
    required this.description,
    required this.cost,
    required this.supplierName,
    required this.isPaid,
    required this.createdBy,
    this.isCancelled = false,
    this.cancelledBy,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) => Maintenance(
    id: json['id'] as String,
    kind: MaintenanceKind.fromApi(json['kind'] as String),
    performedOn: DateTime.parse(json['performed_on'] as String),
    description: json['description'] as String?,
    cost: json['cost'] as int,
    supplierName: (json['supplier'] as Map<String, dynamic>?)?['name'] as String?,
    isPaid: json['is_paid'] as bool,
    createdBy: (json['created_by'] as Map<String, dynamic>)['name'] as String,
    isCancelled: json['is_cancelled'] as bool? ?? false,
    cancelledBy: json['cancelled_by'] as String?,
  );

  final String id;
  final MaintenanceKind kind;
  final DateTime performedOn;
  final String? description;

  /// Minor units; 0 when it cost nothing.
  final int cost;
  final String? supplierName;
  final bool isPaid;
  final String createdBy;

  /// Recorded by mistake: its expense was removed and it no longer counts.
  final bool isCancelled;
  final String? cancelledBy;
}
