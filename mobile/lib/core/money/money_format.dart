import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_repository.dart';
import '../l10n/locale_controller.dart';

/// Formats and parses amounts kept as integers in the currency's minor unit.
///
/// BHD has 3 decimals (1 dinar = 1000 fils): 2500 ⇄ "2.500". Integer arithmetic only, so no rounding drift.
class MoneyFormat {
  const MoneyFormat({required this.currency, required this.decimals, required this.languageCode});

  /// Arabic currency symbols for Gulf currencies; others are shown by ISO code.
  static const _arabicSymbols = {'BHD': 'د.ب', 'SAR': 'ر.س', 'KWD': 'د.ك', 'AED': 'د.إ', 'OMR': 'ر.ع', 'QAR': 'ر.ق'};

  final String currency;
  final int decimals;
  final String languageCode;

  int get _factor {
    var factor = 1;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    return factor;
  }

  /// The amount without currency, e.g. "1,234.500".
  String formatNumber(int minor) {
    final sign = minor < 0 ? '-' : '';
    final absolute = minor.abs();
    final whole = (absolute ~/ _factor).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    if (decimals == 0) {
      return '$sign$whole';
    }
    final fraction = (absolute % _factor).toString().padLeft(decimals, '0');
    return '$sign$whole.$fraction';
  }

  /// The amount with currency for display: "2.500 د.ب" in Arabic, "BHD 2.500" in English.
  String format(int minor) {
    final number = formatNumber(minor);
    final arabicSymbol = _arabicSymbols[currency];
    return languageCode == 'ar' && arabicSymbol != null ? '$number $arabicSymbol' : '$currency $number';
  }

  /// The amount typed by a user, as minor units; null when it is not a valid amount.
  /// Accepts Arabic-Indic digits and separators ("٢٫٥" → 2500).
  int? parse(String input) {
    final normalised = input
        .trim()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .replaceAllMapped(RegExp('[٠-٩]'), (match) => '${match[0]!.codeUnitAt(0) - 0x0660}');

    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(normalised);
    if (match == null) {
      return null;
    }

    final fraction = match[2] ?? '';
    if (fraction.length > decimals) {
      return null;
    }

    return int.parse(match[1]!) * _factor + (fraction.isEmpty ? 0 : int.parse(fraction.padRight(decimals, '0')));
  }

  /// The minor amount as editable text without grouping, e.g. 2500 → "2.500".
  String toInput(int minor) => formatNumber(minor).replaceAll(',', '');
}

/// The money format of the signed-in car wash, falling back to BHD until settings load.
final moneyFormatProvider = Provider<MoneyFormat>((ref) {
  final settings = ref.watch(settingsProvider).value;
  return MoneyFormat(
    currency: settings?.currency ?? 'BHD',
    decimals: settings?.currencyDecimals ?? 3,
    languageCode: ref.watch(localeProvider).languageCode,
  );
});
