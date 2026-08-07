import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/transaction/transaction.dart';
import 'package:token/features/unclassified/unclassified_inspector_page.dart';

TokenTransaction _transaction(String id) {
  return TokenTransaction(
    id: id,
    source: TransactionSource.manual,
    wonAmount: BigInt.from(13500),
    tokenAmount: TokenAmount.parse('135.00'),
    appliedExchangeRate: ExchangeRate.parse('100.00'),
    merchant: '테스트 가맹점',
    memo: '',
    occurredAt: DateTime.utc(2026, 8, 7, 12),
    createdAt: DateTime.utc(2026, 8, 7, 12),
  );
}

void main() {
  test('effective UNCLASSIFIED Ledger appears in inspector', () {
    final tx = _transaction('tx-1');
    final ledger = [
      LedgerEntry(
        id: 'u-1',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: '테스트 가맹점',
        transactionId: tx.id,
        createdAt: tx.occurredAt,
      ),
    ];

    final result = pendingUnclassifiedTransactions(
      transactions: [tx],
      ledger: ledger,
    );

    expect(result, hasLength(1));
    expect(result.single.id, tx.id);
  });

  test('reversed UNCLASSIFIED Ledger disappears from inspector', () {
    final tx = _transaction('tx-2');
    final ledger = [
      LedgerEntry(
        id: 'u-2',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: '테스트 가맹점',
        transactionId: tx.id,
        createdAt: tx.occurredAt,
      ),
      LedgerEntry(
        id: 'u-2-reverse',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('135.00'),
        type: LedgerEntryType.reversal,
        description: '분류 처리 역분개',
        transactionId: tx.id,
        reversesLedgerEntryId: 'u-2',
        createdAt: DateTime.utc(2026, 8, 7, 13),
      ),
      LedgerEntry(
        id: 'resource-2',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.reclassification,
        description: '테스트 가맹점',
        transactionId: tx.id,
        createdAt: DateTime.utc(2026, 8, 7, 13),
      ),
    ];

    final result = pendingUnclassifiedTransactions(
      transactions: [tx],
      ledger: ledger,
    );

    expect(result, isEmpty);
  });

  test('RESOURCE transaction never appears as unclassified', () {
    final tx = _transaction('tx-3');
    final ledger = [
      LedgerEntry(
        id: 'resource-3',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: '테스트 가맹점',
        transactionId: tx.id,
        createdAt: tx.occurredAt,
      ),
    ];

    final result = pendingUnclassifiedTransactions(
      transactions: [tx],
      ledger: ledger,
    );

    expect(result, isEmpty);
  });
}
