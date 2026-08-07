import '../../core/token_amount.dart';

class RefundRecord {
  final String id;
  final String transactionId;
  final BigInt wonAmount;
  final TokenAmount tokenAmount;
  final String ledgerEntryId;
  final DateTime createdAt;

  const RefundRecord({
    required this.id,
    required this.transactionId,
    required this.wonAmount,
    required this.tokenAmount,
    required this.ledgerEntryId,
    required this.createdAt,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'wonAmount': wonAmount.toString(),
        'tokenAmount': tokenAmount.toStorageString(),
        'ledgerEntryId': ledgerEntryId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RefundRecord.fromJson(Map<String, Object?> json) {
    return RefundRecord(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      wonAmount: BigInt.parse(json['wonAmount'] as String),
      tokenAmount: TokenAmount.parse(json['tokenAmount'] as String),
      ledgerEntryId: json['ledgerEntryId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
