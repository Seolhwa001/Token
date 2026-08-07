import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/exchange_rate.dart';
import '../../core/token_amount.dart';
import '../classification/classification.dart';
import '../classification/classification_repository.dart';
import '../ledger/ledger_entry.dart';
import '../ledger/ledger_repository.dart';
import '../resource/resource.dart';
import '../resource/resource_repository.dart';
import '../transaction/lifecycle_event.dart';
import '../transaction/lifecycle_repository.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_repository.dart';

class PipelineMigration {
  static const _flag = 'token.pipeline.v2.migrated';

  Future<void> runIfNeeded() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_flag) == true) return;

    final newResources = await ResourceRepository().loadAll();
    final newTransactions = await TransactionRepository().list();

    if (newResources.isNotEmpty || newTransactions.isNotEmpty) {
      await preferences.setBool(_flag, true);
      return;
    }

    final legacyResourceRaw = preferences.getString('token.resources.v1');
    final legacyTransactionRaw =
        preferences.getString('token.transactions.v1');

    if (legacyResourceRaw == null || legacyResourceRaw.isEmpty) {
      await preferences.setBool(_flag, true);
      return;
    }

    final legacyResources = jsonDecode(legacyResourceRaw) as List<dynamic>;
    final legacyTransactions =
        legacyTransactionRaw == null || legacyTransactionRaw.isEmpty
            ? <dynamic>[]
            : jsonDecode(legacyTransactionRaw) as List<dynamic>;

    final resources = <Resource>[];
    final transactions = <TokenTransaction>[];
    final classifications = <ClassificationResult>[];
    final ledger = <LedgerEntry>[];
    final lifecycle = <TransactionLifecycleEvent>[];

    final spendByResource = <String, TokenAmount>{};

    for (final item in legacyTransactions) {
      final map = Map<String, Object?>.from(item as Map);
      final resourceId = map['resourceId'] as String;
      final tokenAmount = TokenAmount.parse(map['tokenAmount'] as String);
      final existing =
          spendByResource[resourceId] ?? TokenAmount.fromMinorUnits(BigInt.zero);
      spendByResource[resourceId] = existing + tokenAmount;
    }

    for (final item in legacyResources) {
      final map = Map<String, Object?>.from(item as Map);
      final id = map['id'] as String;
      final currentBalance = TokenAmount.parse(map['balance'] as String);
      final historicalSpend =
          spendByResource[id] ?? TokenAmount.fromMinorUnits(BigInt.zero);
      final opening = currentBalance + historicalSpend;
      final createdAt = DateTime.parse(map['createdAt'] as String);

      resources.add(
        Resource(
          id: id,
          name: map['name'] as String,
          colorKey: map['colorKey'] as String,
          createdAt: createdAt,
        ),
      );

      if (!opening.isZero) {
        ledger.add(
          LedgerEntry(
            id: 'migration-opening-$id',
            resourceId: id,
            amount: opening,
            type: LedgerEntryType.migrationOpening,
            description: '기존 자원 초기 잔액 마이그레이션',
            createdAt: createdAt,
          ),
        );
      }
    }

    for (final item in legacyTransactions) {
      final map = Map<String, Object?>.from(item as Map);
      final id = map['id'] as String;
      final resourceId = map['resourceId'] as String;
      final tokenAmount = TokenAmount.parse(map['tokenAmount'] as String);
      final createdAt = DateTime.parse(map['createdAt'] as String);

      final transaction = TokenTransaction(
        id: id,
        source: TransactionSource.manual,
        wonAmount: BigInt.parse(map['wonAmount'] as String),
        tokenAmount: tokenAmount,
        appliedExchangeRate:
            ExchangeRate.parse(map['appliedExchangeRate'] as String),
        merchant: '',
        memo: (map['memo'] as String?) ?? '',
        occurredAt: createdAt,
        createdAt: createdAt,
      );
      transactions.add(transaction);

      classifications.add(
        ClassificationResult(
          id: 'migration-classification-$id',
          transactionId: id,
          status: ClassificationStatus.userClassified,
          resourceId: resourceId,
          createdAt: createdAt,
        ),
      );

      ledger.add(
        LedgerEntry(
          id: 'migration-purchase-$id',
          resourceId: resourceId,
          amount: -tokenAmount,
          type: LedgerEntryType.purchase,
          description:
              transaction.memo.isEmpty ? '기존 거래' : transaction.memo,
          transactionId: id,
          createdAt: createdAt,
        ),
      );

      for (final state in [
        TransactionLifecycleState.newTransaction,
        TransactionLifecycleState.classified,
        TransactionLifecycleState.ledgerCreated,
        TransactionLifecycleState.analyzed,
      ]) {
        lifecycle.add(
          TransactionLifecycleEvent(
            id: 'migration-${state.name}-$id',
            transactionId: id,
            state: state,
            createdAt: createdAt,
          ),
        );
      }
    }

    await ResourceRepository().saveAll(resources);
    await TransactionRepository().seedIfEmpty(transactions);
    await ClassificationRepository().seedIfEmpty(classifications);
    await LedgerRepository().seedIfEmpty(ledger);
    await LifecycleRepository().saveAll(lifecycle);

    await preferences.setBool(_flag, true);
  }
}
