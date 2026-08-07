import '../../core/token_amount.dart';
import 'ledger_entry.dart';

class LedgerCalculator {
  const LedgerCalculator();

  TokenAmount balanceForResource(
    String resourceId,
    List<LedgerEntry> ledger,
  ) {
    final minor = ledger
        .where(
          (entry) =>
              entry.ledgerType == LedgerType.resource &&
              entry.resourceId == resourceId,
        )
        .fold<BigInt>(
          BigInt.zero,
          (sum, entry) => sum + entry.amount.minorUnits,
        );

    return TokenAmount.fromMinorUnits(minor);
  }
}
