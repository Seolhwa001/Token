import '../../core/token_amount.dart';

class Resource {
  final String id;
  final String name;
  final TokenAmount balance;
  final String colorKey;
  final DateTime createdAt;

  const Resource({
    required this.id,
    required this.name,
    required this.balance,
    required this.colorKey,
    required this.createdAt,
  });

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance.toStorageString(),
      'colorKey': colorKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Resource.fromJson(Map<String, Object?> json) {
    return Resource(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: TokenAmount.parse(json['balance'] as String),
      colorKey: json['colorKey'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
