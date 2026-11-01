import 'package:carwash_app/features/catalog/domain/catalog.dart';
import 'package:carwash_app/features/orders/domain/order.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> orderJson({
  String status = 'waiting',
  List<String> allowedNext = const ['in_progress', 'cancelled'],
}) => {
  'id': 'o1',
  'number': 7,
  'reference': 'MAIN-7',
  'branch_id': 'b1',
  'status': status,
  'allowed_next': allowedNext,
  'customer': {'id': 'c1', 'name': 'Ahmed', 'phone': '+97333334444'},
  'vehicle_id': 'v1',
  'plate_number': '12345',
  'vehicle_size_id': 's1',
  'bay': {'id': 'bay1', 'name': 'Bay 1'},
  'staff': [
    {'id': 'u1', 'name': 'Ali'},
  ],
  'items': [
    {
      'id': 'i1',
      'service_id': 'wash',
      'name': 'Exterior wash',
      'is_addon': false,
      'quantity': 1,
      'unit_price': 2000,
      'line_total': 2000,
      'duration_minutes': 15,
    },
    {
      'id': 'i2',
      'service_id': 'fresh',
      'name': 'Air freshener',
      'is_addon': true,
      'quantity': 1,
      'unit_price': 500,
      'line_total': 500,
      'duration_minutes': 2,
    },
  ],
  'subtotal': 2500,
  'estimated_minutes': 17,
  'notes': null,
  'cancel_reason': null,
  'created_by': {'id': 'u2', 'name': 'Sara'},
  'created_at': '2026-11-01T09:00:00+00:00',
  'started_at': status == 'waiting' ? null : '2026-11-01T09:10:00+00:00',
  'qc_at': status == 'qc' ? '2026-11-01T09:25:00+00:00' : null,
  'ready_at': null,
  'delivered_at': null,
  'cancelled_at': null,
  'history': [
    {'from': null, 'to': 'waiting', 'by': 'Sara', 'reason': null, 'at': '2026-11-01T09:00:00+00:00'},
  ],
  'quality_checks': [
    {
      'passed': false,
      'by': 'Ali',
      'at': '2026-11-01T09:30:00+00:00',
      'results': [
        {'item_id': 'i1', 'name': 'Exterior wash', 'passed': true},
        {'item_id': 'i2', 'name': 'Air freshener', 'passed': false},
      ],
    },
  ],
};

void main() {
  test('reads an order as the queue shows it', () {
    final order = Order.fromJson(orderJson());

    expect(order.reference, 'MAIN-7');
    expect(order.status, OrderStatus.waiting);
    expect(order.customer?.name, 'Ahmed');
    expect(order.bay?.name, 'Bay 1');
    expect(order.servicesSummary, 'Exterior wash + Air freshener');
    expect(order.subtotal, 2500);
    expect(order.history.single.to, OrderStatus.waiting);
    expect(order.items.first.id, 'i1');
    expect(order.qualityChecks.single.passed, isFalse);
    expect(order.qualityChecks.single.results.last, (name: 'Air freshener', passed: false));
    expect(order.stageStartedAt, DateTime.utc(2026, 11, 1, 9));
  });

  test('the next step is the first forward move, never cancelling or sending back', () {
    expect(Order.fromJson(orderJson()).nextStep, OrderStatus.inProgress);

    final washing = Order.fromJson(orderJson(status: 'in_progress', allowedNext: ['qc', 'waiting', 'cancelled']));
    expect(washing.nextStep, OrderStatus.qualityCheck);
    expect(washing.stageStartedAt, DateTime.utc(2026, 11, 1, 9, 10));

    final ready = Order.fromJson(orderJson(status: 'ready', allowedNext: ['delivered', 'in_progress']));
    expect(ready.nextStep, OrderStatus.delivered);
    expect(ready.status.isForwardTo(OrderStatus.inProgress), isFalse);

    expect(Order.fromJson(orderJson(status: 'delivered', allowedNext: [])).nextStep, isNull);

    final inspecting = Order.fromJson(orderJson(status: 'qc', allowedNext: ['ready', 'in_progress', 'cancelled']));
    expect(inspecting.nextStep, OrderStatus.ready);
    expect(inspecting.stageStartedAt, DateTime.utc(2026, 11, 1, 9, 25));
  });

  test('a walk-in has no customer', () {
    final order = Order.fromJson({...orderJson(), 'customer': null, 'bay': null});

    expect(order.customer, isNull);
    expect(order.bay, isNull);
  });

  test('prices resolve like the server: size and branch, size, branch, then every size', () {
    CatalogService serviceWith(List<ServicePrice> prices) => CatalogService(
      id: 'wash',
      categoryId: null,
      name: 'Wash',
      description: null,
      durationMinutes: 15,
      isAddon: false,
      isActive: true,
      prices: prices,
    );

    final service = serviceWith(const [
      ServicePrice(vehicleSizeId: 'sedan', branchId: null, price: 2000),
      ServicePrice(vehicleSizeId: 'sedan', branchId: 'seef', price: 1800),
      ServicePrice(vehicleSizeId: null, branchId: 'seef', price: 3000),
      ServicePrice(vehicleSizeId: null, branchId: null, price: 2500),
    ]);

    expect(service.priceFor('sedan', 'seef'), 1800);
    expect(service.priceFor('sedan', 'main'), 2000);
    expect(service.priceFor('suv', 'seef'), 3000);
    expect(service.priceFor('suv', 'main'), 2500);
    expect(service.priceFor(null, 'main'), 2500);
    expect(
      serviceWith(const [ServicePrice(vehicleSizeId: 'sedan', branchId: null, price: 2000)]).priceFor(null, 'main'),
      isNull,
    );
  });
}
