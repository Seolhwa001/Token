import '../../core/token_amount.dart';
import '../classification/classification.dart';
import '../classification/classification_repository.dart';
import '../classification/rule_engine.dart';
import '../classification/rule_repository.dart';
import '../ledger/ledger_entry.dart';
import '../ledger/ledger_repository.dart';
import 'lifecycle_event.dart';
import 'lifecycle_repository.dart';
import 'transaction.dart';
import 'transaction_repository.dart';

class PipelineResult {
  final ClassificationResult classification;
  final List<LedgerEntry> ledger;

  const PipelineResult({
    required this.classification,
    required this.ledger,
  });
}

class TransactionPipeline {
  final TransactionRepository transactionRepository;
  final ClassificationRepository classificationRepository;
  final LedgerRepository ledgerRepository;
  final LifecycleRepository lifecycleRepository;
  final RuleEngine ruleEngine;
  final RuleRepository? ruleRepository;

  const TransactionPipeline({
    required this.transactionRepository,
    required this.classificationRepository,
    required this.ledgerRepository,
    required this.lifecycleRepository,
    required this.ruleEngine,
    this.ruleRepository,
  });

  Future<PipelineResult> submit(
    TokenTransaction transaction, {
    String? userResourceId,
  }) async {
    await transactionRepository.append(transaction);
    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.newTransaction,
    );

    final ClassificationResult classification;

    if (userResourceId != null) {
      final now = DateTime.now();

      classification = ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-user-classification',
        transactionId: transaction.id,
        status: ClassificationStatus.userClassified,
        resourceId: userResourceId,
        createdAt: now,
      );
    } else {
      final repository = ruleRepository;

      if (repository == null) {
        classification = ruleEngine.classify(transaction);
      } else {
        final rules = await repository.listEnabled();
        classification = ruleEngine.classifyWithRules(
          transaction,
          rules,
        );
      }
    }

    await classificationRepository.append(classification);

    if (!classification.isClassified) {
      final entry = LedgerEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}-unclassified',
        ledgerType: LedgerType.unclassified,
        amount: -transaction.tokenAmount,
        type: LedgerEntryType.purchase,
        description:
            transaction.merchant.isEmpty ? '미분류 거래' : transaction.merchant,
        transactionId: transaction.id,
        createdAt: transaction.occurredAt,
      );

      final ledger = await ledgerRepository.append(entry);

      await _lifecycle(
        transaction.id,
        TransactionLifecycleState.ledgerCreated,
      );
      await _lifecycle(
        transaction.id,
        TransactionLifecycleState.analyzed,
      );

      return PipelineResult(
        classification: classification,
        ledger: ledger,
      );
    }

    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.classified,
    );

    final entry = LedgerEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-purchase',
      ledgerType: LedgerType.resource,
      resourceId: classification.resourceId!,
      amount: -transaction.tokenAmount,
      type: LedgerEntryType.purchase,
      description:
          transaction.merchant.isEmpty ? '거래' : transaction.merchant,
      transactionId: transaction.id,
      createdAt: transaction.occurredAt,
    );

    final ledger = await ledgerRepository.append(entry);

    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.ledgerCreated,
    );
    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.analyzed,
    );

    return PipelineResult(
      classification: classification,
      ledger: ledger,
    );
  }

  Future<List<LedgerEntry>> classifyPending({
    required TokenTransaction transaction,
    required String resourceId,
  }) async {
    final ledger = await ledgerRepository.loadAll();

    final unclassifiedDebit = _latestEffectiveDebit(
      transactionId: transaction.id,
      ledger: ledger,
      requiredLedgerType: LedgerType.unclassified,
    );

    if (unclassifiedDebit == null) {
      throw StateError(
        'UNCLASSIFIED Ledger entry not found for transaction.',
      );
    }

    final now = DateTime.now();

    await classificationRepository.append(
      ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-pending-classification',
        transactionId: transaction.id,
        status: ClassificationStatus.userClassified,
        resourceId: resourceId,
        createdAt: now,
      ),
    );

    final unclassifiedReverse = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-unclassified-reversal',
      ledgerType: LedgerType.unclassified,
      amount: TokenAmount.fromMinorUnits(
        unclassifiedDebit.amount.minorUnits.abs(),
      ),
      type: LedgerEntryType.reversal,
      description: '분류 처리 역분개 · ${unclassifiedDebit.description}',
      transactionId: transaction.id,
      reversesLedgerEntryId: unclassifiedDebit.id,
      createdAt: now,
    );

    final resourceEntry = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-resource-classification',
      ledgerType: LedgerType.resource,
      resourceId: resourceId,
      amount: -transaction.tokenAmount,
      type: LedgerEntryType.reclassification,
      description: unclassifiedDebit.description,
      transactionId: transaction.id,
      createdAt: now,
    );

    final updated = await ledgerRepository.appendAll(
      [unclassifiedReverse, resourceEntry],
    );

    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.classified,
    );
    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.reclassified,
    );

    return updated;
  }

  Future<List<LedgerEntry>> refund(TokenTransaction transaction) async {
    final ledger = await ledgerRepository.loadAll();

    final effective = _latestEffectiveDebit(
      transactionId: transaction.id,
      ledger: ledger,
    );

    if (effective == null) {
      throw StateError('Refund target Ledger entry not found.');
    }

    final now = DateTime.now();

    final refund = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-refund',
      ledgerType: effective.ledgerType,
      resourceId: effective.resourceId,
      amount: TokenAmount.fromMinorUnits(
        effective.amount.minorUnits.abs(),
      ),
      type: LedgerEntryType.refund,
      description: '환불 · ${effective.description}',
      transactionId: transaction.id,
      reversesLedgerEntryId: effective.id,
      createdAt: now,
    );

    final updated = await ledgerRepository.append(refund);

    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.refunded,
    );

    return updated;
  }

  Future<List<LedgerEntry>> reclassify({
    required TokenTransaction transaction,
    required String newResourceId,
  }) async {
    final ledger = await ledgerRepository.loadAll();

    final effective = _latestEffectiveDebit(
      transactionId: transaction.id,
      ledger: ledger,
    );

    if (effective == null) {
      throw StateError('Reclassification target Ledger entry not found.');
    }

    if (effective.ledgerType == LedgerType.unclassified) {
      return classifyPending(
        transaction: transaction,
        resourceId: newResourceId,
      );
    }

    if (effective.ledgerType != LedgerType.resource ||
        effective.resourceId == null) {
      throw StateError(
        'SYSTEM Ledger cannot be Resource-reclassified.',
      );
    }

    final now = DateTime.now();

    final reversal = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-reversal',
      ledgerType: LedgerType.resource,
      resourceId: effective.resourceId,
      amount: TokenAmount.fromMinorUnits(
        effective.amount.minorUnits.abs(),
      ),
      type: LedgerEntryType.reversal,
      description: '재분류 역분개 · ${effective.description}',
      transactionId: transaction.id,
      reversesLedgerEntryId: effective.id,
      createdAt: now,
    );

    final replacement = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-reclassification',
      ledgerType: LedgerType.resource,
      resourceId: newResourceId,
      amount: -transaction.tokenAmount,
      type: LedgerEntryType.reclassification,
      description: effective.description,
      transactionId: transaction.id,
      createdAt: now,
    );

    await classificationRepository.append(
      ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-reclassification-result',
        transactionId: transaction.id,
        status: ClassificationStatus.userClassified,
        resourceId: newResourceId,
        createdAt: now,
      ),
    );

    final updated = await ledgerRepository.appendAll(
      [reversal, replacement],
    );

    await _lifecycle(
      transaction.id,
      TransactionLifecycleState.reclassified,
    );

    return updated;
  }

  LedgerEntry? _latestEffectiveDebit({
    required String transactionId,
    required List<LedgerEntry> ledger,
    LedgerType? requiredLedgerType,
  }) {
    final candidates = ledger.where((entry) {
      if (entry.transactionId != transactionId) return false;
      if (!entry.amount.isNegative) return false;

      if (requiredLedgerType != null &&
          entry.ledgerType != requiredLedgerType) {
        return false;
      }

      return entry.type == LedgerEntryType.purchase ||
          entry.type == LedgerEntryType.reclassification;
    }).toList();

    for (final candidate in candidates.reversed) {
      final reversed = ledger.any(
        (entry) => entry.reversesLedgerEntryId == candidate.id,
      );

      if (!reversed) return candidate;
    }

    return null;
  }

  Future<void> _lifecycle(
    String transactionId,
    TransactionLifecycleState state,
  ) {
    final now = DateTime.now();

    return lifecycleRepository.append(
      TransactionLifecycleEvent(
        id: '${now.microsecondsSinceEpoch}-${state.name}',
        transactionId: transactionId,
        state: state,
        createdAt: now,
      ),
    );
  }
}
