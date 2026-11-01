import 'package:carwash_app/core/auth/route_permissions.dart';
import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:flutter_test/flutter_test.dart';

Me meWith(Set<String> permissions) => Me(
  id: 'u1',
  name: 'Staff',
  email: null,
  carWashName: 'Demo',
  isOwner: false,
  allBranches: false,
  roles: const [],
  permissions: permissions,
  branches: const [],
);

void main() {
  test('sections without a rule are open to every signed-in user', () {
    expect(canOpen('/', meWith({})), isTrue);
    expect(canOpen('/pin', meWith({})), isTrue);
  });

  test('staff and devices need users.manage, including nested pages', () {
    final cashier = meWith({'orders.view', 'pos.checkout'});
    final manager = meWith({'users.manage'});

    expect(canOpen('/staff', cashier), isFalse);
    expect(canOpen('/staff/new', cashier), isFalse);
    expect(canOpen('/devices', cashier), isFalse);
    expect(canOpen('/staff/abc', manager), isTrue);
    expect(canOpen('/devices', manager), isTrue);
  });

  test('roles open with either roles.manage or users.manage', () {
    expect(canOpen('/roles', meWith({'users.manage'})), isTrue);
    expect(canOpen('/roles/3', meWith({'roles.manage'})), isTrue);
    expect(canOpen('/roles', meWith({'orders.view'})), isFalse);
  });

  test('settings and branches need settings.manage', () {
    expect(canOpen('/settings', meWith({'users.manage'})), isFalse);
    expect(canOpen('/branches/b1', meWith({'orders.view'})), isFalse);
    expect(canOpen('/branches/new', meWith({'settings.manage'})), isTrue);
  });

  test('the queue needs orders.view, and checking a car in needs orders.create', () {
    final washer = meWith({'orders.view', 'orders.update_status'});
    final cashier = meWith({'orders.view', 'orders.create'});

    expect(canOpen('/queue', washer), isTrue);
    expect(canOpen('/queue/o1', washer), isTrue);
    expect(canOpen('/queue/new', washer), isFalse);
    expect(canOpen('/queue/new', cashier), isTrue);
    expect(canOpen('/queue', meWith({'customers.view'})), isFalse);
  });

  test('taking payment needs pos.checkout', () {
    expect(canOpen('/checkout/o1', meWith({'orders.view', 'orders.update_status'})), isFalse);
    expect(canOpen('/checkout/o1', meWith({'orders.view', 'pos.checkout'})), isTrue);
  });

  test('a prefix only matches whole path segments', () {
    expect(canOpen('/staffroom', meWith({})), isTrue);
  });
}
