import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json([Map<String, dynamic> extra = const {}]) => {
  'id': 'u1',
  'name': 'Mahmood',
  'email': null,
  'tenant': {'name': 'Blue Line', 'slug': 'blue-line'},
  'is_owner': false,
  'all_branches': false,
  'roles': <Object>[],
  'permissions': <Object>[],
  'branches': <Object>[],
  ...extra,
};

void main() {
  test('reads whether the device is shared', () {
    final me = Me.fromJson(_json({'device_is_shared': true}));

    expect(me.deviceIsShared, isTrue);
  });

  test('switching stays hidden when the server does not say otherwise', () {
    final me = Me.fromJson(_json());

    expect(me.deviceIsShared, isFalse);
  });
}
