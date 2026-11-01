/// Percentages kept as integer basis points (1000 = 10%), as the server stores rates and limits.
abstract final class PercentFormat {
  /// 1000 → "10", 1250 → "12.5", 1205 → "12.05".
  static String format(int bps) {
    final whole = bps ~/ 100;
    final fraction = bps % 100;
    if (fraction == 0) {
      return '$whole';
    }
    return '$whole.${fraction.toString().padLeft(2, '0').replaceFirst(RegExp(r'0$'), '')}';
  }

  /// What a user typed ("12.5", "١٠") as basis points; null when it is not a percentage from 0 to 100
  /// with at most two decimals.
  static int? parse(String input) {
    final normalised = input
        .trim()
        .replaceAll('%', '')
        .replaceAll('٫', '.')
        .replaceAllMapped(RegExp('[٠-٩]'), (match) => '${match[0]!.codeUnitAt(0) - 0x0660}');

    final match = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$').firstMatch(normalised);
    if (match == null) {
      return null;
    }

    final bps = int.parse(match[1]!) * 100 + int.parse((match[2] ?? '0').padRight(2, '0'));
    return bps > 10000 ? null : bps;
  }
}
