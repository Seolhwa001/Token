import '../../core/exchange_rate.dart';
import '../../core/token_amount.dart';

enum TransactionSource {
  manual,
  csv,
  excel,
  sms,
  notification,
  openBanking,
  myData,
  cardCompany,
  samsungWallet,
  toss,
  kakaoPay,
}

class TokenTransaction {
  final String id;
  final TransactionSource source;
  final String? sourceExternalId;
  final BigInt wonAmount;
  final TokenAmount tokenAmount;
  final ExchangeRate appliedExchangeRate;
  final String merchant;
  final String memo;
  final DateTime occurredAt;
  final DateTime createdAt;

  const TokenTransaction({
    required this.id,
    required this.source,
    required this.wonAmount,
    required this.tokenAmount,
    required this.appliedExchangeRate,
    required this.merchant,
    required this.memo,
    required this.occurredAt,
    required this.createdAt,
    this.sourceExternalId,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'source': source.name,
        'sourceExternalId': sourceExternalId,
        'wonAmount': wonAmount.toString(),
        'tokenAmount': tokenAmount.toStorageString(),
        'appliedExchangeRate': appliedExchangeRate.toStorageString(),
        'merchant': merchant,
        'memo': memo,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TokenTransaction.fromJson(Map<String, Object?> json) => TokenTransaction(
        id: json['id'] as String,
        source: TransactionSource.values.byName(json['source'] as String),
        sourceExternalId: json['sourceExternalId'] as String?,
        wonAmount: BigInt.parse(json['wonAmount'] as String),
        tokenAmount: TokenAmount.parse(json['tokenAmount'] as String),
        appliedExchangeRate: ExchangeRate.parse(json['appliedExchangeRate'] as String),
        merchant: (json['merchant'] as String?) ?? '',
        memo: (json['memo'] as String?) ?? '',
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
