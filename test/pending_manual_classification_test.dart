import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/classification/classification_repository.dart';
import 'package:token/features/classification/rule_engine.dart';
import 'package:token/features/ledger/ledger_calculator.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/ledger/ledger_repository.dart';
import 'package:token/features/transaction/lifecycle_repository.dart';
import 'package:token/features/transaction/transaction.dart';
import 'package:token/features/transaction/transaction_pipeline.dart';
import 'package:token/features/transaction/transaction_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Manual pending classification appends reverse + RESOURCE + Classification',
      () async {
    final pipeline = TransactionPipeline(
      transactionRepository: TransactionRepository(),
      classificationRepository: ClassificationRepository(),
      ledgerRepository: LedgerRepository(),
      lifecycleRepository: LifecycleRepository(),
      ruleEngine: const RuleEngine(),
    );

    final now = DateTime.utc(2026, 8, 7);

    final transaction = TokenTransaction(
      id: 'pending-1',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(13500),
      tokenAmount: TokenAmount.parse('135.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '맥도날드',
      memo: '',
      occurredAt: now,
      createdAt: now,
    );

    final submitted = await pipeline.submit(transaction);

    expect(
      submitted.classification.status,
      ClassificationStatus.unclassified,
    );
    expect(submitted.ledger.single.ledgerType, LedgerType.unclassified);

    final original = submitted.ledger.single;

    final after = await pipeline.classifyPending(
      transaction: transaction,
      resourceId: 'food',
    );

    expect(after, hasLength(3));

    expect(after[0].id, original.id);
    expect(after[0].amount.toStorageString(), '-135.00');

    expect(after[1].ledgerType, LedgerType.unclassified);
    expect(after[1].amount.toStorageString(), '135.00');
    expect(after[1].reversesLedgerEntryId, original.id);

    expect(after[2].ledgerType, LedgerType.resource);
    expect(after[2].resourceId, 'food');
    expect(after[2].amount.toStorageString(), '-135.00');

    final current =
        await ClassificationRepository().getCurrent(transaction.id);

    expect(current!.status, ClassificationStatus.userClassified);
    expect(current.resourceId, 'food');

    final foodBalance = const LedgerCalculator().balanceForResource(
      'food',
      after,
    );

    expect(foodBalance.toStorageString(), '-135.00');
  });
}
