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
    this.pointsEnabled = false,
    this.pointsEarnAmount = 1000,
    this.pointsRedeemPoints = 100,
    this.pointsRedeemValue = 2000,
    this.pointsExpiryMonths,
    this.membershipsEnabled = false,
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
    pointsEnabled: json['points_enabled'] as bool? ?? false,
    pointsEarnAmount: json['points_earn_amount'] as int? ?? 1000,
    pointsRedeemPoints: json['points_redeem_points'] as int? ?? 100,
    pointsRedeemValue: json['points_redeem_value'] as int? ?? 2000,
    pointsExpiryMonths: json['points_expiry_months'] as int?,
    membershipsEnabled: json['memberships_enabled'] as bool? ?? false,
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

  /// Points: one is earned per [pointsEarnAmount] paid (minor units), [pointsRedeemPoints] of them take off
  /// [pointsRedeemValue] (minor units), and a balance lapses after [pointsExpiryMonths] without activity, or never.
  final bool pointsEnabled;
  final int pointsEarnAmount;
  final int pointsRedeemPoints;
  final int pointsRedeemValue;
  final int? pointsExpiryMonths;

  /// Whether memberships can be sold and used; the plans are set on their own screen.
  final bool membershipsEnabled;
}
