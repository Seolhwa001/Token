import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/core/token_converter.dart';
import 'package:token/features/transaction/transaction.dart';

void main() {
  test('13855 won at 100 won per TOKEN becomes 138.55 TOKEN', () {
    final amount = wonToToken(
      won: BigInt.from(13855),
      exchangeRate: ExchangeRate.fromInt(100),
    );
    expect(amount.toStorageString(), '138.55');
  });

  test('HALF_UP works with decimal exchange rate', () {
    final amount = wonToToken(
      won: BigInt.from(1),
      exchangeRate: ExchangeRate.parse('160.00'),
    );
    expect(amount.toStorageString(), '0.01');
  });

  test('transaction freezes its applied exchange rate', () {
    final transaction = TokenTransaction(
      id: 'transaction-1',
      resourceId: 'resource-1',
      wonAmount: BigInt.from(13855),
      tokenAmount: TokenAmount.parse('138.55'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      memo: '점심',
      createdAt: DateTime.utc(2026, 8, 7),
    );

    final restored = TokenTransaction.fromJson(transaction.toJson());

    expect(restored.tokenAmount.toStorageString(), '138.55');
    expect(restored.appliedExchangeRate.toStorageString(), '100.00');
  });

  test('resource balance may become negative', () {
    final before = TokenAmount.parse('20.00');
    final spent = TokenAmount.parse('30.00');
    expect((before - spent).toStorageString(), '-10.00');
  });
}
