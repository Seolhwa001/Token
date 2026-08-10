import '../../core/token_amount.dart';
import '../classification/classification.dart';
import '../ledger/ledger_entry.dart';
import '../transaction/transaction.dart';

class ResourceTransactionView {
  final TokenTransaction transaction;
  final TokenAmount effectiveConsumption;
  final bool fullyRefunded;
  final bool partiallyRefunded;

  const ResourceTransactionView({
    required this.transaction,
    required this.effectiveConsumption,
    required this.fullyRefunded,
    required this.partiallyRefunded,
  });
}

class ResourceDetailSnapshot {
  final TokenAmount balance;
  final TokenAmount granted;
  final TokenAmount effectiveConsumption;
  final List<ResourceTransactionView> transactions;

  const ResourceDetailSnapshot({
    required this.balance,
    required this.granted,
    required this.effectiveConsumption,
    required this.transactions,
  });
}

class ResourceDetailQuery {
  const ResourceDetailQuery();

  ResourceDetailSnapshot build({
    required String resourceId,
    required List<TokenTransaction> transactions,
    required List<ClassificationResult> classifications,
    required List<LedgerEntry> ledger,
  }) {
    var balanceMinor = BigInt.zero;
    var grantedMinor = BigInt.zero;
    var consumptionMinor = BigInt.zero;
    final items = <ResourceTransactionView>[];

    for (final entry in ledger) {
      if (entry.ledgerType != LedgerType.resource ||
          entry.resourceId != resourceId) continue;
      balanceMinor += entry.amount.minorUnits;
      if (entry.type == LedgerEntryType.initialGrant ||
          entry.type == LedgerEntryType.migrationOpening) {
        grantedMinor += entry.amount.minorUnits;
      }
    }

    for (final tx in transactions) {
      final current = _current(tx.id, classifications);
      if (current?.resourceId != resourceId) continue;

      var netMinor = BigInt.zero;
      var hadRefund = false;
      for (final entry in ledger) {
        if (entry.transactionId == tx.id &&
            entry.ledgerType == LedgerType.resource &&
            entry.resourceId == resourceId) {
          netMinor += entry.amount.minorUnits;
          if (entry.type == LedgerEntryType.refund) {hadRefund = true;
        }
      }

      final effectiveMinor = netMinor.isNegative ? -netMinor : BigInt.zero;
      final effective = TokenAmount.fromMinorUnits(effectiveMinor);
      consumptionMinor += effectiveMinor;
      items.add(ResourceTransactionView(
        transaction: tx,
        effectiveConsumption: effective,
        fullyRefunded: effectiveMinor == BigInt.zero,
        partiallyRefunded: hadRefund && effectiveMinor > BigInt.zero,
      ));
    }

    items.sort((a, b) =>
        b.transaction.occurredAt.compareTo(a.transaction.occurredAt));

    return ResourceDetailSnapshot(
      balance: TokenAmount.fromMinorUnits(balanceMinor),
      granted: TokenAmount.fromMinorUnits(grantedMinor),
      effectiveConsumption: TokenAmount.fromMinorUnits(consumptionMinor),
      transactions: List.unmodifiable(items),
    );
  }

  ClassificationResult? _current(
    String transactionId,
    List<ClassificationResult> classifications,
  ) {
    final history = classifications
        .where((c) => c.transactionId == transactionId)
        .toList();
    if (history.isEmpty) return null;
    history.sort((a, b) {
      final t = a.createdAt.compareTo(b.createdAt);
      return t != 0 ? t : a.id.compareTo(b.id);
    });
    return history.last;
  }
}
