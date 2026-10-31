import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/route_permissions.dart';
import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../data/roles_repository.dart';
import '../domain/role.dart';

/// Creates a role ([roleId] null) or shows/edits one, with its permission matrix.
class RoleEditorScreen extends ConsumerWidget {
  const RoleEditorScreen({super.key, this.roleId});

  final int? roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(permissionCatalogProvider);
    final role = roleId == null ? const AsyncData<Role?>(null) : ref.watch(roleProvider(roleId!));
    final me = ref.watch(sessionProvider).value;

    void retry() {
      ref.invalidate(permissionCatalogProvider);
      if (roleId != null) {
        ref.invalidate(roleProvider(roleId!));
      }
    }

    return switch ((catalog, role)) {
      (AsyncData(value: final modules), AsyncData(value: final role)) when me != null => _RoleForm(
        key: ValueKey(role?.id),
        role: role,
        modules: modules,
        me: me,
      ),
      (AsyncError(:final error), _) || (_, AsyncError(:final error)) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: retry),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _RoleForm extends ConsumerStatefulWidget {
  const _RoleForm({super.key, required this.role, required this.modules, required this.me});

  final Role? role;
  final List<PermissionModule> modules;
  final Me me;

  @override
  ConsumerState<_RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends ConsumerState<_RoleForm> {
  late final _name = TextEditingController(text: widget.role?.name ?? '');
  late final Set<String> _selected = {...?widget.role?.permissions};
  bool _saving = false;
  bool _nameMissing = false;
  ApiProblem? _problem;

  bool get _isNew => widget.role == null;

  bool get _isOwnerRole => widget.role?.isOwnerRole ?? false;

  bool get _canEdit => widget.me.can(Permissions.rolesManage) && !_isOwnerRole;

  /// Only permissions the editor holds can be granted or revoked; the server enforces the same rule.
  bool _canToggle(String permission) => _canEdit && widget.me.can(permission);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    setState(() {
      _nameMissing = name.isEmpty;
      _problem = null;
    });
    if (_nameMissing) {
      return;
    }

    setState(() => _saving = true);

    final repository = ref.read(rolesRepositoryProvider);
    try {
      if (_isNew) {
        await repository.create(name: name, permissions: _selected);
      } else {
        final role = widget.role!;
        if (name != role.name) {
          await repository.rename(role.id, name);
        }
        if (!_sameSet(_selected, role.permissions)) {
          await repository.syncPermissions(role.id, _selected);
        }
        ref.invalidate(roleProvider(role.id));
      }
      ref.invalidate(rolesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        setState(() => _problem = problem);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final role = widget.role!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deleteRoleConfirm(role.label)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await ref.read(rolesRepositoryProvider).delete(role.id);
      ref.invalidate(rolesProvider);
      if (mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problemMessage(context, problem))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nameError = _nameMissing ? l10n.fieldRequired : _problem?.fieldError('name');
    final generalError = _problem != null && nameError == null ? problemMessage(context, _problem!) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newRole : widget.role!.label),
        actions: [
          if (!_isNew && _canEdit)
            IconButton(tooltip: l10n.deleteRole, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      floatingActionButton: _canEdit
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (_isOwnerRole)
            _Notice(icon: Icons.lock_outline, text: l10n.ownerRoleLocked)
          else if (!widget.me.can(Permissions.rolesManage))
            _Notice(icon: Icons.visibility_outlined, text: l10n.readOnlyRole),
          TextField(
            controller: _name,
            enabled: _canEdit,
            decoration: InputDecoration(labelText: l10n.roleName, errorText: nameError),
          ),
          if (generalError != null) ...[
            const SizedBox(height: 12),
            Text(generalError, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Text(l10n.permissionsSection, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final module in widget.modules) _buildModule(module),
        ],
      ),
    );
  }

  Widget _buildModule(PermissionModule module) {
    final names = [for (final permission in module.permissions) permission.name];
    final selectedCount = names.where((name) => _isOwnerRole || _selected.contains(name)).length;
    final toggleable = names.where(_canToggle).toList();

    return Card(
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(module.label, style: Theme.of(context).textTheme.titleSmall),
            tristate: true,
            value: selectedCount == 0 ? false : (selectedCount == names.length ? true : null),
            onChanged: toggleable.isEmpty
                ? null
                : (_) => setState(() {
                    final selectAll = !toggleable.every(_selected.contains);
                    selectAll ? _selected.addAll(toggleable) : _selected.removeAll(toggleable);
                  }),
          ),
          const Divider(height: 1),
          for (final permission in module.permissions)
            CheckboxListTile(
              dense: true,
              title: Text(permission.label),
              value: _isOwnerRole || _selected.contains(permission.name),
              onChanged: _canToggle(permission.name)
                  ? (checked) => setState(() {
                      checked == true ? _selected.add(permission.name) : _selected.remove(permission.name);
                    })
                  : null,
            ),
        ],
      ),
    );
  }

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(leading: Icon(icon), title: Text(text)),
    );
  }
}
