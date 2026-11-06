import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json([Map<String, dynamic> extra = const {}]) => {
  'id': 'u1',
  'name': 'Mahmood',
  'email': null,
  'tenant': {'name': 'Blue Line'},
  'is_owner': false,
  'all_branches': false,
  'roles': <Object>[],
  'permissions': <Object>[],
  'branches': <Object>[],
  ...extra,
};

void main() {
  test('reads whether they must clock in and whether the device is shared', () {
    final me = Me.fromJson(_json({'requires_attendance': true, 'device_is_shared': true}));

    expect(me.requiresAttendance, isTrue);
    expect(me.deviceIsShared, isTrue);
  });

  test('nobody is held back and switching stays hidden when the server does not say otherwise', () {
    final me = Me.fromJson(_json());

    expect(me.requiresAttendance, isFalse);
    expect(me.deviceIsShared, isFalse);
  });
}
