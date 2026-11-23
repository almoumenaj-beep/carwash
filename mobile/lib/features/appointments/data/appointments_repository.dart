import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../../orders/domain/order.dart';
import '../domain/appointment.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>(
  (ref) => AppointmentsRepository(ref.watch(dioProvider)),
);

/// A branch's bookings with the day's capacity and how loaded each opening hour is.
typedef DayBookings = ({List<Appointment> appointments, int capacity, List<({String hour, int used})> hours});

/// A booking list query: from [date] (`YYYY-MM-DD`) for [days] days (one by default, up to a week).
typedef AppointmentQuery = ({String branchId, String date, int days});

final appointmentsProvider = FutureProvider.autoDispose.family<DayBookings, AppointmentQuery>(
  (ref, query) => ref.watch(appointmentsRepositoryProvider).list(query.branchId, query.date, days: query.days),
);

/// The times a visit of [minutes] can still be booked on a day; [appointmentId] frees that booking's own place.
final appointmentSlotsProvider = FutureProvider.autoDispose
    .family<List<AppointmentSlot>, ({String branchId, String date, int minutes, String? appointmentId})>(
      (ref, query) => ref.watch(appointmentsRepositoryProvider).slots(query),
    );

class AppointmentsRepository {
  AppointmentsRepository(this._dio);

  final Dio _dio;

  Future<DayBookings> list(String branchId, String date, {int days = 1}) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/appointments',
        queryParameters: {'branch_id': branchId, 'date': date, 'days': days},
      ),
    );
    final meta = response.data?['meta'] as Map<String, dynamic>?;
    return (
      appointments: [
        for (final item in unwrapData<List>(response)) Appointment.fromJson(item as Map<String, dynamic>),
      ],
      capacity: (meta?['capacity'] as int?) ?? 1,
      hours: [
        for (final hour in (meta?['hours'] as List?) ?? const [])
          (
            hour: (hour as Map<String, dynamic>)['hour'] as String,
            used: hour['used'] as int,
          ),
      ],
    );
  }

  Future<void> confirm(String id) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/appointments/$id/confirm'));
  }

  Future<List<AppointmentSlot>> slots(
    ({String branchId, String date, int minutes, String? appointmentId}) query,
  ) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/appointments/slots',
        queryParameters: {
          'branch_id': query.branchId,
          'date': query.date,
          'minutes': query.minutes,
          'appointment_id': ?query.appointmentId,
        },
      ),
    );
    return [
      for (final slot in unwrapData<List>(response))
        (
          startsAt: (slot as Map<String, dynamic>)['starts_at'] as String,
          time: slot['time'] as String,
          free: slot['free'] as int,
        ),
    ];
  }

  Future<Appointment> book(Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/appointments', data: data));
    return Appointment.fromJson(unwrapData(response));
  }

  Future<Appointment> update(String id, Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.patch<Map<String, dynamic>>('/appointments/$id', data: data));
    return Appointment.fromJson(unwrapData(response));
  }

  Future<void> cancel(String id, String? reason) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/appointments/$id/cancel', data: {'reason': reason}));
  }

  Future<void> noShow(String id) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/appointments/$id/no-show'));
  }

  /// Checks the booked car in with the same details as at the counter.
  Future<Order> checkIn(String id, Map<String, dynamic> data) async {
    final response = await sendRequest(() => _dio.post<Map<String, dynamic>>('/appointments/$id/check-in', data: data));
    return Order.fromJson(unwrapData(response));
  }
}
