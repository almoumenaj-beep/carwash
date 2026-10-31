import 'package:carwash_app/features/auth/application/session_controller.dart';
import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:carwash_app/features/roles/data/roles_repository.dart';
import 'package:carwash_app/features/roles/domain/role.dart';
import 'package:carwash_app/features/roles/presentation/role_editor_screen.dart';
import 'package:carwash_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const catalog = [
  PermissionModule(
    module: 'orders',
    label: 'Work orders',
    permissions: [
      PermissionItem(name: 'orders.view', label: 'View work orders'),
      PermissionItem(name: 'orders.refund', label: 'Issue refunds'),
    ],
  ),
];

Role role({bool isOwnerRole = false}) => Role(
  id: 7,
  key: isOwnerRole ? 'owner' : null,
  name: isOwnerRole ? 'Owner' : 'Supervisor',
  label: isOwnerRole ? 'Owner' : 'Supervisor',
  isOwnerRole: isOwnerRole,
  permissions: const {'orders.view'},
  usersCount: 0,
);

Me editor(Set<String> permissions) => Me(
  id: 'u1',
  name: 'Editor',
  email: null,
  carWashName: 'Demo',
  isOwner: false,
  allBranches: true,
  roles: const [],
  permissions: permissions,
  branches: const [],
);

void main() {
  Future<void> pumpEditor(WidgetTester tester, {required Role role, required Me me}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => FixedSession(me)),
          permissionCatalogProvider.overrideWith((ref) async => catalog),
          roleProvider(role.id).overrideWith((ref) async => role),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: RoleEditorScreen(roleId: role.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String label) =>
      tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label)).onChanged != null;

  testWidgets('the owner role is shown locked with every permission ticked', (tester) async {
    await pumpEditor(
      tester,
      role: role(isOwnerRole: true),
      me: editor({'roles.manage', 'orders.view', 'orders.refund'}),
    );

    expect(find.text('The owner role always has every permission and cannot be changed.'), findsOneWidget);
    expect(isEnabled(tester, 'Issue refunds'), isFalse);
    expect(tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Issue refunds')).value, isTrue);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('editors can only toggle permissions they hold themselves', (tester) async {
    await pumpEditor(tester, role: role(), me: editor({'roles.manage', 'orders.view'}));

    expect(isEnabled(tester, 'View work orders'), isTrue);
    expect(isEnabled(tester, 'Issue refunds'), isFalse);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('staff managers without roles.manage see roles read-only', (tester) async {
    await pumpEditor(tester, role: role(), me: editor({'users.manage', 'orders.view'}));

    expect(find.text('You can view roles but not change them.'), findsOneWidget);
    expect(isEnabled(tester, 'View work orders'), isFalse);
    expect(find.text('Save'), findsNothing);
  });
}

class FixedSession extends SessionController {
  FixedSession(this.me);

  final Me me;

  @override
  Future<Me?> build() async => me;
}
