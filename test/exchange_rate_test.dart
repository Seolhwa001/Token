import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/exchange_rate.dart';

void main() {
  test('exchange rate is fixed-point scale 2', () {
    final rate = ExchangeRate.parse('99.5');
    expect(rate.toStorageString(), '99.50');
    expect(rate.toDisplayString(), '99.5');
  });

  test('integer exchange rate remains compatible', () {
    final rate = ExchangeRate.fromInt(100);
    expect(rate.toStorageString(), '100.00');
    expect(rate.toDisplayString(), '100');
  });
}
