import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_problem.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/problem_message.dart';
import '../../../l10n/app_localizations.dart';
import '../data/branches_repository.dart';
import '../domain/branch.dart';

/// Opens a branch ([branchId] null) or edits one: details, weekly hours and, once saved, its bays.
class BranchEditorScreen extends ConsumerWidget {
  const BranchEditorScreen({super.key, this.branchId});

  final String? branchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (branchId == null) {
      return const _BranchForm(branch: null);
    }

    return switch (ref.watch(branchProvider(branchId!))) {
      AsyncData(:final value) => _BranchForm(key: ValueKey(value.id), branch: value),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(error: error, onRetry: () => ref.invalidate(branchProvider(branchId!))),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _BranchForm extends ConsumerStatefulWidget {
  const _BranchForm({super.key, required this.branch});

  final Branch? branch;

  @override
  ConsumerState<_BranchForm> createState() => _BranchFormState();
}

class _BranchFormState extends ConsumerState<_BranchForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.branch?.name);
  late final _code = TextEditingController(text: widget.branch?.code);
  late final _phone = TextEditingController(text: widget.branch?.phone);
  late final _address = TextEditingController(text: widget.branch?.address);
  late final Map<String, DayHours?> _hours = {
    for (final day in weekDays) day: widget.branch == null ? DayHours.standard : widget.branch!.openingHours[day],
  };
  late bool _isActive = widget.branch?.isActive ?? true;
  bool _saving = false;
  ApiProblem? _problem;

  bool get _isNew => widget.branch == null;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _phone.dispose();
    _address.dispose();
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

    final data = {
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'phone': _optional(_phone),
      'address': _optional(_address),
      'opening_hours': {for (final day in weekDays) day: _hours[day]?.toJson()},
      if (!_isNew) 'is_active': _isActive,
    };

    final repository = ref.read(branchesRepositoryProvider);
    try {
      if (_isNew) {
        final branch = await repository.create(data);
        ref.invalidate(branchListProvider);
        if (mounted) {
          // Continue on the saved branch so its bays can be added straight away.
          context.pushReplacement('/branches/${branch.id}');
        }
      } else {
        await repository.update(widget.branch!.id, data);
        ref.invalidate(branchListProvider);
        ref.invalidate(branchProvider(widget.branch!.id));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).saved)));
        }
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

  Future<void> _pickTime(String day, {required bool opening}) async {
    final current = _hours[day]!;
    final [hour, minute] = (opening ? current.opens : current.closes).split(':').map(int.parse).toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) {
      return;
    }

    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _hours[day] = opening ? current.copyWith(opens: formatted) : current.copyWith(closes: formatted));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hoursError = _problem?.errors.entries.where((entry) => entry.key.startsWith('opening_hours')).firstOrNull;
    final knownFields = {'name', 'code', 'phone', 'address', 'is_active'};
    final hasKnownError = _problem != null && (_problem!.errors.keys.any(knownFields.contains) || hoursError != null);
    final generalError = _problem != null && !hasKnownError ? problemMessage(context, _problem!) : null;

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? l10n.newBranch : widget.branch!.name)),
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
              decoration: InputDecoration(labelText: l10n.branchName, errorText: _problem?.fieldError('name')),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.branchCode,
                helperText: l10n.branchCodeHint,
                errorText: _problem?.fieldError('code'),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.phoneField, errorText: _problem?.fieldError('phone')),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: InputDecoration(labelText: l10n.addressField, errorText: _problem?.fieldError('address')),
            ),
            if (!_isNew)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.branchActive),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            const SizedBox(height: 24),
            Text(l10n.openingHours, style: theme.textTheme.titleMedium),
            if (hoursError != null) Text(hoursError.value.first, style: TextStyle(color: theme.colorScheme.error)),
            Card(
              child: Column(
                children: [
                  for (final day in weekDays)
                    _DayRow(
                      dayLabel: _dayLabel(l10n, day),
                      hours: _hours[day],
                      onOpenChanged: (open) => setState(() => _hours[day] = open ? DayHours.standard : null),
                      onPickOpens: () => _pickTime(day, opening: true),
                      onPickCloses: () => _pickTime(day, opening: false),
                    ),
                ],
              ),
            ),
            if (generalError != null) ...[
              const SizedBox(height: 12),
              Text(generalError, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (!_isNew) ...[const SizedBox(height: 24), _BaysSection(branch: widget.branch!)],
          ],
        ),
      ),
    );
  }

  static String _dayLabel(AppLocalizations l10n, String day) => switch (day) {
    'sat' => l10n.daySat,
    'sun' => l10n.daySun,
    'mon' => l10n.dayMon,
    'tue' => l10n.dayTue,
    'wed' => l10n.dayWed,
    'thu' => l10n.dayThu,
    _ => l10n.dayFri,
  };
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.dayLabel,
    required this.hours,
    required this.onOpenChanged,
    required this.onPickOpens,
    required this.onPickCloses,
  });

  final String dayLabel;
  final DayHours? hours;
  final ValueChanged<bool> onOpenChanged;
  final VoidCallback onPickOpens;
  final VoidCallback onPickCloses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListTile(
      title: Text(dayLabel),
      subtitle: hours == null
          ? Text(l10n.closedDay)
          : Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(label: Text('${l10n.opensAt} ${hours!.opens}'), onPressed: onPickOpens),
                ActionChip(label: Text('${l10n.closesAt} ${hours!.closes}'), onPressed: onPickCloses),
              ],
            ),
      trailing: Switch(value: hours != null, onChanged: onOpenChanged),
    );
  }
}

/// Asks for a bay name; pops with the trimmed name, or null when cancelled.
class _BayNameDialog extends StatefulWidget {
  const _BayNameDialog({this.initial});

  final String? initial;

  @override
  State<_BayNameDialog> createState() => _BayNameDialogState();
}

class _BayNameDialogState extends State<_BayNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.initial == null ? l10n.addBay : l10n.bayName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.bayName),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: Text(l10n.save)),
      ],
    );
  }
}

/// Bays are saved one by one as they are added or changed, independently of the branch form.
class _BaysSection extends ConsumerWidget {
  const _BaysSection({required this.branch});

  final Branch branch;

  Future<String?> _askName(BuildContext context, {String? initial}) => showDialog<String>(
    context: context,
    builder: (_) => _BayNameDialog(initial: initial),
  );

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() change) async {
    try {
      await change();
      ref.invalidate(branchProvider(branch.id));
    } catch (error, stackTrace) {
      final problem = ApiProblem.from(error, stackTrace);
      if (context.mounted) {
        final message = problem.fieldError('name') ?? problemMessage(context, problem);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(branchesRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.baysSection, style: Theme.of(context).textTheme.titleMedium)),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.addBay),
              onPressed: () async {
                final name = await _askName(context);
                if (name != null && name.isNotEmpty && context.mounted) {
                  await _run(context, ref, () => repository.addBay(branch.id, name));
                }
              },
            ),
          ],
        ),
        if (branch.bays.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noBays))
        else
          Card(
            child: Column(
              children: [
                for (final bay in branch.bays)
                  ListTile(
                    leading: const Icon(Icons.local_car_wash_outlined),
                    title: Text(bay.name),
                    subtitle: bay.isActive ? null : Text(l10n.bayOutOfService),
                    onTap: () async {
                      final name = await _askName(context, initial: bay.name);
                      if (name != null && name.isNotEmpty && name != bay.name && context.mounted) {
                        await _run(context, ref, () => repository.updateBay(bay.id, {'name': name}));
                      }
                    },
                    trailing: Switch(
                      value: bay.isActive,
                      onChanged: (active) =>
                          _run(context, ref, () => repository.updateBay(bay.id, {'is_active': active})),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
