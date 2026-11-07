/// A membership the owner offers. [washes] null means no limit; [forOneCar] ties it to one of the customer's cars.
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.washes,
    required this.validityDays,
    required this.forOneCar,
    required this.serviceIds,
    required this.isActive,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    price: json['price'] as int,
    washes: json['washes'] as int?,
    validityDays: json['validity_days'] as int,
    forOneCar: json['scope'] == 'vehicle',
    serviceIds: [for (final id in json['service_ids'] as List) id as String],
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String name;

  /// Minor units.
  final int price;
  final int? washes;
  final int validityDays;
  final bool forOneCar;
  final List<String> serviceIds;
  final bool isActive;
}

/// A membership a customer bought, with its own copy of the terms.
class CustomerMembership {
  const CustomerMembership({
    required this.id,
    required this.name,
    required this.washesLeft,
    required this.serviceIds,
    required this.vehicleId,
    required this.plateNumber,
    required this.expiresAt,
    required this.isUsable,
    required this.isCancelled,
  });

  factory CustomerMembership.fromJson(Map<String, dynamic> json) {
    final vehicle = json['vehicle'] as Map<String, dynamic>?;

    return CustomerMembership(
      id: json['id'] as String,
      name: json['name'] as String,
      washesLeft: json['washes_left'] as int?,
      serviceIds: [for (final id in json['service_ids'] as List) id as String],
      vehicleId: vehicle?['id'] as String?,
      plateNumber: vehicle?['plate_number'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsable: json['is_usable'] as bool,
      isCancelled: json['is_cancelled'] as bool,
    );
  }

  final String id;
  final String name;

  /// Null when there is no limit.
  final int? washesLeft;
  final List<String> serviceIds;
  final String? vehicleId;
  final String? plateNumber;
  final DateTime expiresAt;
  final bool isUsable;
  final bool isCancelled;
}
