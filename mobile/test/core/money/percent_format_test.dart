import 'package:carwash_app/core/money/percent_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('basis points are shown as a short percentage', () {
    expect(PercentFormat.format(1000), '10');
    expect(PercentFormat.format(1250), '12.5');
    expect(PercentFormat.format(1205), '12.05');
    expect(PercentFormat.format(0), '0');
    expect(PercentFormat.format(10000), '100');
  });

  test('typed percentages become basis points, Arabic digits included', () {
    expect(PercentFormat.parse('10'), 1000);
    expect(PercentFormat.parse('12.5'), 1250);
    expect(PercentFormat.parse(' 7% '), 700);
    expect(PercentFormat.parse('١٢٫٥'), 1250);
  });

  test('anything that is not a percentage from 0 to 100 is refused', () {
    expect(PercentFormat.parse(''), isNull);
    expect(PercentFormat.parse('100.5'), isNull);
    expect(PercentFormat.parse('12.345'), isNull);
    expect(PercentFormat.parse('-5'), isNull);
    expect(PercentFormat.parse('abc'), isNull);
  });
}
