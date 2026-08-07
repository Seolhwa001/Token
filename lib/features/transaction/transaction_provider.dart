import '../../core/exchange_rate.dart';
import '../../core/token_converter.dart';
import 'transaction.dart';

abstract class TransactionProvider {
  TransactionSource get source;

  TokenTransaction create({
    required String id,
    required BigInt wonAmount,
    required ExchangeRate exchangeRate,
    required String merchant,
    required String memo,
    required DateTime occurredAt,
    String? sourceExternalId,
  }) => TokenTransaction(
        id: id,
        source: source,
        sourceExternalId: sourceExternalId,
        wonAmount: wonAmount,
        tokenAmount: wonToToken(won: wonAmount, exchangeRate: exchangeRate),
        appliedExchangeRate: exchangeRate,
        merchant: merchant,
        memo: memo,
        occurredAt: occurredAt,
        createdAt: DateTime.now(),
      );
}

class ManualTransactionProvider extends TransactionProvider {
  @override
  TransactionSource get source => TransactionSource.manual;
}
