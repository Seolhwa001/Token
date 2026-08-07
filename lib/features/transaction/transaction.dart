import '../../core/exchange_rate.dart';
import '../../core/token_amount.dart';

class TokenTransaction {
  final String id;
  final String resourceId;
  final BigInt wonAmount;
  final TokenAmount tokenAmount;
  final ExchangeRate appliedExchangeRate;
  final String memo;
  final DateTime createdAt;

  const TokenTransaction({
    required this.id,
    required this.resourceId,
    required this.wonAmount,
    required this.tokenAmount,
    required this.appliedExchangeRate,
    required this.memo,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'wonAmount': wonAmount.toString(),
        'tokenAmount': tokenAmount.toStorageString(),
        'appliedExchangeRate': appliedExchangeRate.toStorageString(),
        'memo': memo,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TokenTransaction.fromJson(Map<String, Object?> json) {
    return TokenTransaction(
      id: json['id'] as String,
      resourceId: json['resourceId'] as String,
      wonAmount: BigInt.parse(json['wonAmount'] as String),
      tokenAmount: TokenAmount.parse(json['tokenAmount'] as String),
      appliedExchangeRate:
          ExchangeRate.parse(json['appliedExchangeRate'] as String),
      memo: (json['memo'] as String?) ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
