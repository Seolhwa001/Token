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

  test('transaction freezes exchange rate and has no Resource classification', () {
    final transaction = TokenTransaction(
      id: 'transaction-1',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(13855),
      tokenAmount: TokenAmount.parse('138.55'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '맥도날드',
      memo: '점심',
      occurredAt: DateTime.utc(2026, 8, 7, 12),
      createdAt: DateTime.utc(2026, 8, 7, 12),
    );

    final restored = TokenTransaction.fromJson(transaction.toJson());

    expect(restored.source, TransactionSource.manual);
    expect(restored.tokenAmount.toStorageString(), '138.55');
    expect(restored.appliedExchangeRate.toStorageString(), '100.00');
    expect(restored.merchant, '맥도날드');
    expect(restored.occurredAt, DateTime.utc(2026, 8, 7, 12));
  });

  test('same Transaction shape supports future source types', () {
    final transaction = TokenTransaction(
      id: 'transaction-toss',
      source: TransactionSource.toss,
      sourceExternalId: 'toss-123',
      wonAmount: BigInt.from(5000),
      tokenAmount: TokenAmount.parse('50.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '편의점',
      memo: '',
      occurredAt: DateTime.utc(2026, 8, 7, 18),
      createdAt: DateTime.utc(2026, 8, 7, 18),
    );

    expect(transaction.source, TransactionSource.toss);
    expect(transaction.sourceExternalId, 'toss-123');
  });
}
