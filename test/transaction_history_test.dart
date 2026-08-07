import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/history/transaction_history_page.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/resource/resource.dart';
import 'package:token/features/transaction/transaction.dart';

void main() {
  testWidgets('Transaction History shows formatted values and detail timeline',
      (tester) async {
    final when = DateTime.utc(2026, 8, 7, 18, 42);

    final tx = TokenTransaction(
      id: 'tx-1',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(13500),
      tokenAmount: TokenAmount.parse('135.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '맥도날드',
      memo: '',
      occurredAt: when,
      createdAt: when,
    );

    final classification = ClassificationResult(
      id: 'c-1',
      transactionId: tx.id,
      status: ClassificationStatus.userClassified,
      resourceId: 'food',
      createdAt: when,
    );

    final ledger = LedgerEntry(
      id: 'l-1',
      ledgerType: LedgerType.resource,
      resourceId: 'food',
      amount: TokenAmount.parse('-135.00'),
      type: LedgerEntryType.purchase,
      description: '맥도날드',
      transactionId: tx.id,
      createdAt: when,
    );

    final resource = Resource(
      id: 'food',
      name: '식비',
      colorKey: 'teal',
      createdAt: when,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionHistoryPage(
          transactions: [tx],
          classifications: [classification],
          ledger: [ledger],
          resources: [resource],
        ),
      ),
    );

    expect(find.text('13,500원'), findsOneWidget);
    expect(find.text('135 TOKEN'), findsOneWidget);
    expect(find.textContaining('식비'), findsOneWidget);

    await tester.tap(find.text('맥도날드'));
    await tester.pumpAndSettle();

    expect(find.text('거래 상세'), findsOneWidget);
    expect(find.text('Ledger 이력 (1)'), findsOneWidget);
    expect(find.text('분류 이력 (1)'), findsOneWidget);
    expect(find.text('환불 이력 (0)'), findsOneWidget);
  });
}
