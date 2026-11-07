/// The car wash's settings, from `/settings`.
class AppSettings {
  const AppSettings({
    required this.name,
    required this.currency,
    required this.currencyDecimals,
    required this.locale,
    required this.timezone,
    required this.vatRate,
    required this.pricesIncludeVat,
    required this.vatNumber,
    this.appointmentGraceMinutes,
    this.loyaltyEnabled = false,
    this.loyaltyWashesRequired = 10,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    name: json['name'] as String,
    currency: json['currency'] as String,
    currencyDecimals: json['currency_decimals'] as int,
    locale: json['locale'] as String,
    timezone: json['timezone'] as String,
    vatRate: (json['vat_rate'] as num).toDouble(),
    pricesIncludeVat: json['prices_include_vat'] as bool,
    vatNumber: json['vat_number'] as String?,
    appointmentGraceMinutes: json['appointment_grace_minutes'] as int?,
    loyaltyEnabled: json['loyalty_enabled'] as bool? ?? false,
    loyaltyWashesRequired: json['loyalty_washes_required'] as int? ?? 10,
  );

  final String name;

  /// ISO 4217 code; amounts are integers in its minor unit (BHD: fils, 3 decimals).
  final String currency;
  final int currencyDecimals;
  final String locale;
  final String timezone;

  /// Percentage, e.g. 10.0.
  final double vatRate;
  final bool pricesIncludeVat;
  final String? vatNumber;

  /// Minutes after its time a booked car may still come before the booking becomes a no-show; null leaves late
  /// bookings to the staff.
  final int? appointmentGraceMinutes;

  /// The loyalty card: a stamp for each paid visit, and a free wash after [loyaltyWashesRequired] of them.
  final bool loyaltyEnabled;
  final int loyaltyWashesRequired;
}
