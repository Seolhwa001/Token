import 'package:flutter/material.dart';

import '../../core/display_formatter.dart';
import '../../core/token_amount.dart';
import '../classification/classification.dart';
import '../ledger/ledger_calculator.dart';
import '../ledger/ledger_entry.dart';
import '../resource/resource.dart';
import '../transaction/transaction.dart';

TokenAmount effectiveUnclassifiedTokenForTransaction({
  required String transactionId,
  required List<LedgerEntry> ledger,
}) {
  var minor = BigInt.zero;

  for (final entry in ledger) {
    if (entry.transactionId == transactionId &&
        entry.ledgerType == LedgerType.unclassified) {
      minor += entry.amount.minorUnits;
    }
  }

  if (minor >= BigInt.zero) {
    return TokenAmount.fromMinorUnits(BigInt.zero);
  }

  return TokenAmount.fromMinorUnits(-minor);
}

List<TokenTransaction> pendingTransactionsFromCurrentClassification({
  required List<TokenTransaction> transactions,
  required List<ClassificationResult> classifications,
  List<LedgerEntry> ledger = const [],
}) {
  final currentByTransaction = <String, ClassificationResult>{};

  for (final classification in classifications) {
    final current = currentByTransaction[classification.transactionId];

    if (current == null ||
        classification.createdAt.isAfter(current.createdAt) ||
        (classification.createdAt.isAtSameMomentAs(current.createdAt) &&
            classification.id.compareTo(current.id) > 0)) {
      currentByTransaction[classification.transactionId] = classification;
    }
  }

  final pending = transactions.where((transaction) {
    final current = currentByTransaction[transaction.id];

    if (current?.status != ClassificationStatus.unclassified) {
      return false;
    }

    // Backward-compatible behavior for unit tests or callers that do not
    // provide Ledger. Production UI always supplies Ledger.
    if (ledger.isEmpty) {
      return true;
    }

    // A fully refunded UNCLASSIFIED transaction has no remaining consumption
    // to classify, so it is not actionable and must not remain in Pending.
    return !effectiveUnclassifiedTokenForTransaction(
      transactionId: transaction.id,
      ledger: ledger,
    ).isZero;
  }).toList(growable: false)
    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  return List.unmodifiable(pending);
}

class PendingQueuePage extends StatefulWidget {
  final List<TokenTransaction> transactions;
  final List<ClassificationResult> classifications;
  final List<Resource> resources;
  final List<LedgerEntry> ledger;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onClassify;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onCreateSuggestedRule;

  const PendingQueuePage({
    super.key,
    required this.transactions,
    required this.classifications,
    required this.resources,
    required this.ledger,
    required this.onClassify,
    required this.onCreateSuggestedRule,
  });

  @override
  State<PendingQueuePage> createState() => _PendingQueuePageState();
}

class _PendingQueuePageState extends State<PendingQueuePage> {
  late List<TokenTransaction> _pending;

  @override
  void initState() {
    super.initState();
    _pending = pendingTransactionsFromCurrentClassification(
      transactions: widget.transactions,
      classifications: widget.classifications,
      ledger: widget.ledger,
    );
  }

  Future<void> _openDetail(TokenTransaction transaction) async {
    final result = await Navigator.of(context).push<PendingClassificationResult>(
      MaterialPageRoute(
        builder: (_) => PendingDetailPage(
          transaction: transaction,
          resources: widget.resources,
          ledger: widget.ledger,
          onClassify: widget.onClassify,
          onCreateSuggestedRule: widget.onCreateSuggestedRule,
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _pending = _pending
          .where((item) => item.id != transaction.id)
          .toList(growable: false);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            result.ruleSaved
                ? '분류하고 자동분류 규칙도 저장했습니다.'
                : '거래를 분류했습니다.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('분류 대기 ${_pending.length}건'),
      ),
      body: SafeArea(
        child: _pending.isEmpty
            ? const _PendingEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final transaction = _pending[index];
                  final remaining = effectiveUnclassifiedTokenForTransaction(
                    transactionId: transaction.id,
                    ledger: widget.ledger,
                  );

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        transaction.merchant.isEmpty
                            ? '가맹점 정보 없음'
                            : transaction.merchant,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${DisplayFormatter.won(transaction.wonAmount)} · '
                          '${DisplayFormatter.dateTime(transaction.occurredAt)}',
                        ),
                      ),
                      trailing: Text(
                        DisplayFormatter.token(remaining),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      onTap: () => _openDetail(transaction),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class PendingDetailPage extends StatefulWidget {
  final TokenTransaction transaction;
  final List<Resource> resources;
  final List<LedgerEntry> ledger;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onClassify;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onCreateSuggestedRule;

  const PendingDetailPage({
    super.key,
    required this.transaction,
    required this.resources,
    required this.ledger,
    required this.onClassify,
    required this.onCreateSuggestedRule,
  });

  @override
  State<PendingDetailPage> createState() => _PendingDetailPageState();
}

class _PendingDetailPageState extends State<PendingDetailPage> {
  final _calculator = const LedgerCalculator();

  String? _resourceId;
  bool _saving = false;
  String? _errorText;

  TokenAmount get _remaining {
    // PendingDetailPage is also used by legacy/widget-test callers that do not
    // supply Ledger. In that case the transaction's original TOKEN amount is
    // the classification target. Production Pending Queue supplies Ledger and
    // therefore uses the effective UNCLASSIFIED remainder after refunds.
    if (widget.ledger.isEmpty) {
      return widget.transaction.tokenAmount;
    }

    return effectiveUnclassifiedTokenForTransaction(
      transactionId: widget.transaction.id,
      ledger: widget.ledger,
    );
  }

  Future<void> _classify() async {
    final resourceId = _resourceId;

    if (_remaining.isZero) {
      setState(() {
        _errorText = '이 거래는 전액 환불되어 분류할 소비가 없습니다.';
      });
      return;
    }

    if (resourceId == null) {
      setState(() => _errorText = '분류할 자원을 선택하세요.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await widget.onClassify(widget.transaction, resourceId);

      var ruleSaved = false;

      if (widget.transaction.merchant.trim().isNotEmpty && mounted) {
        final saveRule = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('자동분류 규칙 저장'),
                content: Text(
                  '앞으로 "${widget.transaction.merchant.trim()}"이 포함된 '
                  '거래를 같은 자원으로 자동분류할까요?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('아니오'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('예'),
                  ),
                ],
              ),
            ) ??
            false;

        if (saveRule) {
          await widget.onCreateSuggestedRule(
            widget.transaction,
            resourceId,
          );
          ruleSaved = true;
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(
        PendingClassificationResult(ruleSaved: ruleSaved),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _errorText = '분류 처리 중 오류가 발생했습니다: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;

    return Scaffold(
      appBar: AppBar(title: const Text('미분류 거래 상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              transaction.merchant.isEmpty
                  ? '가맹점 정보 없음'
                  : transaction.merchant,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _DetailLine(
              label: '원화',
              value: DisplayFormatter.won(transaction.wonAmount),
            ),
            _DetailLine(
              label: '원래 TOKEN',
              value: DisplayFormatter.token(transaction.tokenAmount),
            ),
            _DetailLine(
              label: '분류 대상',
              value: DisplayFormatter.token(_remaining),
            ),
            _DetailLine(
              label: '거래일시',
              value: DisplayFormatter.dateTime(transaction.occurredAt),
            ),
            _DetailLine(
              label: '환율',
              value: DisplayFormatter.exchangeRate(
                transaction.appliedExchangeRate,
              ),
            ),
            if (transaction.memo.isNotEmpty)
              _DetailLine(
                label: '메모',
                value: transaction.memo,
              ),
            const SizedBox(height: 28),
            Text(
              '분류할 자원',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _resourceId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '자원을 선택하세요',
              ),
              items: widget.resources.map((resource) {
                final balance = _calculator.balanceForResource(
                  resource.id,
                  widget.ledger,
                );

                return DropdownMenuItem(
                  value: resource.id,
                  child: Text(
                    '${resource.name} · '
                    '${DisplayFormatter.token(balance)}',
                  ),
                );
              }).toList(growable: false),
              onChanged: _saving || _remaining.isZero
                  ? null
                  : (value) {
                      setState(() {
                        _resourceId = value;
                        _errorText = null;
                      });
                    },
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving || _remaining.isZero ? null : _classify,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_saving ? '처리 중...' : '이 자원으로 분류'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingClassificationResult {
  final bool ruleSaved;

  const PendingClassificationResult({
    required this.ruleSaved,
  });
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PendingEmptyState extends StatelessWidget {
  const _PendingEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, size: 52),
            const SizedBox(height: 16),
            Text(
              '분류할 거래가 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '자동분류되지 않은 거래가 생기면 여기에 표시됩니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
