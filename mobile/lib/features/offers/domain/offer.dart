/// An offer shown on the car wash's public customer page. Amounts in minor units.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    this.description,
    this.price,
    this.expiresOn,
    required this.isActive,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => Offer(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    price: json['price'] as int?,
    expiresOn: json['expires_on'] as String?,
    isActive: json['is_active'] as bool,
  );

  final String id;
  final String title;
  final String? description;

  /// Minor units; null when the offer has no set price.
  final int? price;
  final String? expiresOn;
  final bool isActive;
}
