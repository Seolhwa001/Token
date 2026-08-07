import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/analytics/ledger_analytics.dart';
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

TokenTransaction _transaction({
  String id = 'tx-1',
  String merchant = 'Unknown Shop',
}) {
  return TokenTransaction(
    id: id,
    source: TransactionSource.manual,
    wonAmount: BigInt.from(13500),
    tokenAmount: TokenAmount.parse('135.00'),
    appliedExchangeRate: ExchangeRate.parse('100.00'),
    merchant: merchant,
    memo: '',
    occurredAt: DateTime.utc(2026, 8, 7, 12),
    createdAt: DateTime.utc(2026, 8, 7, 12),
  );
}

TransactionPipeline _pipeline() {
  return TransactionPipeline(
    transactionRepository: TransactionRepository(),
    classificationRepository: ClassificationRepository(),
    ledgerRepository: LedgerRepository(),
    lifecycleRepository: LifecycleRepository(),
    ruleEngine: const RuleEngine(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('unclassified transaction generates UNCLASSIFIED Ledger', () async {
    final result = await _pipeline().submit(_transaction());

    expect(
      result.classification.status,
      ClassificationStatus.unclassified,
    );
    expect(result.ledger, hasLength(1));
    expect(result.ledger.single.ledgerType, LedgerType.unclassified);
    expect(result.ledger.single.resourceId, isNull);
    expect(result.ledger.single.amount.toStorageString(), '-135.00');
  });

  test('total consumption includes RESOURCE and UNCLASSIFIED but not SYSTEM',
      () {
    final ledger = [
      LedgerEntry(
        id: 'resource',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-100.00'),
        type: LedgerEntryType.purchase,
        description: 'Food',
        transactionId: 'tx-resource',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'unclassified',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-35.00'),
        type: LedgerEntryType.purchase,
        description: 'Unknown',
        transactionId: 'tx-unclassified',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'system',
        ledgerType: LedgerType.system,
        amount: TokenAmount.parse('-999.00'),
        type: LedgerEntryType.purchase,
        description: 'System',
        transactionId: 'tx-system',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final total =
        const LedgerAnalytics().totalConsumption(ledger: ledger);

    expect(total.toStorageString(), '135.00');
  });

  test('Resource Balance excludes UNCLASSIFIED Ledger', () {
    final ledger = [
      LedgerEntry(
        id: 'grant',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('500.00'),
        type: LedgerEntryType.initialGrant,
        description: 'Grant',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'unclassified',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: 'Unknown',
        transactionId: 'tx-1',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final balance =
        const LedgerCalculator().balanceForResource('food', ledger);

    expect(balance.toStorageString(), '500.00');
  });

  test('classification appends reverse UNCLASSIFIED and RESOURCE Ledger',
      () async {
    final pipeline = _pipeline();
    final tx = _transaction();

    final first = await pipeline.submit(tx);
    final original = first.ledger.single;

    final after = await pipeline.classifyPending(
      transaction: tx,
      resourceId: 'food',
    );

    expect(after, hasLength(3));

    expect(after[0].id, original.id);
    expect(after[0].ledgerType, LedgerType.unclassified);
    expect(after[0].amount.toStorageString(), '-135.00');

    expect(after[1].ledgerType, LedgerType.unclassified);
    expect(after[1].amount.toStorageString(), '135.00');
    expect(after[1].reversesLedgerEntryId, original.id);

    expect(after[2].ledgerType, LedgerType.resource);
    expect(after[2].resourceId, 'food');
    expect(after[2].amount.toStorageString(), '-135.00');

    final total =
        const LedgerAnalytics().totalConsumption(ledger: after);
    expect(total.toStorageString(), '135.00');
  });

  test('refund preserves UNCLASSIFIED Ledger Type', () async {
    final pipeline = _pipeline();
    final tx = _transaction();

    await pipeline.submit(tx);
    final after = await pipeline.refund(tx);

    expect(after, hasLength(2));
    expect(after[0].ledgerType, LedgerType.unclassified);
    expect(after[1].ledgerType, LedgerType.unclassified);
    expect(after[1].amount.toStorageString(), '135.00');

    final total =
        const LedgerAnalytics().totalConsumption(ledger: after);
    expect(total.toStorageString(), '0.00');
  });

  test('refund preserves RESOURCE Ledger Type', () async {
    final pipeline = _pipeline();
    final tx = _transaction(id: 'tx-resource');

    await pipeline.submit(tx, userResourceId: 'food');
    final after = await pipeline.refund(tx);

    expect(after, hasLength(2));
    expect(after[0].ledgerType, LedgerType.resource);
    expect(after[1].ledgerType, LedgerType.resource);
    expect(after[0].resourceId, 'food');
    expect(after[1].resourceId, 'food');
  });

  test('historical Ledger remains append-only during reclassification',
      () async {
    final pipeline = _pipeline();
    final tx = _transaction(id: 'tx-reclass');

    final before = await pipeline.submit(
      tx,
      userResourceId: 'food',
    );
    final original = before.ledger.single;

    final after = await pipeline.reclassify(
      transaction: tx,
      newResourceId: 'car',
    );

    expect(after, hasLength(3));
    expect(after[0].id, original.id);
    expect(after[0].resourceId, 'food');
    expect(after[0].amount.toStorageString(), '-135.00');

    expect(after[1].resourceId, 'food');
    expect(after[1].amount.toStorageString(), '135.00');

    expect(after[2].resourceId, 'car');
    expect(after[2].amount.toStorageString(), '-135.00');

    final food =
        const LedgerCalculator().balanceForResource('food', after);
    final car =
        const LedgerCalculator().balanceForResource('car', after);

    expect(food.toStorageString(), '0.00');
    expect(car.toStorageString(), '-135.00');
  });
}
