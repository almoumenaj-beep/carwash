import 'package:carwash_app/features/auth/application/session_controller.dart';
import 'package:carwash_app/features/auth/domain/me.dart';
import 'package:carwash_app/features/inventory/data/inventory_repository.dart';
import 'package:carwash_app/features/inventory/domain/inventory.dart';
import 'package:carwash_app/features/inventory/presentation/stock_issue_screen.dart';
import 'package:carwash_app/features/orders/data/orders_repository.dart';
import 'package:carwash_app/features/orders/domain/order.dart';
import 'package:carwash_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedSession extends SessionController {
  @override
  Future<Me?> build() async => const Me(
    id: 'u1',
    name: 'Keeper',
    email: null,
    carWashName: 'Demo',
    isOwner: false,
    allBranches: false,
    roles: [],
    permissions: {'inventory.adjust'},
    branches: [BranchSummary(id: 'b1', name: 'Main', code: 'MAIN')],
  );
}

class RecordingRepository extends InventoryRepository {
  RecordingRepository() : super(Dio());

  String? receiverId;
  List<({String itemId, double quantity})>? issued;

  @override
  Future<void> issue(
    String branchId,
    String receiverId,
    List<({String itemId, double quantity})> lines, {
    String? note,
  }) async {
    this.receiverId = receiverId;
    issued = lines;
  }
}

InventoryItem item(String id, String name, double quantity) => InventoryItem(
  id: id,
  name: name,
  unit: 'L',
  unitCost: 0,
  minStock: 0,
  quantity: quantity,
  isLow: false,
  isActive: true,
);

void main() {
  late RecordingRepository repository;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = RecordingRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(FixedSession.new),
          inventoryRepositoryProvider.overrideWithValue(repository),
          inventoryItemsProvider('b1').overrideWith((ref) async => [item('i1', 'Shampoo', 10), item('i2', 'Wax', 4)]),
          branchStaffProvider('b1').overrideWith((ref) async => const [NamedRef(id: 'u2', name: 'Mahmood')]),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const StockIssueScreen(branchId: 'b1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String field, String option) async {
    await tester.tap(find.text(field));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> add(WidgetTester tester, String material, String quantity) async {
    await pick(tester, 'Material', material);
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), quantity);
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
  }

  testWidgets('materials are added to a list one at a time and issued together', (tester) async {
    await pumpScreen(tester);

    await pick(tester, 'Received by', 'Mahmood');
    await add(tester, 'Shampoo', '2.5');
    expect(find.text('Materials to issue (1)'), findsOneWidget);
    expect(find.text('2.5 L'), findsOneWidget);

    await add(tester, 'Wax', '1');
    expect(find.text('Materials to issue (2)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.outbox_outlined));
    await tester.pump();

    expect(repository.receiverId, 'u2');
    expect(repository.issued, [(itemId: 'i1', quantity: 2.5), (itemId: 'i2', quantity: 1.0)]);
  });

  testWidgets('a line removed from the list is not issued and can be chosen again', (tester) async {
    await pumpScreen(tester);

    await pick(tester, 'Received by', 'Mahmood');
    await add(tester, 'Shampoo', '2');
    await add(tester, 'Wax', '1');
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Materials to issue (1)'), findsOneWidget);

    await tester.tap(find.text('Material'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Shampoo'), findsWidgets);
    await tester.tap(find.textContaining('Shampoo').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '3');

    // Chosen but not added yet: issuing includes it rather than dropping it.
    await tester.tap(find.byIcon(Icons.outbox_outlined));
    await tester.pump();

    expect(repository.issued, [(itemId: 'i2', quantity: 1.0), (itemId: 'i1', quantity: 3.0)]);
  });

  testWidgets('more than the stock stays out of the list, and nothing is issued without a receiver', (tester) async {
    await pumpScreen(tester);

    await add(tester, 'Wax', '5');
    expect(find.text('Only 4 L of Wax is in stock'), findsOneWidget);
    expect(find.text('Materials to issue (0)'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '4');
    await tester.tap(find.text('Add material'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.outbox_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Choose who receives them'), findsOneWidget);
    expect(repository.issued, isNull);
  });
}
