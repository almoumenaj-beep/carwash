import 'package:carwash_app/core/money/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bhdArabic = MoneyFormat(currency: 'BHD', decimals: 3, languageCode: 'ar');
  const bhdEnglish = MoneyFormat(currency: 'BHD', decimals: 3, languageCode: 'en');

  test('formats fils as dinars with three decimals', () {
    expect(bhdArabic.format(2500), '2.500 د.ب');
    expect(bhdEnglish.format(2500), 'BHD 2.500');
    expect(bhdEnglish.format(5), 'BHD 0.005');
    expect(bhdEnglish.format(1234567), 'BHD 1,234.567');
    expect(bhdEnglish.format(-1500), 'BHD -1.500');
  });

  test('parses typed amounts into fils', () {
    expect(bhdEnglish.parse('2.5'), 2500);
    expect(bhdEnglish.parse('2.500'), 2500);
    expect(bhdEnglish.parse('2'), 2000);
    expect(bhdEnglish.parse(' 1,250.75 '), 1250750);
    expect(bhdEnglish.parse('0.005'), 5);
  });

  test('accepts Arabic-Indic digits and separators', () {
    expect(bhdArabic.parse('٢٫٥'), 2500);
    expect(bhdArabic.parse('١٥'), 15000);
  });

  test('rejects anything that is not an amount in this currency', () {
    expect(bhdEnglish.parse(''), isNull);
    expect(bhdEnglish.parse('abc'), isNull);
    expect(bhdEnglish.parse('-1'), isNull);
    expect(bhdEnglish.parse('1.2345'), isNull, reason: 'BHD has only three decimals');
  });

  test('round-trips through the editable form', () {
    expect(bhdEnglish.toInput(2500), '2.500');
    expect(bhdEnglish.parse(bhdEnglish.toInput(1234567)), 1234567);
  });

  test('handles two-decimal and zero-decimal currencies', () {
    const usd = MoneyFormat(currency: 'USD', decimals: 2, languageCode: 'en');
    const jpy = MoneyFormat(currency: 'JPY', decimals: 0, languageCode: 'en');

    expect(usd.format(1999), 'USD 19.99');
    expect(usd.parse('19.9'), 1990);
    expect(jpy.format(1500), 'JPY 1,500');
    expect(jpy.parse('1.5'), isNull);
  });
}
