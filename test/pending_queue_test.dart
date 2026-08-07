import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/pending/pending_queue_page.dart';
import 'package:token/features/resource/resource.dart';
import 'package:token/features/transaction/transaction.dart';

TokenTransaction _tx(String id, DateTime time) {
  return TokenTransaction(
    id: id,
    source: TransactionSource.manual,
    wonAmount: BigInt.from(13500),
    tokenAmount: TokenAmount.parse('135.00'),
    appliedExchangeRate: ExchangeRate.parse('100.00'),
    merchant: '맥도날드',
    memo: '',
    occurredAt: time,
    createdAt: time,
  );
}

void main() {
  test('Pending Queue derives from CURRENT Classification == UNCLASSIFIED', () {
    final t1 = _tx('t1', DateTime.utc(2026, 8, 7, 10));
    final t2 = _tx('t2', DateTime.utc(2026, 8, 7, 11));

    final classifications = [
      ClassificationResult(
        id: 'c1',
        transactionId: 't1',
        status: ClassificationStatus.unclassified,
        createdAt: DateTime.utc(2026, 8, 7, 10),
      ),
      ClassificationResult(
        id: 'c2',
        transactionId: 't1',
        status: ClassificationStatus.userClassified,
        resourceId: 'food',
        createdAt: DateTime.utc(2026, 8, 7, 12),
      ),
      ClassificationResult(
        id: 'c3',
        transactionId: 't2',
        status: ClassificationStatus.unclassified,
        createdAt: DateTime.utc(2026, 8, 7, 11),
      ),
    ];

    final pending = pendingTransactionsFromCurrentClassification(
      transactions: [t1, t2],
      classifications: classifications,
    );

    expect(pending.map((item) => item.id), ['t2']);
  });

  testWidgets('Pending Detail allows Resource selection and classification',
      (tester) async {
    final transaction = _tx('t1', DateTime.utc(2026, 8, 7, 10));

    String? selectedResource;

    await tester.pumpWidget(
      MaterialApp(
        home: PendingDetailPage(
          transaction: transaction,
          resources: [
            Resource(
              id: 'food',
              name: '식비',
              colorKey: 'teal',
              createdAt: DateTime.utc(2026, 8, 1),
            ),
          ],
          ledger: const <LedgerEntry>[],
          onClassify: (_, resourceId) async {
            selectedResource = resourceId;
          },
          onCreateSuggestedRule: (_, __) async {},
        ),
      ),
    );

    await tester.tap(find.text('자원을 선택하세요'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('식비').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('이 자원으로 분류'));
    await tester.pumpAndSettle();

    expect(find.text('자동분류 규칙 저장'), findsOneWidget);

    await tester.tap(find.text('아니오'));
    await tester.pumpAndSettle();

    expect(selectedResource, 'food');
  });
}
