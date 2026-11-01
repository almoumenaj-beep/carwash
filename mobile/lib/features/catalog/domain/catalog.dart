/// A vehicle size class that prices depend on.
class VehicleSize {
  const VehicleSize({required this.id, required this.name, required this.sortOrder, required this.isActive});

  factory VehicleSize.fromJson(Map<String, dynamic> json) => VehicleSize(
    id: json['id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int,
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
}

/// A group of services on the menu.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.servicesCount,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) => ServiceCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int,
    isActive: json['is_active'] as bool,
    servicesCount: json['services_count'] as int? ?? 0,
  );

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final int servicesCount;
}

/// A price in minor units (BHD: fils). A null size means every size, a null branch every branch.
class ServicePrice {
  const ServicePrice({required this.vehicleSizeId, required this.branchId, required this.price});

  factory ServicePrice.fromJson(Map<String, dynamic> json) => ServicePrice(
    vehicleSizeId: json['vehicle_size_id'] as String?,
    branchId: json['branch_id'] as String?,
    price: json['price'] as int,
  );

  final String? vehicleSizeId;
  final String? branchId;
  final int price;

  Map<String, dynamic> toJson() => {
    if (vehicleSizeId != null) 'vehicle_size_id': vehicleSizeId,
    if (branchId != null) 'branch_id': branchId,
    'price': price,
  };
}

/// A service on the menu, or an add-on sold with one.
class CatalogService {
  const CatalogService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.isAddon,
    required this.isActive,
    required this.prices,
    this.isPackage = false,
    this.packageDiscountType,
    this.packageDiscountValue = 0,
    this.packageItemIds = const [],
  });

  factory CatalogService.fromJson(Map<String, dynamic> json) => CatalogService(
    id: json['id'] as String,
    categoryId: json['service_category_id'] as String?,
    name: json['name'] as String,
    description: json['description'] as String?,
    durationMinutes: json['duration_minutes'] as int,
    isAddon: json['is_addon'] as bool,
    isActive: json['is_active'] as bool,
    prices: [
      for (final price in (json['prices'] as List?) ?? const []) ServicePrice.fromJson(price as Map<String, dynamic>),
    ],
    isPackage: json['is_package'] as bool? ?? false,
    packageDiscountType: json['package_discount_type'] as String?,
    packageDiscountValue: json['package_discount_value'] as int? ?? 0,
    packageItemIds: [
      for (final item in (json['package_items'] as List?) ?? const []) (item as Map<String, dynamic>)['id'] as String,
    ],
  );

  final String id;
  final String? categoryId;
  final String name;
  final String? description;
  final int durationMinutes;
  final bool isAddon;
  final bool isActive;
  final List<ServicePrice> prices;

  /// A package bundles [packageItemIds] and costs their prices less its discount: [packageDiscountValue] in minor
  /// units when [packageDiscountType] is `amount`, or in basis points (1500 = 15%) when it is `percent`.
  final bool isPackage;
  final String? packageDiscountType;
  final int packageDiscountValue;
  final List<String> packageItemIds;

  /// The general price for [sizeId] (or for every size when null), ignoring branch prices.
  int? generalPrice(String? sizeId) =>
      prices.where((price) => price.branchId == null && price.vehicleSizeId == sizeId).firstOrNull?.price;

  /// The price charged for [sizeId] at [branchId], resolved like the server: size and branch,
  /// then size, then branch, then the price for every size. Null when the service has no price.
  int? priceFor(String? sizeId, String? branchId) {
    for (final (size, branch) in [(sizeId, branchId), (sizeId, null), (null, branchId), (null, null)]) {
      final match = prices.where((price) => price.vehicleSizeId == size && price.branchId == branch).firstOrNull;
      if (match != null) {
        return match.price;
      }
    }
    return null;
  }

  /// What a package's services cost separately for [sizeId] at [branchId], looked up in [catalog] (services by
  /// id); null when one of them has no price.
  int? separatePriceIn(Map<String, CatalogService> catalog, String? sizeId, String? branchId) {
    var total = 0;
    for (final id in packageItemIds) {
      final price = catalog[id]?.priceFor(sizeId, branchId);
      if (price == null) {
        return null;
      }
      total += price;
    }
    return total;
  }

  /// The price charged for [sizeId] at [branchId], packages included: a package costs its services' prices
  /// less its discount, like on the server.
  int? priceIn(Map<String, CatalogService> catalog, String? sizeId, String? branchId) {
    if (!isPackage) {
      return priceFor(sizeId, branchId);
    }

    final full = separatePriceIn(catalog, sizeId, branchId);
    if (full == null || packageItemIds.isEmpty) {
      return null;
    }

    final discount = switch (packageDiscountType) {
      'amount' => packageDiscountValue,
      'percent' => (2 * full * packageDiscountValue + 10000) ~/ 20000,
      _ => 0,
    };
    return full - (discount > full ? full : discount);
  }

  /// The lowest general price, for "from ..." on the menu.
  int? get lowestPrice {
    final general = prices.where((price) => price.branchId == null).map((price) => price.price);
    return general.isEmpty ? null : general.reduce((a, b) => a < b ? a : b);
  }
}
