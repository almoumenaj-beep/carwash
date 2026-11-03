import 'package:carwash_app/features/appointments/domain/appointment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a booking made by phone', () {
    final appointment = Appointment.fromJson({
      'id': 'a1',
      'branch_id': 'b1',
      'starts_at': '2026-11-04T10:00:00+03:00',
      'ends_at': '2026-11-04T10:17:00+03:00',
      'status': 'booked',
      'customer': null,
      'customer_name': 'Hassan',
      'customer_phone': '+97339991111',
      'vehicle_id': null,
      'plate_number': '55777',
      'vehicle_size': {'id': 's1', 'name': 'Sedan'},
      'items': [
        {'service_id': 'w1', 'quantity': 1, 'name': 'Exterior wash'},
      ],
      'estimated_total': 2500,
      'notes': null,
      'cancel_reason': null,
      'order': null,
      'created_by': {'id': 'u1', 'name': 'Reception'},
    });

    expect(appointment.isBooked, isTrue);
    expect(appointment.minutes, 17);
    expect(appointment.customerName, 'Hassan');
    expect(appointment.vehicleSizeId, 's1');
    expect(appointment.items.single.name, 'Exterior wash');
    expect(appointment.orderId, isNull);
  });

  test('a checked-in booking points to its order and falls back to the customer', () {
    final appointment = Appointment.fromJson({
      'id': 'a1',
      'branch_id': 'b1',
      'starts_at': '2026-11-04T10:00:00+03:00',
      'ends_at': '2026-11-04T10:15:00+03:00',
      'status': 'checked_in',
      'customer': {'id': 'c1', 'name': 'Ali', 'phone': '+97333334444'},
      'customer_name': null,
      'customer_phone': null,
      'vehicle_id': 'v1',
      'plate_number': '12345',
      'vehicle_size': null,
      'items': [],
      'estimated_total': 2000,
      'notes': null,
      'cancel_reason': null,
      'order': {'id': 'o1', 'number': 7},
      'created_by': {'id': 'u1', 'name': 'Reception'},
    });

    expect(appointment.status, AppointmentStatus.checkedIn);
    expect(appointment.customerName, 'Ali');
    expect(appointment.customerPhone, '+97333334444');
    expect(appointment.orderNumber, 7);
  });
}
