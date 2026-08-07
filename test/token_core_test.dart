import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/core/token_converter.dart';

void main() {
  group('TokenAmount', () {
    test('storage preserves scale=2', () {
      expect(TokenAmount.fromInt(138).toStorageString(), '138.00');
    });

    test('display removes trailing zeros only', () {
      expect(TokenAmount.parse('120.00').toDisplayString(), '120');
      expect(TokenAmount.parse('138.50').toDisplayString(), '138.5');
      expect(TokenAmount.parse('138.55').toDisplayString(), '138.55');
    });

    test('negative TOKEN is allowed', () {
      expect(TokenAmount.parse('-7.25').isNegative, isTrue);
    });
  });

  group('KRW conversion', () {
    test('uses HALF_UP at scale 2', () {
      // 13,855 / 100 = 138.55
      final result = wonToToken(
        won: BigInt.from(13855),
        exchangeRate: ExchangeRate.fromInt(100),
      );
      expect(result.toStorageString(), '138.55');
    });

    test('rounds third decimal HALF_UP', () {
      // 100 / 32 = 3.125 -> 3.13
      final result = wonToToken(
        won: BigInt.from(100),
        exchangeRate: ExchangeRate.fromInt(32),
      );
      expect(result.toStorageString(), '3.13');
    });
  });
}
