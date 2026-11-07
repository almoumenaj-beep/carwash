/// A customer of the car wash, identified by phone number (stored as +97333334444).
class Customer {
  const Customer({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.marketingConsent,
    required this.notes,
    required this.vehicles,
    this.loyaltyStamps = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    email: json['email'] as String?,
    marketingConsent: json['marketing_consent'] as bool,
    notes: json['notes'] as String?,
    loyaltyStamps: json['loyalty_stamps'] as int? ?? 0,
    vehicles: [
      for (final vehicle in (json['vehicles'] as List?) ?? const []) Vehicle.fromJson(vehicle as Map<String, dynamic>),
    ],
  );

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final bool marketingConsent;
  final String? notes;

  /// Stamps on the loyalty card, shared by all branches.
  final int loyaltyStamps;
  final List<Vehicle> vehicles;

  /// The name, or the phone number for customers who gave no name.
  String get displayName => (name == null || name!.isEmpty) ? formatPhone(phone) : name!;
}

/// A customer's car; its size picks the price of each service.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.plateNumber,
    required this.vehicleSizeId,
    required this.make,
    required this.model,
    required this.color,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as String?,
    plateNumber: json['plate_number'] as String,
    vehicleSizeId: json['vehicle_size_id'] as String?,
    make: json['make'] as String?,
    model: json['model'] as String?,
    color: json['color'] as String?,
  );

  /// Null for a car not saved yet (part of a new customer's registration).
  final String? id;
  final String plateNumber;
  final String? vehicleSizeId;
  final String? make;
  final String? model;
  final String? color;

  /// "Toyota Camry · White", leaving out what is unknown.
  String get description => [
    [make, model].whereType<String>().where((part) => part.isNotEmpty).join(' '),
    if (color != null && color!.isNotEmpty) color!,
  ].where((part) => part.isNotEmpty).join(' · ');

  Map<String, dynamic> toJson() => {
    'plate_number': plateNumber,
    'vehicle_size_id': vehicleSizeId,
    'make': make,
    'model': model,
    'color': color,
  };
}

/// Groups a stored number for reading: "+97333334444" → "+973 3333 4444". Other forms are left as they are.
String formatPhone(String phone) {
  final bahraini = RegExp(r'^\+973(\d{4})(\d{4})$').firstMatch(phone);
  return bahraini == null ? phone : '+973 ${bahraini[1]} ${bahraini[2]}';
}
