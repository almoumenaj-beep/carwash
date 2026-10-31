import 'package:carwash_app/features/branches/domain/branch.dart';
import 'package:carwash_app/features/settings/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a branch with closed days, late closing and bays', () {
    final branch = Branch.fromJson({
      'id': 'b1',
      'name': 'Main Branch',
      'code': 'MAIN',
      'phone': null,
      'address': 'Manama',
      'is_active': true,
      'opening_hours': {
        'sat': {'opens': '08:00', 'closes': '22:00'},
        'thu': {'opens': '16:00', 'closes': '01:00'},
        'fri': null,
      },
      'bays': [
        {'id': 'bay1', 'branch_id': 'b1', 'name': 'Bay 1', 'sort_order': 0, 'is_active': true},
      ],
    });

    expect(branch.openingHours.keys, weekDays);
    expect(branch.openingHours['sat']!.closes, '22:00');
    expect(branch.openingHours['thu']!.closes, '01:00');
    expect(branch.openingHours['fri'], isNull);
    expect(branch.openingHours['mon'], isNull, reason: 'days missing from the payload are closed');
    expect(branch.bays.single.name, 'Bay 1');
  });

  test('day hours serialise back to the API shape', () {
    expect(DayHours.standard.copyWith(closes: '23:30').toJson(), {'opens': '08:00', 'closes': '23:30'});
  });

  test('reads Bahraini settings with a three-decimal currency', () {
    final settings = AppSettings.fromJson({
      'id': 't1',
      'name': 'Demo Car Wash',
      'currency': 'BHD',
      'currency_decimals': 3,
      'locale': 'ar',
      'timezone': 'Asia/Bahrain',
      'vat_rate': 10,
      'prices_include_vat': true,
      'vat_number': null,
    });

    expect(settings.currencyDecimals, 3);
    expect(settings.vatRate, 10.0);
    expect(settings.pricesIncludeVat, isTrue);
  });
}
