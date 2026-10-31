/// The signed-in staff member, from `GET /me`.
class Me {
  const Me({
    required this.id,
    required this.name,
    required this.email,
    required this.carWashName,
    required this.isOwner,
    required this.allBranches,
    required this.roles,
    required this.permissions,
    required this.branches,
  });

  factory Me.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'] as Map<String, dynamic>;

    return Me(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      carWashName: tenant['name'] as String,
      isOwner: json['is_owner'] as bool,
      allBranches: json['all_branches'] as bool,
      roles: [
        for (final role in json['roles'] as List) RoleSummary.fromJson(role as Map<String, dynamic>),
      ],
      permissions: {for (final permission in json['permissions'] as List) permission as String},
      branches: [
        for (final branch in json['branches'] as List) BranchSummary.fromJson(branch as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final String? email;
  final String carWashName;
  final bool isOwner;
  final bool allBranches;
  final List<RoleSummary> roles;
  final Set<String> permissions;
  final List<BranchSummary> branches;

  /// Whether the server granted [permission]. For showing or hiding UI only — the server enforces it.
  bool can(String permission) => permissions.contains(permission);
}

class RoleSummary {
  const RoleSummary({required this.id, required this.key, required this.label});

  factory RoleSummary.fromJson(Map<String, dynamic> json) => RoleSummary(
        id: json['id'] as int,
        key: json['key'] as String?,
        label: json['label'] as String,
      );

  final int id;
  final String? key;
  final String label;
}

class BranchSummary {
  const BranchSummary({required this.id, required this.name, required this.code});

  factory BranchSummary.fromJson(Map<String, dynamic> json) => BranchSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
      );

  final String id;
  final String name;
  final String code;
}

/// A staff member who can switch in on this device with a PIN.
class DeviceStaff {
  const DeviceStaff({required this.id, required this.name});

  factory DeviceStaff.fromJson(Map<String, dynamic> json) => DeviceStaff(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
}
