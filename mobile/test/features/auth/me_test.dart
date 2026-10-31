import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the /me payload returned by the API', () {
    final me = Me.fromJson({
      'id': '0199a1b2-0000-7000-8000-000000000001',
      'name': 'Demo Cashier',
      'email': 'cashier@example.com',
      'tenant': {'id': 't1', 'name': 'Demo Car Wash', 'locale': 'ar', 'currency': 'BHD', 'timezone': 'Asia/Bahrain'},
      'is_owner': false,
      'all_branches': false,
      'roles': [
        {'id': 3, 'key': 'cashier', 'name': 'Cashier', 'label': 'كاشير', 'is_owner_role': false},
      ],
      'permissions': ['orders.view', 'pos.checkout'],
      'branches': [
        {'id': 'b1', 'name': 'Main Branch', 'code': 'MAIN', 'phone': null, 'address': null, 'is_active': true},
      ],
    });

    expect(me.carWashName, 'Demo Car Wash');
    expect(me.roles.single.label, 'كاشير');
    expect(me.can('pos.checkout'), isTrue);
    expect(me.can('roles.manage'), isFalse);
    expect(me.branches.single.code, 'MAIN');
  });
}
