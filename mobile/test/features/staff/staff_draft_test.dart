import 'package:carwash_app/features/staff/domain/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StaffDraft draft({bool includeBranches = true, String? password, bool allBranches = false}) => StaffDraft(
    name: 'Washer',
    email: null,
    phone: '0555',
    password: password,
    roleIds: {4},
    allBranches: allBranches,
    branchIds: {'b1'},
    includeBranches: includeBranches,
    isActive: true,
  );

  test('omits branch access when it did not change', () {
    final json = draft(includeBranches: false).toJson();

    expect(json.containsKey('all_branches'), isFalse);
    expect(json.containsKey('branch_ids'), isFalse);
  });

  test('sends no branch list for all-branch staff', () {
    expect(draft(allBranches: true).toJson()['branch_ids'], isEmpty);
  });

  test('keeps the current password unless a new one is typed', () {
    expect(draft(password: '').toJson().containsKey('password'), isFalse);
    expect(draft(password: 'new-secret').toJson()['password'], 'new-secret');
  });
}
