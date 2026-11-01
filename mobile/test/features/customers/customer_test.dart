import 'package:carwash_app/features/customers/domain/customer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a customer with their cars', () {
    final customer = Customer.fromJson({
      'id': 'c1',
      'phone': '+97333334444',
      'name': 'Ahmed',
      'email': null,
      'marketing_consent': true,
      'marketing_consent_at': '2026-11-01T10:00:00+03:00',
      'notes': null,
      'last_visit_at': null,
      'vehicles': [
        {
          'id': 'v1',
          'customer_id': 'c1',
          'plate_number': '12345',
          'vehicle_size_id': 's1',
          'make': 'Toyota',
          'model': 'Camry',
          'color': 'White',
          'notes': null,
        },
      ],
    });

    expect(customer.displayName, 'Ahmed');
    expect(customer.marketingConsent, isTrue);
    expect(customer.vehicles.single.description, 'Toyota Camry · White');
  });

  test('a customer without a name is shown by phone number', () {
    final customer = Customer.fromJson({
      'id': 'c1',
      'phone': '+97333334444',
      'name': null,
      'email': null,
      'marketing_consent': false,
      'notes': null,
      'vehicles': const [],
    });

    expect(customer.displayName, '+973 3333 4444');
  });

  test('Bahraini numbers are grouped for reading; others are left as stored', () {
    expect(formatPhone('+97333334444'), '+973 3333 4444');
    expect(formatPhone('+966501234567'), '+966501234567');
  });

  test('a car description leaves out what is unknown', () {
    const vehicle = Vehicle(id: null, plateNumber: '1', vehicleSizeId: null, make: null, model: 'Patrol', color: null);

    expect(vehicle.description, 'Patrol');
    expect(vehicle.toJson()['plate_number'], '1');
  });
}
