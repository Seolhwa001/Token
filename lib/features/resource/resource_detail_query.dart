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
          entry.resourceId != resourceId) {
        continue;
      }

      balanceMinor += entry.amount.minorUnits;

      if (entry.type == LedgerEntryType.initialGrant ||
          entry.type == LedgerEntryType.migrationOpening) {
        grantedMinor += entry.amount.minorUnits;
      }
    }

    for (final transaction in transactions) {
      final current = _current(
        transaction.id,
        classifications,
      );

      if (current?.resourceId != resourceId) {
        continue;
      }

      var netMinor = BigInt.zero;
      var hadRefund = false;

      for (final entry in ledger) {
        if (entry.transactionId == transaction.id &&
            entry.ledgerType == LedgerType.resource &&
            entry.resourceId == resourceId) {
          netMinor += entry.amount.minorUnits;

          if (entry.type == LedgerEntryType.refund) {
            hadRefund = true;
          }
        }
      }

      final effectiveMinor =
          netMinor.isNegative ? -netMinor : BigInt.zero;

      consumptionMinor += effectiveMinor;

      items.add(
        ResourceTransactionView(
          transaction: transaction,
          effectiveConsumption:
              TokenAmount.fromMinorUnits(effectiveMinor),
          fullyRefunded: effectiveMinor == BigInt.zero,
          partiallyRefunded:
              hadRefund && effectiveMinor > BigInt.zero,
        ),
      );
    }

    items.sort(
      (a, b) => b.transaction.occurredAt.compareTo(
        a.transaction.occurredAt,
      ),
    );

    return ResourceDetailSnapshot(
      balance: TokenAmount.fromMinorUnits(balanceMinor),
      granted: TokenAmount.fromMinorUnits(grantedMinor),
      effectiveConsumption:
          TokenAmount.fromMinorUnits(consumptionMinor),
      transactions: List.unmodifiable(items),
    );
  }

  ClassificationResult? _current(
    String transactionId,
    List<ClassificationResult> classifications,
  ) {
    final history = classifications
        .where(
          (classification) =>
              classification.transactionId == transactionId,
        )
        .toList();

    if (history.isEmpty) {
      return null;
    }

    history.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);

      if (byTime != 0) {
        return byTime;
      }

      return a.id.compareTo(b.id);
    });

    return history.last;
  }
}
