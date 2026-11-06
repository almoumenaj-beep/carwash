import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_request.dart';
import '../domain/inventory.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) => InventoryRepository(ref.watch(dioProvider)));

/// Materials with their stock at a branch (null: all of the user's branches).
final inventoryItemsProvider = FutureProvider.autoDispose.family<List<InventoryItem>, String?>(
  (ref, branchId) => ref.watch(inventoryRepositoryProvider).items(branchId),
);

/// The latest stock changes at a branch, optionally for one material.
final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, ({String? branchId, String? itemId})>(
      (ref, query) => ref.watch(inventoryRepositoryProvider).movements(query.branchId, query.itemId),
    );

/// What left a branch's stock on a day (`YYYY-MM-DD`).
final dailyStockUsageProvider = FutureProvider.autoDispose.family<DailyStockUsage, ({String branchId, String date})>(
  (ref, query) => ref.watch(inventoryRepositoryProvider).dailyUsage(query.branchId, query.date),
);

final purchasesProvider = FutureProvider.autoDispose.family<List<Purchase>, String?>(
  (ref, branchId) => ref.watch(inventoryRepositoryProvider).purchases(branchId),
);

final serviceMaterialsProvider = FutureProvider.autoDispose.family<List<ServiceMaterial>, String>(
  (ref, serviceId) => ref.watch(inventoryRepositoryProvider).serviceMaterials(serviceId),
);

class InventoryRepository {
  InventoryRepository(this._dio);

  final Dio _dio;

  Future<List<InventoryItem>> items(String? branchId) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/inventory/items', queryParameters: {'branch_id': ?branchId}),
    );
    return [for (final item in unwrapData<List>(response)) InventoryItem.fromJson(item as Map<String, dynamic>)];
  }

  /// Adds a material (no [id]) or changes one; returns it as saved.
  Future<InventoryItem> saveItem(String? id, Map<String, dynamic> data) async {
    final response = await sendRequest(
      () => id == null
          ? _dio.post<Map<String, dynamic>>('/inventory/items', data: data)
          : _dio.patch<Map<String, dynamic>>('/inventory/items/$id', data: data),
    );
    return InventoryItem.fromJson(unwrapData(response));
  }

  /// Sets the branch's stock of the material to what was counted.
  Future<void> count(String branchId, String itemId, double quantity, {String? note}) async {
    await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/inventory/counts',
        data: {'branch_id': branchId, 'inventory_item_id': itemId, 'quantity': quantity, 'note': ?note},
      ),
    );
  }

  /// Issues materials from the branch's stock to a staff member: all of them, or none if one falls short.
  Future<void> issue(
    String branchId,
    String receiverId,
    List<({String itemId, double quantity})> lines, {
    String? note,
  }) async {
    await sendRequest(
      () => _dio.post<Map<String, dynamic>>(
        '/inventory/issues',
        data: {
          'branch_id': branchId,
          'issued_to': receiverId,
          'lines': [
            for (final line in lines) {'inventory_item_id': line.itemId, 'quantity': line.quantity},
          ],
          'note': ?note,
        },
      ),
    );
  }

  /// Cancels materials issued by mistake: the quantity goes back in stock and the issue stays on record.
  Future<void> cancelIssue(String movementId) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/inventory/issues/$movementId/cancel'));
  }

  Future<DailyStockUsage> dailyUsage(String branchId, String date) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/inventory/daily-usage',
        queryParameters: {'branch_id': branchId, 'date': date},
      ),
    );
    return DailyStockUsage.fromJson(unwrapData(response));
  }

  Future<List<StockMovement>> movements(String? branchId, String? itemId) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>(
        '/inventory/movements',
        queryParameters: {'branch_id': ?branchId, 'inventory_item_id': ?itemId},
      ),
    );
    return [
      for (final movement in unwrapData<List>(response)) StockMovement.fromJson(movement as Map<String, dynamic>),
    ];
  }

  Future<List<Purchase>> purchases(String? branchId) async {
    final response = await sendRequest(
      () => _dio.get<Map<String, dynamic>>('/inventory/purchases', queryParameters: {'branch_id': ?branchId}),
    );
    return [for (final purchase in unwrapData<List>(response)) Purchase.fromJson(purchase as Map<String, dynamic>)];
  }

  /// Cancels a purchase recorded by mistake: its quantities leave the stock and its expense is removed.
  Future<void> cancelPurchase(String id) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/inventory/purchases/$id/cancel'));
  }

  Future<void> recordPurchase(Map<String, dynamic> data) async {
    await sendRequest(() => _dio.post<Map<String, dynamic>>('/inventory/purchases', data: data));
  }

  Future<List<ServiceMaterial>> serviceMaterials(String serviceId) async {
    final response = await sendRequest(() => _dio.get<Map<String, dynamic>>('/services/$serviceId/materials'));
    return [
      for (final material in unwrapData<List>(response)) ServiceMaterial.fromJson(material as Map<String, dynamic>),
    ];
  }

  Future<void> saveServiceMaterials(String serviceId, List<({String itemId, double quantity})> materials) async {
    await sendRequest(
      () => _dio.put<Map<String, dynamic>>(
        '/services/$serviceId/materials',
        data: {
          'materials': [
            for (final material in materials) {'inventory_item_id': material.itemId, 'quantity': material.quantity},
          ],
        },
      ),
    );
  }
}
