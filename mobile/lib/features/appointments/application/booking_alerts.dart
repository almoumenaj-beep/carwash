import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/route_permissions.dart';
import '../../auth/application/session_controller.dart';
import '../../expenses/domain/expense.dart';
import '../data/appointments_repository.dart';

/// How many of today's bookings (all the user's branches) await reception's confirmation.
final pendingBookingsCountProvider = NotifierProvider<PendingBookingsCount, int>(PendingBookingsCount.new);

class PendingBookingsCount extends Notifier<int> {
  @override
  int build() => 0;

  set count(int value) => state = value;
}

final _alertsProvider = Provider<BookingAlerts>((ref) => BookingAlerts(ref));

/// Watches the signed-in session and polls today's bookings so a booking made on the customer page
/// rings a chime and raises [pendingBookingsCountProvider]. Watched from the app shell, so it runs on
/// every screen while the app is open.
final bookingAlertsWatcherProvider = Provider<void>((ref) {
  final session = ref.watch(sessionProvider).value;
  final alerts = ref.watch(_alertsProvider);
  ref.onDispose(alerts.stop);

  if (session != null && (session.can(Permissions.appointmentsManage) || session.can(Permissions.ordersCreate))) {
    alerts.start();
  } else {
    alerts.stop();
    ref.read(pendingBookingsCountProvider.notifier).count = 0;
  }
});

class BookingAlerts {
  BookingAlerts(this._ref);

  static const _pollEvery = Duration(seconds: 30);

  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;

  /// Pending count at the last poll; -1 until the first poll, so opening the app does not ring
  /// for bookings that arrived while it was closed.
  int _knownPending = -1;

  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_pollEvery, (_) => unawaited(_poll()));
    unawaited(_poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _knownPending = -1;
  }

  Future<void> _poll() async {
    final session = _ref.read(sessionProvider).value;
    if (session == null || session.branches.isEmpty) {
      return;
    }
    final date = apiDate(DateTime.now());
    var pending = 0;
    for (final branch in session.branches) {
      try {
        final day = await _ref.read(appointmentsRepositoryProvider).list(branch.id, date);
        pending += day.appointments.where((appointment) => appointment.isPending).length;
      } catch (_) {
        // A flaky network round must not stop the next poll.
      }
    }
    _ref.read(pendingBookingsCountProvider.notifier).count = pending;
    if (_knownPending >= 0 && pending > _knownPending) {
      unawaited(_player.play(AssetSource('sounds/new-booking.wav')));
    }
    _knownPending = pending;
  }
}
