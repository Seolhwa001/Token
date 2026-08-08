import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification_repository.dart';
import 'package:token/features/classification/rule_engine.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/ledger/ledger_repository.dart';
import 'package:token/features/refund/refund_repository.dart';
import 'package:token/features/transaction/lifecycle_repository.dart';
import 'package:token/features/transaction/transaction.dart';
import 'package:token/features/transaction/transaction_pipeline.dart';
import 'package:token/features/transaction/transaction_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  TransactionPipeline pipeline() => TransactionPipeline(
        transactionRepository: TransactionRepository(),
        classificationRepository: ClassificationRepository(),
        ledgerRepository: LedgerRepository(),
        lifecycleRepository: LifecycleRepository(),
        ruleEngine: const RuleEngine(),
        refundRepository: RefundRepository(),
      );

  TokenTransaction tx(String id) => TokenTransaction(
        id: id,
        source: TransactionSource.manual,
        wonAmount: BigInt.from(13500),
        tokenAmount: TokenAmount.parse('135.00'),
        appliedExchangeRate: ExchangeRate.parse('100.00'),
        merchant: '맥도날드',
        memo: '',
        occurredAt: DateTime.utc(2026, 8, 8),
        createdAt: DateTime.utc(2026, 8, 8),
      );

  test('partial refunds can be repeated up to remaining amount', () async {
    final p = pipeline();
    final transaction = tx('partial');

    await p.submit(transaction, userResourceId: 'food');
    await p.refundPartial(
      transaction: transaction,
      wonAmount: BigInt.from(5000),
    );
    await p.refundPartial(
      transaction: transaction,
      wonAmount: BigInt.from(8500),
    );

    final ledger = await LedgerRepository().listByTransaction(transaction.id);
    final refunds =
        ledger.where((e) => e.type == LedgerEntryType.refund).toList();

    expect(refunds, hasLength(2));
    expect(
      p.remainingTokenAmount(transaction, ledger).toStorageString(),
      '0.00',
    );
    expect(p.remainingWonAmount(transaction, ledger), BigInt.zero);
  });

  test('refund <= 0 is rejected', () async {
    final p = pipeline();
    final transaction = tx('invalid-zero');
    await p.submit(transaction, userResourceId: 'food');

    await expectLater(
      p.refundPartial(
        transaction: transaction,
        wonAmount: BigInt.zero,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('refund greater than remaining amount is rejected', () async {
    final p = pipeline();
    final transaction = tx('invalid-over');
    await p.submit(transaction, userResourceId: 'food');

    await p.refundPartial(
      transaction: transaction,
      wonAmount: BigInt.from(5000),
    );

    await expectLater(
      p.refundPartial(
        transaction: transaction,
        wonAmount: BigInt.from(9000),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('reclassification after partial refund moves only remaining TOKEN',
      () async {
    final p = pipeline();
    final transaction = tx('reclass-partial');

    await p.submit(transaction, userResourceId: 'food');
    await p.refundPartial(
      transaction: transaction,
      wonAmount: BigInt.from(5000),
    );
    await p.reclassify(
      transaction: transaction,
      newResourceId: 'vehicle',
    );

    final ledger = await LedgerRepository().listByTransaction(transaction.id);

    expect(ledger, hasLength(4));
    expect(ledger[0].resourceId, 'food');
    expect(ledger[0].amount.toStorageString(), '-135.00');

    expect(ledger[1].type, LedgerEntryType.refund);
    expect(ledger[1].resourceId, 'food');
    expect(ledger[1].amount.toStorageString(), '50.00');

    expect(ledger[2].type, LedgerEntryType.reversal);
    expect(ledger[2].resourceId, 'food');
    expect(ledger[2].amount.toStorageString(), '85.00');

    expect(ledger[3].type, LedgerEntryType.reclassification);
    expect(ledger[3].resourceId, 'vehicle');
    expect(ledger[3].amount.toStorageString(), '-85.00');
  });

  test('fully refunded transaction cannot be reclassified', () async {
    final p = pipeline();
    final transaction = tx('full-refund');

    await p.submit(transaction, userResourceId: 'food');
    await p.refund(transaction);

    await expectLater(
      p.reclassify(
        transaction: transaction,
        newResourceId: 'vehicle',
      ),
      throwsA(isA<StateError>()),
    );
  });
}
