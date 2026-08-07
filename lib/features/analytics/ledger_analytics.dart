import '../../core/token_amount.dart';
import '../ledger/ledger_entry.dart';

class LedgerAnalytics {
  const LedgerAnalytics();

  TokenAmount spentForResourceOnDay({
    required String resourceId,
    required DateTime day,
    required List<LedgerEntry> ledger,
  }) {
    final net = ledger.where((entry) {
      if (entry.resourceId != resourceId || !_sameDay(entry.createdAt, day)) {
        return false;
      }
      return entry.transactionId != null;
    }).fold<BigInt>(
      BigInt.zero,
      (sum, entry) => sum + entry.amount.minorUnits,
    );

    return TokenAmount.fromMinorUnits(net.isNegative ? net.abs() : BigInt.zero);
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
