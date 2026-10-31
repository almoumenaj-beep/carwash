import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/me.dart';
import '../../roles/data/roles_repository.dart';
import '../../roles/domain/role.dart';
import '../data/staff_repository.dart';
import '../domain/staff_member.dart';

/// Adds a staff member ([staffId] null) or edits one: profile, roles, branches and activation.
class StaffEditorScreen extends ConsumerWidget {
  const StaffEditorScreen({super.key, this.staffId});

  final String? staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = staffId == null ? const AsyncData<StaffMember?>(null) : ref.watch(staffMemberProvider(staffId!));
    final roles = ref.watch(rolesProvider);
    final branches = ref.watch(branchesProvider);
    final me = ref.watch(sessionProvider).value;

    void retry() {
      ref.invalidate(rolesProvider);
      ref.invalidate(branchesProvider);
      if (staffId != null) {
        ref.invalidate(staffMemberProvider(staffId!));
      }
    }

    return switch ((staff, roles, branches)) {
      (AsyncData(value: final staff), AsyncData(value: final roles), AsyncData(value: final branches))
          when me != null =>
        _StaffForm(key: ValueKey(staff?.id), staff: staff, roles: roles, branches: branches, me: me),
      (AsyncError(:final error), _, _) ||
      (_, AsyncError(:final error), _) ||
      (_, _, AsyncError(:final error)) => Scaffold(
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

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({super.key, required this.staff, required this.roles, required this.branches, required this.me});

  final StaffMember? staff;
  final List<Role> roles;
  final List<BranchSummary> branches;
  final Me me;

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.staff?.name);
  late final _email = TextEditingController(text: widget.staff?.email);
  late final _phone = TextEditingController(text: widget.staff?.phone);
  final _password = TextEditingController();
  late final Set<int> _roleIds = {for (final role in widget.staff?.roles ?? const <RoleSummary>[]) role.id};
  late final Set<String> _branchIds = {
    for (final branch in widget.staff?.branches ?? const <BranchSummary>[]) branch.id,
  };
  late bool _allBranches = widget.staff?.allBranches ?? false;
  late bool _isActive = widget.staff?.isActive ?? true;
  bool _saving = false;
  ApiProblem? _problem;

  bool get _isNew => widget.staff == null;

  bool get _isSelf => widget.staff?.id == widget.me.id;

  /// Branch access is sent only when changed: a branch manager may edit staff who also work in
  /// branches the manager cannot grant, and resending those would be refused.
  bool get _branchesChanged {
    final staff = widget.staff!;
    final original = {for (final branch in staff.branches) branch.id};
    return _allBranches != staff.allBranches ||
        (!_allBranches && (original.length != _branchIds.length || !original.containsAll(_branchIds)));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _problem = null;
    });

    final draft = StaffDraft(
      name: _name.text.trim(),
      email: _optional(_email),
      phone: _optional(_phone),
      password: _password.text,
      roleIds: _roleIds,
      allBranches: _allBranches,
      branchIds: _branchIds,
      includeBranches: _isNew || _branchesChanged,
      isActive: _isNew ? null : _isActive,
    );

    final repository = ref.read(staffRepositoryProvider);
    try {
      if (_isNew) {
        await repository.create(draft);
      } else {
        final staff = widget.staff!;
        await repository.update(staff.id, draft);
        final originalRoleIds = {for (final role in staff.roles) role.id};
        if (originalRoleIds.length != _roleIds.length || !originalRoleIds.containsAll(_roleIds)) {
          await repository.syncRoles(staff.id, _roleIds);
        }
        ref.invalidate(staffMemberProvider(staff.id));
      }
      ref.invalidate(staffListProvider);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fieldErrors = {'name', 'email', 'phone', 'password', 'is_active'};
    final hasFieldError = _problem != null && _problem!.errors.keys.any(fieldErrors.contains);
    final generalError = _problem != null && !hasFieldError ? problemMessage(context, _problem!) : null;
    final activeError = _problem?.fieldError('is_active');

    String? emailOrPhone(String? _) =>
        _optional(_email) == null && _optional(_phone) == null ? l10n.emailOrPhoneRequired : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? l10n.newStaff : widget.staff!.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.check),
        label: Text(l10n.save),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.staffName, errorText: _problem?.fieldError('name')),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.emailField, errorText: _problem?.fieldError('email')),
              validator: emailOrPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneField, errorText: _problem?.fieldError('phone')),
              validator: emailOrPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.passwordField,
                helperText: _isNew ? null : l10n.passwordKeepHint,
                errorText: _problem?.fieldError('password'),
              ),
              validator: (value) => _isNew && (value == null || value.isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 24),
            Text(l10n.rolesSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final role in widget.roles)
                  FilterChip(
                    label: Text(role.label),
                    selected: _roleIds.contains(role.id),
                    // Only owners hand out the owner role; the server enforces this too.
                    onSelected: role.isOwnerRole && !widget.me.isOwner
                        ? null
                        : (selected) => setState(() => selected ? _roleIds.add(role.id) : _roleIds.remove(role.id)),
                  ),
              ],
            ),
            if (_problem?.fieldError('roles') case final rolesError?) ...[
              const SizedBox(height: 8),
              Text(rolesError, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            Text(l10n.branchesSection, style: theme.textTheme.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.allBranchesSwitch),
              value: _allBranches,
              onChanged: widget.me.allBranches ? (value) => setState(() => _allBranches = value) : null,
            ),
            for (final branch in widget.branches)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(branch.name),
                subtitle: Text(branch.code),
                value: _allBranches || _branchIds.contains(branch.id),
                onChanged: _allBranches
                    ? null
                    : (checked) =>
                          setState(() => checked == true ? _branchIds.add(branch.id) : _branchIds.remove(branch.id)),
              ),
            if (!_isNew) ...[
              const Divider(height: 32),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.activeSwitch),
                subtitle: activeError == null
                    ? null
                    : Text(activeError, style: TextStyle(color: theme.colorScheme.error)),
                value: _isActive,
                onChanged: _isSelf ? null : (value) => setState(() => _isActive = value),
              ),
            ],
            if (generalError != null) ...[
              const SizedBox(height: 12),
              Text(generalError, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
