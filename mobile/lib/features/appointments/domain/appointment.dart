/// Where a booking stands; while booked it can still be changed, checked in, cancelled or marked a no-show.
enum AppointmentStatus {
  booked('booked'),
  checkedIn('checked_in'),
  cancelled('cancelled'),
  noShow('no_show');

  const AppointmentStatus(this.apiValue);

  final String apiValue;

  static AppointmentStatus fromApi(String value) => values.firstWhere((status) => status.apiValue == value);
}

/// A car booked to come in at a branch.
class Appointment {
  const Appointment({
    required this.id,
    required this.branchId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleId,
    required this.plateNumber,
    required this.vehicleSizeId,
    required this.vehicleSizeName,
    required this.items,
    required this.estimatedTotal,
    required this.notes,
    required this.cancelReason,
    required this.orderId,
    required this.orderNumber,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final size = json['vehicle_size'] as Map<String, dynamic>?;
    final order = json['order'] as Map<String, dynamic>?;

    return Appointment(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      status: AppointmentStatus.fromApi(json['status'] as String),
      customerId: customer?['id'] as String?,
      customerName: (json['customer_name'] as String?) ?? customer?['name'] as String?,
      customerPhone: (json['customer_phone'] as String?) ?? customer?['phone'] as String?,
      vehicleId: json['vehicle_id'] as String?,
      plateNumber: json['plate_number'] as String?,
      vehicleSizeId: size?['id'] as String?,
      vehicleSizeName: size?['name'] as String?,
      items: [
        for (final item in json['items'] as List)
          (
            serviceId: (item as Map<String, dynamic>)['service_id'] as String,
            name: item['name'] as String,
            quantity: item['quantity'] as int,
          ),
      ],
      estimatedTotal: json['estimated_total'] as int,
      notes: json['notes'] as String?,
      cancelReason: json['cancel_reason'] as String?,
      orderId: order?['id'] as String?,
      orderNumber: order?['number'] as int?,
    );
  }

  final String id;
  final String branchId;
  final DateTime startsAt;
  final DateTime endsAt;
  final AppointmentStatus status;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;

  /// Set when a registered car was booked.
  final String? vehicleId;
  final String? plateNumber;
  final String? vehicleSizeId;
  final String? vehicleSizeName;
  final List<({String serviceId, String name, int quantity})> items;

  /// What the services came to when booked, in minor units.
  final int estimatedTotal;
  final String? notes;
  final String? cancelReason;

  /// The order opened when the car was checked in.
  final String? orderId;
  final int? orderNumber;

  /// Still waiting for the car.
  bool get isOpen => status == AppointmentStatus.booked;

  /// Still waiting for the car after its time.
  bool isLateAt(DateTime now) => isOpen && startsAt.isBefore(now);

  /// The visit's length in minutes.
  int get minutes => endsAt.difference(startsAt).inMinutes;
}

/// A start time that can still be booked: `startsAt` is local `YYYY-MM-DDTHH:MM`, [free] the places left.
typedef AppointmentSlot = ({String startsAt, String time, int free});
