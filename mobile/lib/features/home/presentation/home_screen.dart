import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/session_controller.dart';
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
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ],
        ),
        actions: [
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
            const HomeSectionsMenu(),
          ],
        ),
      ),
    );
  }
}
