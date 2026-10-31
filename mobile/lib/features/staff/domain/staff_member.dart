import '../../auth/domain/me.dart';

/// A staff account as managers see it, from `/users`.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.isOwner,
    required this.allBranches,
    required this.hasPin,
    required this.roles,
    required this.branches,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    isActive: json['is_active'] as bool,
    isOwner: json['is_owner'] as bool,
    allBranches: json['all_branches'] as bool,
    hasPin: json['has_pin'] as bool,
    roles: [
      for (final role in (json['roles'] as List?) ?? const []) RoleSummary.fromJson(role as Map<String, dynamic>),
    ],
    branches: [
      for (final branch in (json['branches'] as List?) ?? const [])
        BranchSummary.fromJson(branch as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final bool isActive;
  final bool isOwner;
  final bool allBranches;
  final bool hasPin;
  final List<RoleSummary> roles;
  final List<BranchSummary> branches;
}

/// What the staff form sends; null fields are left unchanged on update.
class StaffDraft {
  const StaffDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.roleIds,
    required this.allBranches,
    required this.branchIds,
    this.includeBranches = true,
    this.isActive,
  });

  final String name;
  final String? email;
  final String? phone;
  final String? password;
  final Set<int> roleIds;
  final bool allBranches;
  final Set<String> branchIds;
  final bool includeBranches;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    if (password != null && password!.isNotEmpty) 'password': password,
    if (includeBranches) ...{'all_branches': allBranches, 'branch_ids': allBranches ? <String>[] : branchIds.toList()},
    if (isActive != null) 'is_active': isActive,
  };
}
