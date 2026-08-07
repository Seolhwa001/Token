import '../../core/token_amount.dart';
import '../classification/classification.dart';
import '../classification/classification_repository.dart';
import '../classification/rule_engine.dart';
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

  const TransactionPipeline({
    required this.transactionRepository,
    required this.classificationRepository,
    required this.ledgerRepository,
    required this.lifecycleRepository,
    required this.ruleEngine,
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
      classification = ruleEngine.classify(transaction);
    }

    await classificationRepository.append(classification);

    if (!classification.isClassified) {
      return PipelineResult(
        classification: classification,
        ledger: await ledgerRepository.loadAll(),
      );
    }

    await _lifecycle(transaction.id, TransactionLifecycleState.classified);

    final entry = LedgerEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}-purchase',
      resourceId: classification.resourceId!,
      amount: -transaction.tokenAmount,
      type: LedgerEntryType.purchase,
      description: transaction.merchant.isEmpty ? '거래' : transaction.merchant,
      transactionId: transaction.id,
      createdAt: transaction.occurredAt,
    );

    final ledger = await ledgerRepository.append(entry);
    await _lifecycle(transaction.id, TransactionLifecycleState.ledgerCreated);
    await _lifecycle(transaction.id, TransactionLifecycleState.analyzed);

    return PipelineResult(classification: classification, ledger: ledger);
  }

  Future<List<LedgerEntry>> classifyPending({
    required TokenTransaction transaction,
    required String resourceId,
  }) async {
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
    await _lifecycle(transaction.id, TransactionLifecycleState.classified);

    final ledger = await ledgerRepository.append(
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-purchase',
        resourceId: resourceId,
        amount: -transaction.tokenAmount,
        type: LedgerEntryType.purchase,
        description: transaction.merchant.isEmpty ? '거래' : transaction.merchant,
        transactionId: transaction.id,
        createdAt: transaction.occurredAt,
      ),
    );
    await _lifecycle(transaction.id, TransactionLifecycleState.ledgerCreated);
    return ledger;
  }

  Future<List<LedgerEntry>> refund(TokenTransaction transaction) async {
    final ledger = await ledgerRepository.loadAll();
    final effective = _latestDebitForTransaction(transaction.id, ledger);
    if (effective == null) {
      throw StateError('Refund target Ledger entry not found.');
    }

    final now = DateTime.now();
    final updated = await ledgerRepository.append(
      LedgerEntry(
        id: '${now.microsecondsSinceEpoch}-refund',
        resourceId: effective.resourceId,
        amount: TokenAmount.fromMinorUnits(effective.amount.minorUnits.abs()),
        type: LedgerEntryType.refund,
        description: '환불 · ${effective.description}',
        transactionId: transaction.id,
        reversesLedgerEntryId: effective.id,
        createdAt: now,
      ),
    );
    await _lifecycle(transaction.id, TransactionLifecycleState.refunded);
    return updated;
  }

  Future<List<LedgerEntry>> reclassify({
    required TokenTransaction transaction,
    required String newResourceId,
  }) async {
    final ledger = await ledgerRepository.loadAll();
    final effective = _latestDebitForTransaction(transaction.id, ledger);
    if (effective == null) {
      throw StateError('Reclassification target Ledger entry not found.');
    }

    final now = DateTime.now();
    final reversal = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-reversal',
      resourceId: effective.resourceId,
      amount: TokenAmount.fromMinorUnits(effective.amount.minorUnits.abs()),
      type: LedgerEntryType.reversal,
      description: '재분류 역분개 · ${effective.description}',
      transactionId: transaction.id,
      reversesLedgerEntryId: effective.id,
      createdAt: now,
    );
    final replacement = LedgerEntry(
      id: '${now.microsecondsSinceEpoch}-reclassification',
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

    final updated = await ledgerRepository.appendAll([reversal, replacement]);
    await _lifecycle(transaction.id, TransactionLifecycleState.reclassified);
    return updated;
  }

  LedgerEntry? _latestDebitForTransaction(
    String transactionId,
    List<LedgerEntry> ledger,
  ) {
    final candidates = ledger.where((entry) =>
        entry.transactionId == transactionId &&
        entry.amount.isNegative &&
        (entry.type == LedgerEntryType.purchase ||
            entry.type == LedgerEntryType.reclassification));
    if (candidates.isEmpty) return null;
    return candidates.last;
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
