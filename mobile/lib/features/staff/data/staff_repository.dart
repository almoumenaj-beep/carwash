import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../../auth/domain/me.dart';
import '../domain/staff_member.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) => StaffRepository(ref.watch(dioProvider)));

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>((ref) {
  ref.watch(localeProvider);
  return ref.watch(staffRepositoryProvider).list();
});

final staffMemberProvider = FutureProvider.autoDispose.family<StaffMember, String>((ref, id) {
  ref.watch(localeProvider);
  return ref.watch(staffRepositoryProvider).find(id);
});

/// Branches the signed-in manager works in, offered when assigning staff.
final branchesProvider = FutureProvider.autoDispose<List<BranchSummary>>(
  (ref) => ref.watch(staffRepositoryProvider).branches(),
);

class StaffRepository {
  StaffRepository(this._dio);

  final Dio _dio;

  /// The first page (up to 50) of staff, which covers a car wash's team.
  Future<List<StaffMember>> list() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/users'));
    return [for (final staff in unwrapData<List>(response)) StaffMember.fromJson(staff as Map<String, dynamic>)];
  }

  Future<StaffMember> find(String id) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/users/$id'));
    return StaffMember.fromJson(unwrapData(response));
  }

  Future<StaffMember> create(StaffDraft draft) async {
    final response = await sendRequest(
      () => _dio.post<Map<String, dynamic>>('/users', data: {...draft.toJson(), 'roles': draft.roleIds.toList()}),
    );
    return StaffMember.fromJson(unwrapData(response));
  }

  Future<void> update(String id, StaffDraft draft) async {
    await sendRequest(() => _dio.patch<Map<String, dynamic>>('/users/$id', data: draft.toJson()));
  }

  Future<void> syncRoles(String id, Set<int> roleIds) async {
    await sendRequest(() => _dio.put<Map<String, dynamic>>('/users/$id/roles', data: {'roles': roleIds.toList()}));
  }

  Future<List<BranchSummary>> branches() async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/branches'));
    return [for (final branch in unwrapData<List>(response)) BranchSummary.fromJson(branch as Map<String, dynamic>)];
  }
}
