import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/classification/classification_repository.dart';
import 'package:token/features/classification/classification_rule.dart';
import 'package:token/features/classification/rule_repository.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/ledger/ledger_repository.dart';
import 'package:token/features/refund/refund_record.dart';
import 'package:token/features/refund/refund_repository.dart';
import 'package:token/features/transaction/transaction.dart';
import 'package:token/features/transaction/transaction_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('TransactionRepository insert/get/list preserves immutable object',
      () async {
    final repository = TransactionRepository();
    final transaction = TokenTransaction(
      id: 'tx-1',
      source: TransactionSource.manual,
      wonAmount: BigInt.from(13500),
      tokenAmount: TokenAmount.parse('135.00'),
      appliedExchangeRate: ExchangeRate.parse('100.00'),
      merchant: 'McDonald',
      memo: '',
      occurredAt: DateTime.utc(2026, 8, 7),
      createdAt: DateTime.utc(2026, 8, 7),
    );

    await repository.insert(transaction);

    expect((await repository.get('tx-1'))!.toJson(), transaction.toJson());
    expect(await repository.list(), hasLength(1));

    await expectLater(
      repository.insert(transaction),
      throwsA(isA<StateError>()),
    );
  });

  test('ClassificationRepository is append-only and returns current/history',
      () async {
    final repository = ClassificationRepository();

    final first = ClassificationResult(
      id: 'c-1',
      transactionId: 'tx-1',
      status: ClassificationStatus.unclassified,
      createdAt: DateTime.utc(2026, 8, 7, 10),
    );
    final second = ClassificationResult(
      id: 'c-2',
      transactionId: 'tx-1',
      status: ClassificationStatus.userClassified,
      resourceId: 'food',
      createdAt: DateTime.utc(2026, 8, 7, 11),
    );

    await repository.append(first);
    await repository.append(second);

    expect(await repository.getHistory('tx-1'), hasLength(2));
    expect((await repository.getCurrent('tx-1'))!.id, 'c-2');
  });

  test('LedgerRepository exposes append/list contracts', () async {
    final repository = LedgerRepository();

    await repository.append(
      LedgerEntry(
        id: 'l-1',
        ledgerType: LedgerType.resource,
        resourceId: 'food',
        amount: TokenAmount.parse('-135.00'),
        type: LedgerEntryType.purchase,
        description: 'McDonald',
        transactionId: 'tx-1',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    );

    expect(await repository.listByTransaction('tx-1'), hasLength(1));
    expect(await repository.listByResource('food'), hasLength(1));
  });

  test('RuleRepository rejects duplicate priority', () async {
    final repository = RuleRepository();
    final now = DateTime.utc(2026, 8, 7);

    await repository.insert(
      ClassificationRule(
        id: 'r-1',
        priority: 10,
        includeKeywords: const ['맥도날드'],
        resourceId: 'food',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await expectLater(
      repository.insert(
        ClassificationRule(
          id: 'r-2',
          priority: 10,
          includeKeywords: const ['버거킹'],
          resourceId: 'food',
          createdAt: now,
          updatedAt: now,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('RuleRepository disable/update/softDelete behavior', () async {
    final repository = RuleRepository();
    final now = DateTime.utc(2026, 8, 7);

    final rule = ClassificationRule(
      id: 'r-1',
      priority: 1,
      includeKeywords: const ['GS칼텍스'],
      excludeKeywords: const ['상품권'],
      resourceId: 'vehicle',
      createdAt: now,
      updatedAt: now,
    );

    await repository.insert(rule);
    expect(await repository.listEnabled(), hasLength(1));

    await repository.update(
      rule.copyWith(
        enabled: false,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    expect(await repository.listEnabled(), isEmpty);

    await repository.update(
      rule.copyWith(
        enabled: true,
        updatedAt: now.add(const Duration(minutes: 2)),
      ),
    );
    expect(await repository.listEnabled(), hasLength(1));

    await repository.softDelete('r-1');
    expect(await repository.listEnabled(), isEmpty);

    final all = await repository.listAllIncludingDeleted();
    expect(all.single.deleted, isTrue);
    expect(all.single.enabled, isFalse);
  });

  test('RefundRepository is append-only and lists by transaction', () async {
    final repository = RefundRepository();

    final record = RefundRecord(
      id: 'refund-1',
      transactionId: 'tx-1',
      wonAmount: BigInt.from(5000),
      tokenAmount: TokenAmount.parse('50.00'),
      ledgerEntryId: 'ledger-refund-1',
      createdAt: DateTime.utc(2026, 8, 7),
    );

    await repository.append(record);

    final records = await repository.listByTransaction('tx-1');
    expect(records, hasLength(1));
    expect(records.single.toJson(), record.toJson());

    await expectLater(
      repository.append(record),
      throwsA(isA<StateError>()),
    );
  });
}
