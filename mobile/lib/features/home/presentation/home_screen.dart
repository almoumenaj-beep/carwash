import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/auth/route_permissions.dart';
import '../../auth/application/session_controller.dart';
import '../../equipment/presentation/equipment_alert_card.dart';
import '../../staff_affairs/data/staff_affairs_repository.dart';
import '../../staff_affairs/presentation/attendance_card.dart';
import 'home_sections.dart';

/// Landing screen after sign-in: who is working, and the sections they may open.
/// Account details (roles, branches, permissions) and settings such as language and dark mode live on the account screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).value;
    if (me == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final attendance = ref.watch(myAttendanceProvider);
    // Only once the answer is known: a failed request must not lock anyone out of the app.
    final mustClockIn = me.requiresAttendance && attendance.hasValue && attendance.value == null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        // The car wash's name beside the logo, shrunk to fit rather than cut off.
        title: Row(
          children: [
            const AppLogo(size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  me.carWashName,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: AppTheme.lightGold, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (me.deviceIsShared)
            IconButton(
              tooltip: l10n.switchUser,
              icon: const Icon(Icons.switch_account_outlined),
              onPressed: () => context.push('/pin'),
            ),
          IconButton(
            tooltip: l10n.accountTitle,
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/account'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(sessionProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(me.name.characters.first)),
                title: Text(l10n.greeting(me.name)),
                subtitle: Text(me.roles.map((role) => role.label).join(l10n.listSeparator)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/account'),
              ),
            ),
            const AttendanceCard(),
            if (me.can(Permissions.equipmentView) && !mustClockIn) const EquipmentAlertCard(),
            if (mustClockIn)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      l10n.clockInToStart,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.clockInToStartHint, textAlign: TextAlign.center),
                  ],
                ),
              )
            else
              const HomeSectionsMenu(),
          ],
        ),
      ),
    );
  }
}
