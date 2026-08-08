import '../../core/token_amount.dart';
import '../../core/token_converter.dart';
import '../classification/classification.dart';
import '../classification/classification_repository.dart';
import '../classification/rule_engine.dart';
import '../classification/rule_repository.dart';
import '../ledger/ledger_entry.dart';
import '../ledger/ledger_repository.dart';
import '../refund/refund_record.dart';
import '../refund/refund_repository.dart';
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
  final RefundRepository? refundRepository;

  const TransactionPipeline({
    required this.transactionRepository,
    required this.classificationRepository,
    required this.ledgerRepository,
    required this.lifecycleRepository,
    required this.ruleEngine,
    this.ruleRepository,
    this.refundRepository,
  });

  Future<PipelineResult> submit(
    TokenTransaction transaction, {
    String? userResourceId,
  }) async {
    await transactionRepository.append(transaction);
    await _lifecycle(transaction.id, TransactionLifecycleState.newTransaction);

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
      classification = repository == null
          ? ruleEngine.classify(transaction)
          : ruleEngine.classifyWithRules(
              transaction,
              await repository.listEnabled(),
            );
    }

    await classificationRepository.append(classification);

    final entry = LedgerEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-purchase',
      ledgerType: classification.isClassified
          ? LedgerType.resource
          : LedgerType.unclassified,
      resourceId: classification.resourceId,
      amount: -transaction.tokenAmount,
      type: LedgerEntryType.purchase,
      description: transaction.merchant.isEmpty
          ? (classification.isClassified ? '거래' : '미분류 거래')
          : transaction.merchant,
      transactionId: transaction.id,
      createdAt: transaction.occurredAt,
    );

    final ledger = await ledgerRepository.append(entry);

    if (classification.isClassified) {
      await _lifecycle(transaction.id, TransactionLifecycleState.classified);
    }
    await _lifecycle(transaction.id, TransactionLifecycleState.ledgerCreated);
    await _lifecycle(transaction.id, TransactionLifecycleState.analyzed);

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
    final debit = _currentEffectiveDebit(
      transactionId: transaction.id,
      ledger: ledger,
      requiredLedgerType: LedgerType.unclassified,
    );
    if (debit == null) {
      throw StateError('UNCLASSIFIED Ledger entry not found for transaction.');
    }

    final remaining = remainingTokenAmount(transaction, ledger);
    if (remaining.isZero) {
      throw StateError('Fully refunded transaction cannot be classified.');
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

    final updated = await ledgerRepository.appendAll([
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-unclassified-reversal',
        ledgerType: LedgerType.unclassified,
        amount: remaining,
        type: LedgerEntryType.reversal,
        description: '분류 처리 역분개 · ${debit.description}',
        transactionId: transaction.id,
        reversesLedgerEntryId: debit.id,
        createdAt: now,
      ),
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-resource-classification',
        ledgerType: LedgerType.resource,
        resourceId: resourceId,
        amount: -remaining,
        type: LedgerEntryType.reclassification,
        description: debit.description,
        transactionId: transaction.id,
        createdAt: now,
      ),
    ]);

    await _lifecycle(transaction.id, TransactionLifecycleState.classified);
    await _lifecycle(transaction.id, TransactionLifecycleState.reclassified);
    return updated;
  }

  Future<List<LedgerEntry>> refund(TokenTransaction transaction) async {
    final ledger = await ledgerRepository.loadAll();
    final remainingWon = await _remainingWonForValidation(transaction, ledger);
    if (remainingWon <= BigInt.zero) {
      throw StateError('Transaction is already fully refunded.');
    }
    return refundPartial(
      transaction: transaction,
      wonAmount: remainingWon,
    );
  }

  Future<List<LedgerEntry>> refundPartial({
    required TokenTransaction transaction,
    required BigInt wonAmount,
  }) async {
    if (wonAmount <= BigInt.zero) {
      throw ArgumentError.value(wonAmount, 'wonAmount', 'Refund must be > 0.');
    }

    final ledger = await ledgerRepository.loadAll();
    final remainingWon = await _remainingWonForValidation(transaction, ledger);
    if (wonAmount > remainingWon) {
      throw StateError('Refund exceeds remaining effective amount.');
    }

    final refundToken = wonToToken(
      won: wonAmount,
      exchangeRate: transaction.appliedExchangeRate,
    );
    final remainingToken = remainingTokenAmount(transaction, ledger);
    if (refundToken.compareTo(remainingToken) > 0) {
      throw StateError('Refund TOKEN exceeds remaining effective TOKEN.');
    }

    final target = _currentEffectiveDebit(
      transactionId: transaction.id,
      ledger: ledger,
    );
    if (target == null) {
      throw StateError('Refund target Ledger entry not found.');
    }

    final now = DateTime.now();
    final entry = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-refund',
      ledgerType: target.ledgerType,
      resourceId: target.resourceId,
      amount: refundToken,
      type: LedgerEntryType.refund,
      description: '환불 · ${target.description}',
      transactionId: transaction.id,
      reversesLedgerEntryId: target.id,
      createdAt: now,
    );

    final updated = await ledgerRepository.append(entry);

    final repository = refundRepository;
    if (repository != null) {
      await repository.append(
        RefundRecord(
          id: '${now.microsecondsSinceEpoch}-refund-record',
          transactionId: transaction.id,
          wonAmount: wonAmount,
          tokenAmount: refundToken,
          ledgerEntryId: entry.id,
          createdAt: now,
        ),
      );
    }

    await _lifecycle(transaction.id, TransactionLifecycleState.refunded);
    return updated;
  }

  Future<List<LedgerEntry>> reclassify({
    required TokenTransaction transaction,
    required String newResourceId,
  }) async {
    final ledger = await ledgerRepository.loadAll();
    final remaining = remainingTokenAmount(transaction, ledger);
    if (remaining.isZero) {
      throw StateError('Fully refunded transaction cannot be reclassified.');
    }

    final effective = _currentEffectiveDebit(
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
      throw StateError('SYSTEM Ledger cannot be Resource-reclassified.');
    }
    if (effective.resourceId == newResourceId) {
      throw StateError('New Resource must differ from current Resource.');
    }

    final now = DateTime.now();

    await classificationRepository.append(
      ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-reclassification-result',
        transactionId: transaction.id,
        status: ClassificationStatus.userClassified,
        resourceId: newResourceId,
        createdAt: now,
      ),
    );

    final updated = await ledgerRepository.appendAll([
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-reversal',
        ledgerType: LedgerType.resource,
        resourceId: effective.resourceId,
        amount: remaining,
        type: LedgerEntryType.reversal,
        description: '재분류 역분개 · ${effective.description}',
        transactionId: transaction.id,
        reversesLedgerEntryId: effective.id,
        createdAt: now,
      ),
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-reclassification',
        ledgerType: LedgerType.resource,
        resourceId: newResourceId,
        amount: -remaining,
        type: LedgerEntryType.reclassification,
        description: effective.description,
        transactionId: transaction.id,
        createdAt: now,
      ),
    ]);

    await _lifecycle(transaction.id, TransactionLifecycleState.reclassified);
    return updated;
  }


  Future<BigInt> _remainingWonForValidation(
    TokenTransaction transaction,
    List<LedgerEntry> ledger,
  ) async {
    final repository = refundRepository;
    if (repository != null) {
      final records = await repository.listByTransaction(transaction.id);
      var refundedWon = BigInt.zero;
      for (final record in records) {
        refundedWon += record.wonAmount;
      }
      final remaining = transaction.wonAmount - refundedWon;
      return remaining.isNegative ? BigInt.zero : remaining;
    }

    return remainingWonAmount(transaction, ledger);
  }

  BigInt remainingWonAmount(
    TokenTransaction transaction,
    List<LedgerEntry> ledger,
  ) {
    final refundedMinor = _refundedTokenMinor(transaction.id, ledger);
    if (refundedMinor <= BigInt.zero) return transaction.wonAmount;

    final refundedWon =
        (refundedMinor * transaction.appliedExchangeRate.minorWonPerToken) ~/
            BigInt.from(10000);
    final remaining = transaction.wonAmount - refundedWon;
    return remaining.isNegative ? BigInt.zero : remaining;
  }

  TokenAmount remainingTokenAmount(
    TokenTransaction transaction,
    List<LedgerEntry> ledger,
  ) {
    final remaining =
        transaction.tokenAmount.minorUnits - _refundedTokenMinor(transaction.id, ledger);
    return TokenAmount.fromMinorUnits(
      remaining.isNegative ? BigInt.zero : remaining,
    );
  }

  BigInt _refundedTokenMinor(
    String transactionId,
    List<LedgerEntry> ledger,
  ) {
    var result = BigInt.zero;
    for (final entry in ledger) {
      if (entry.transactionId == transactionId &&
          entry.type == LedgerEntryType.refund &&
          !entry.amount.isNegative) {
        result += entry.amount.minorUnits;
      }
    }
    return result;
  }

  LedgerEntry? _currentEffectiveDebit({
    required String transactionId,
    required List<LedgerEntry> ledger,
    LedgerType? requiredLedgerType,
  }) {
    final candidates = ledger.where((entry) {
      if (entry.transactionId != transactionId || !entry.amount.isNegative) {
        return false;
      }
      if (requiredLedgerType != null &&
          entry.ledgerType != requiredLedgerType) {
        return false;
      }
      return entry.type == LedgerEntryType.purchase ||
          entry.type == LedgerEntryType.reclassification;
    }).toList(growable: false);

    for (final candidate in candidates.reversed) {
      final moved = ledger.any(
        (entry) =>
            entry.reversesLedgerEntryId == candidate.id &&
            entry.type == LedgerEntryType.reversal,
      );
      if (!moved) return candidate;
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
