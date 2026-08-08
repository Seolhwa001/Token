import 'package:flutter_test/flutter_test.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/pending/pending_queue_page.dart';
import 'package:token/features/transaction/transaction.dart';

TokenTransaction _tx(String id) => TokenTransaction(
      id: id,
      source: TransactionSource.manual,
      wonAmount: BigInt.from(5000),
      tokenAmount: TokenAmount.parse('50.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '냑',
      memo: '',
      occurredAt: DateTime.utc(2026, 8, 8, 9, 30),
      createdAt: DateTime.utc(2026, 8, 8, 9, 30),
    );

ClassificationResult _unclassified(String id) => ClassificationResult(
      id: 'c-$id',
      transactionId: id,
      status: ClassificationStatus.unclassified,
      createdAt: DateTime.utc(2026, 8, 8, 9, 30),
    );

LedgerEntry _unclassifiedLedger({
  required String id,
  required String txId,
  required String amount,
  LedgerEntryType type = LedgerEntryType.purchase,
}) =>
    LedgerEntry(
      id: id,
      ledgerType: LedgerType.unclassified,
      amount: TokenAmount.parse(amount),
      type: type,
      description: 'test',
      transactionId: txId,
      createdAt: DateTime.utc(2026, 8, 8, 9, 30),
    );

void main() {
  test('fully refunded UNCLASSIFIED transaction is excluded from Pending Queue',
      () {
    final tx = _tx('full');
    final ledger = [
      _unclassifiedLedger(id: 'purchase', txId: tx.id, amount: '-50.00'),
      _unclassifiedLedger(
        id: 'refund',
        txId: tx.id,
        amount: '50.00',
        type: LedgerEntryType.refund,
      ),
    ];

    final pending = pendingTransactionsFromCurrentClassification(
      transactions: [tx],
      classifications: [_unclassified(tx.id)],
      ledger: ledger,
    );

    expect(pending, isEmpty);
    expect(
      effectiveUnclassifiedTokenForTransaction(
        transactionId: tx.id,
        ledger: ledger,
      ).toStorageString(),
      '0.00',
    );
  });

  test('partially refunded UNCLASSIFIED transaction remains with only remainder',
      () {
    final tx = _tx('partial');
    final ledger = [
      _unclassifiedLedger(id: 'purchase', txId: tx.id, amount: '-50.00'),
      _unclassifiedLedger(
        id: 'refund',
        txId: tx.id,
        amount: '20.00',
        type: LedgerEntryType.refund,
      ),
    ];

    final pending = pendingTransactionsFromCurrentClassification(
      transactions: [tx],
      classifications: [_unclassified(tx.id)],
      ledger: ledger,
    );

    expect(pending.map((e) => e.id), ['partial']);
    expect(
      effectiveUnclassifiedTokenForTransaction(
        transactionId: tx.id,
        ledger: ledger,
      ).toStorageString(),
      '30.00',
    );
  });
}
