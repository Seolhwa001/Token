import '../../core/token_amount.dart';

enum LedgerType {
  resource,
  unclassified,
  system,
}

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
  final LedgerType ledgerType;
  final String? resourceId;
  final TokenAmount amount;
  final LedgerEntryType type;
  final String description;
  final String? transactionId;
  final String? reversesLedgerEntryId;
  final DateTime createdAt;

  const LedgerEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.ledgerType = LedgerType.resource,
    this.resourceId,
    this.transactionId,
    this.reversesLedgerEntryId,
  }) : assert(
          ledgerType != LedgerType.resource || resourceId != null,
          'RESOURCE Ledger requires resourceId.',
        );

  Map<String, Object?> toJson() => {
        'id': id,
        'ledgerType': ledgerType.name,
        'resourceId': resourceId,
        'amount': amount.toStorageString(),
        'type': type.name,
        'description': description,
        'transactionId': transactionId,
        'reversesLedgerEntryId': reversesLedgerEntryId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LedgerEntry.fromJson(Map<String, Object?> json) {
    final storedLedgerType = json['ledgerType'] as String?;
    final ledgerType = storedLedgerType == null
        ? LedgerType.resource
        : LedgerType.values.byName(storedLedgerType);

    return LedgerEntry(
      id: json['id'] as String,
      ledgerType: ledgerType,
      resourceId: json['resourceId'] as String?,
      amount: TokenAmount.parse(json['amount'] as String),
      type: LedgerEntryType.values.byName(json['type'] as String),
      description: (json['description'] as String?) ?? '',
      transactionId: json['transactionId'] as String?,
      reversesLedgerEntryId: json['reversesLedgerEntryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
