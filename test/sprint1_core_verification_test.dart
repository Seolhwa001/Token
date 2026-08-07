import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/analytics/ledger_analytics.dart';
import 'package:token/features/classification/classification_repository.dart';
import 'package:token/features/classification/rule_engine.dart';
import 'package:token/features/ledger/ledger_calculator.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/ledger/ledger_repository.dart';
import 'package:token/features/transaction/lifecycle_repository.dart';
import 'package:token/features/transaction/transaction.dart';
import 'package:token/features/transaction/transaction_pipeline.dart';
import 'package:token/features/transaction/transaction_repository.dart';

TokenTransaction _tx({
  required String id,
  required String merchant,
  ExchangeRate? rate,
}) {
  final applied = rate ?? ExchangeRate.parse('100.00');
  return TokenTransaction(
    id: id,
    source: TransactionSource.manual,
    wonAmount: BigInt.from(13500),
    tokenAmount: TokenAmount.parse('135.00'),
    appliedExchangeRate: applied,
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

  test('Reverse Ledger keeps original record and appends refund', () async {
    final pipeline = _pipeline();
    final tx = _tx(id: 'refund-1', merchant: 'McDonald');

    final submitted = await pipeline.submit(
      tx,
      userResourceId: 'food',
    );

    expect(submitted.ledger, hasLength(1));

    final original = submitted.ledger.single;
    final originalJson = original.toJson();

    final afterRefund = await pipeline.refund(tx);

    expect(afterRefund, hasLength(2));

    // Historical Ledger remains byte-for-byte equivalent at domain level.
    expect(afterRefund.first.toJson(), originalJson);

    final refund = afterRefund.last;
    expect(refund.type, LedgerEntryType.refund);
    expect(refund.ledgerType, LedgerType.resource);
    expect(refund.resourceId, 'food');
    expect(refund.amount.toStorageString(), '135.00');
    expect(refund.reversesLedgerEntryId, original.id);

    final balance = const LedgerCalculator().balanceForResource(
      'food',
      afterRefund,
    );
    expect(balance.toStorageString(), '0.00');

    final consumption = const LedgerAnalytics().totalConsumption(
      ledger: afterRefund,
    );
    expect(consumption.toStorageString(), '0.00');
  });

  test('Reclassification preserves original and appends reverse + replacement',
      () async {
    final pipeline = _pipeline();
    final tx = _tx(id: 'reclass-1', merchant: 'Fuel');

    final submitted = await pipeline.submit(
      tx,
      userResourceId: 'food',
    );

    final original = submitted.ledger.single;
    final originalJson = original.toJson();

    final after = await pipeline.reclassify(
      transaction: tx,
      newResourceId: 'vehicle',
    );

    expect(after, hasLength(3));

    // Original remains unchanged.
    expect(after[0].toJson(), originalJson);

    final reverse = after[1];
    expect(reverse.ledgerType, LedgerType.resource);
    expect(reverse.resourceId, 'food');
    expect(reverse.amount.toStorageString(), '135.00');
    expect(reverse.reversesLedgerEntryId, original.id);

    final replacement = after[2];
    expect(replacement.ledgerType, LedgerType.resource);
    expect(replacement.resourceId, 'vehicle');
    expect(replacement.amount.toStorageString(), '-135.00');

    final foodBalance = const LedgerCalculator().balanceForResource(
      'food',
      after,
    );
    final vehicleBalance = const LedgerCalculator().balanceForResource(
      'vehicle',
      after,
    );

    expect(foodBalance.toStorageString(), '0.00');
    expect(vehicleBalance.toStorageString(), '-135.00');

    // Reclassification must not double-count total consumption.
    final total = const LedgerAnalytics().totalConsumption(ledger: after);
    expect(total.toStorageString(), '135.00');
  });

  test('Resource Balance is reconstructed only from RESOURCE Ledger', () {
    final ledger = [
      LedgerEntry(
        id: 'grant-food',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('500.00'),
        type: LedgerEntryType.initialGrant,
        description: 'grant',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'purchase-food',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: 'purchase',
        transactionId: 'tx-food',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'unclassified',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-80.00'),
        type: LedgerEntryType.purchase,
        description: 'unknown',
        transactionId: 'tx-unclassified',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final balance = const LedgerCalculator().balanceForResource(
      'food',
      ledger,
    );

    expect(balance.toStorageString(), '365.00');
  });

  test('Analytics uses RESOURCE + UNCLASSIFIED and excludes SYSTEM', () {
    final ledger = [
      LedgerEntry(
        id: 'resource',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-100.00'),
        type: LedgerEntryType.purchase,
        description: 'food',
        transactionId: 'tx-resource',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'unclassified',
        ledgerType: LedgerType.unclassified,
        amount: TokenAmount.parse('-80.00'),
        type: LedgerEntryType.purchase,
        description: 'unknown',
        transactionId: 'tx-unclassified',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'system',
        ledgerType: LedgerType.system,
        amount: TokenAmount.parse('-999.00'),
        type: LedgerEntryType.purchase,
        description: 'system',
        transactionId: 'tx-system',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final total = const LedgerAnalytics().totalConsumption(ledger: ledger);
    expect(total.toStorageString(), '180.00');
  });

  test('Persistence restores reverse Ledger and balances identically',
      () async {
    final pipeline = _pipeline();
    final tx = _tx(id: 'persist-refund', merchant: 'Shop');

    await pipeline.submit(tx, userResourceId: 'food');
    final beforeRestart = await pipeline.refund(tx);

    final balanceBefore = const LedgerCalculator().balanceForResource(
      'food',
      beforeRestart,
    );
    final analyticsBefore = const LedgerAnalytics().totalConsumption(
      ledger: beforeRestart,
    );

    // Simulated app restart: construct new repository instances and reload
    // solely from persisted SharedPreferences data.
    final reloadedLedger = await LedgerRepository().loadAll();
    final reloadedTransactions = await TransactionRepository().loadAll();

    expect(
      reloadedLedger.map((entry) => entry.toJson()).toList(),
      beforeRestart.map((entry) => entry.toJson()).toList(),
    );
    expect(reloadedTransactions, hasLength(1));

    final balanceAfter = const LedgerCalculator().balanceForResource(
      'food',
      reloadedLedger,
    );
    final analyticsAfter = const LedgerAnalytics().totalConsumption(
      ledger: reloadedLedger,
    );

    expect(balanceAfter, balanceBefore);
    expect(analyticsAfter, analyticsBefore);
  });

  test('Persistence restores reclassification identically', () async {
    final pipeline = _pipeline();
    final tx = _tx(id: 'persist-reclass', merchant: 'Fuel');

    await pipeline.submit(tx, userResourceId: 'food');
    final beforeRestart = await pipeline.reclassify(
      transaction: tx,
      newResourceId: 'vehicle',
    );

    final reloadedLedger = await LedgerRepository().loadAll();

    expect(
      reloadedLedger.map((entry) => entry.toJson()).toList(),
      beforeRestart.map((entry) => entry.toJson()).toList(),
    );

    expect(
      const LedgerCalculator()
          .balanceForResource('food', reloadedLedger)
          .toStorageString(),
      '0.00',
    );
    expect(
      const LedgerCalculator()
          .balanceForResource('vehicle', reloadedLedger)
          .toStorageString(),
      '-135.00',
    );
  });

  test('Historical appliedExchangeRate and Ledger do not change when default rate changes',
      () async {
    final historicalRate = ExchangeRate.parse('100.00');
    final tx = _tx(
      id: 'rate-1',
      merchant: 'Historical Shop',
      rate: historicalRate,
    );

    final pipeline = _pipeline();
    final submitted = await pipeline.submit(
      tx,
      userResourceId: 'food',
    );

    final historicalLedgerJson =
        submitted.ledger.map((entry) => entry.toJson()).toList();

    // Simulate changing the app's current/default rate.
    final newDefaultRate = ExchangeRate.parse('200.00');
    expect(newDefaultRate.toStorageString(), '200.00');

    final reloadedTx = (await TransactionRepository().loadAll()).single;
    final reloadedLedger = await LedgerRepository().loadAll();

    expect(
      reloadedTx.appliedExchangeRate.toStorageString(),
      '100.00',
    );
    expect(reloadedTx.tokenAmount.toStorageString(), '135.00');
    expect(
      reloadedLedger.map((entry) => entry.toJson()).toList(),
      historicalLedgerJson,
    );
  });
}
