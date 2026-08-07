import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/classification/classification_repository.dart';
import 'package:token/features/classification/classification_rule.dart';
import 'package:token/features/classification/rule_engine.dart';
import 'package:token/features/classification/rule_repository.dart';
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

  test('enabled persisted rule AUTO_CLASSIFIES transaction and creates RESOURCE Ledger',
      () async {
    final ruleRepository = RuleRepository();
    final now = DateTime.utc(2026, 8, 7);

    await ruleRepository.insert(
      ClassificationRule(
        id: 'rule-mcd',
        priority: 1,
        includeKeywords: const ['맥도날드'],
        resourceId: 'food',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final pipeline = TransactionPipeline(
      transactionRepository: TransactionRepository(),
      classificationRepository: ClassificationRepository(),
      ledgerRepository: LedgerRepository(),
      lifecycleRepository: LifecycleRepository(),
      ruleEngine: const RuleEngine(),
      ruleRepository: ruleRepository,
    );

    final transaction = TokenTransaction(
      id: 'tx-auto',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(13500),
      tokenAmount: TokenAmount.parse('135.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '맥도날드 강남점',
      memo: '',
      occurredAt: now,
      createdAt: now,
    );

    final result = await pipeline.submit(transaction);

    expect(
      result.classification.status,
      ClassificationStatus.autoClassified,
    );
    expect(result.classification.resourceId, 'food');
    expect(result.classification.ruleId, 'rule-mcd');

    expect(result.ledger, hasLength(1));
    expect(result.ledger.single.ledgerType, LedgerType.resource);
    expect(result.ledger.single.resourceId, 'food');
    expect(result.ledger.single.amount.toStorageString(), '-135.00');

    final current =
        await ClassificationRepository().getCurrent(transaction.id);

    expect(current!.status, ClassificationStatus.autoClassified);
  });

  test('no persisted rule match creates UNCLASSIFIED Ledger', () async {
    final ruleRepository = RuleRepository();

    final pipeline = TransactionPipeline(
      transactionRepository: TransactionRepository(),
      classificationRepository: ClassificationRepository(),
      ledgerRepository: LedgerRepository(),
      lifecycleRepository: LifecycleRepository(),
      ruleEngine: const RuleEngine(),
      ruleRepository: ruleRepository,
    );

    final now = DateTime.utc(2026, 8, 7);

    final transaction = TokenTransaction(
      id: 'tx-no-match',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(5000),
      tokenAmount: TokenAmount.parse('50.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '알 수 없는 상점',
      memo: '',
      occurredAt: now,
      createdAt: now,
    );

    final result = await pipeline.submit(transaction);

    expect(
      result.classification.status,
      ClassificationStatus.unclassified,
    );

    expect(result.ledger.single.ledgerType, LedgerType.unclassified);
    expect(result.ledger.single.resourceId, isNull);
  });

  test('disabled persisted rule is not used by pipeline', () async {
    final ruleRepository = RuleRepository();
    final now = DateTime.utc(2026, 8, 7);

    await ruleRepository.insert(
      ClassificationRule(
        id: 'disabled-rule',
        enabled: false,
        priority: 1,
        includeKeywords: const ['맥도날드'],
        resourceId: 'food',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final pipeline = TransactionPipeline(
      transactionRepository: TransactionRepository(),
      classificationRepository: ClassificationRepository(),
      ledgerRepository: LedgerRepository(),
      lifecycleRepository: LifecycleRepository(),
      ruleEngine: const RuleEngine(),
      ruleRepository: ruleRepository,
    );

    final transaction = TokenTransaction(
      id: 'tx-disabled',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(10000),
      tokenAmount: TokenAmount.parse('100.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: '맥도날드',
      memo: '',
      occurredAt: now,
      createdAt: now,
    );

    final result = await pipeline.submit(transaction);

    expect(
      result.classification.status,
      ClassificationStatus.unclassified,
    );
  });
}
