/// A role of the car wash, from `/roles`.
class Role {
  const Role({
    required this.id,
    required this.key,
    required this.name,
    required this.label,
    required this.isOwnerRole,
    required this.permissions,
    required this.usersCount,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
    id: json['id'] as int,
    key: json['key'] as String?,
    name: json['name'] as String,
    label: json['label'] as String,
    isOwnerRole: json['is_owner_role'] as bool,
    permissions: {for (final permission in (json['permissions'] as List?) ?? const []) permission as String},
    usersCount: json['users_count'] as int? ?? 0,
  );

  final int id;

  /// Set for the default roles (owner, cashier, ...); null for custom roles.
  final String? key;
  final String name;

  /// Translated name for display.
  final String label;
  final bool isOwnerRole;
  final Set<String> permissions;
  final int usersCount;
}

/// One module of the permission catalog with its translated permissions.
class PermissionModule {
  const PermissionModule({required this.module, required this.label, required this.permissions});

  factory PermissionModule.fromJson(Map<String, dynamic> json) => PermissionModule(
    module: json['module'] as String,
    label: json['label'] as String,
    permissions: [
      for (final permission in json['permissions'] as List)
        PermissionItem(
          name: (permission as Map<String, dynamic>)['name'] as String,
          label: permission['label'] as String,
        ),
    ],
  );

  final String module;
  final String label;
  final List<PermissionItem> permissions;
}

class PermissionItem {
  const PermissionItem({required this.name, required this.label});

  final String name;
  final String label;
}
