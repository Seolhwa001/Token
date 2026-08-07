import '../../core/token_amount.dart';

enum LedgerEntryType {
  initialGrant,
  purchase,
  refund,
  reversal,
  reclassification,
  migrationOpening,
}

class LedgerEntry {
  final String id;
  final String resourceId;
  final TokenAmount amount;
  final LedgerEntryType type;
  final String description;
  final String? transactionId;
  final String? reversesLedgerEntryId;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.resourceId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.transactionId,
    this.reversesLedgerEntryId,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'resourceId': resourceId,
        'amount': amount.toStorageString(),
        'type': type.name,
        'description': description,
        'transactionId': transactionId,
        'reversesLedgerEntryId': reversesLedgerEntryId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LedgerEntry.fromJson(Map<String, Object?> json) => LedgerEntry(
        id: json['id'] as String,
        resourceId: json['resourceId'] as String,
        amount: TokenAmount.parse(json['amount'] as String),
        type: LedgerEntryType.values.byName(json['type'] as String),
        description: (json['description'] as String?) ?? '',
        transactionId: json['transactionId'] as String?,
        reversesLedgerEntryId: json['reversesLedgerEntryId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
