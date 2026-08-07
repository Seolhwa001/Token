import 'exchange_rate.dart';
import 'token_amount.dart';

class Resource {
  final String id;
  final String name;
  final TokenAmount balance;

  const Resource({
    required this.id,
    required this.name,
    required this.balance,
  });

  Resource copyWith({TokenAmount? balance}) => Resource(
        id: id,
        name: name,
        balance: balance ?? this.balance,
      );
}

class TokenTransaction {
  final String id;
  final DateTime paidAt;
  final BigInt wonAmount;
  final TokenAmount tokenAmount;
  final ExchangeRate appliedExchangeRate;
  final String? merchant;
  final String? resourceId;

  const TokenTransaction({
    required this.id,
    required this.paidAt,
    required this.wonAmount,
    required this.tokenAmount,
    required this.appliedExchangeRate,
    this.merchant,
    this.resourceId,
  });
}
