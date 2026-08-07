import 'package:flutter/material.dart';

import '../classification/classification.dart';
import '../ledger/ledger_calculator.dart';
import '../ledger/ledger_entry.dart';
import '../resource/resource.dart';
import '../transaction/transaction.dart';

List<TokenTransaction> pendingTransactionsFromCurrentClassification({
  required List<TokenTransaction> transactions,
  required List<ClassificationResult> classifications,
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
    return current?.status == ClassificationStatus.unclassified;
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
                          '${_formatWon(transaction.wonAmount)}원 · '
                          '${_formatDateTime(transaction.occurredAt)}',
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${transaction.tokenAmount.toDisplayString()} TOKEN',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          const Icon(Icons.chevron_right),
                        ],
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

  Future<void> _classify() async {
    final resourceId = _resourceId;

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
              value: '${_formatWon(transaction.wonAmount)}원',
            ),
            _DetailLine(
              label: 'TOKEN',
              value: '${transaction.tokenAmount.toDisplayString()} TOKEN',
            ),
            _DetailLine(
              label: '거래일시',
              value: _formatDateTime(transaction.occurredAt),
            ),
            _DetailLine(
              label: '환율',
              value:
                  '${transaction.appliedExchangeRate.toDisplayString()}원 = 1 TOKEN',
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
                    '${balance.toDisplayString()} TOKEN',
                  ),
                );
              }).toList(growable: false),
              onChanged: _saving
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
              onPressed: _saving ? null : _classify,
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

String _formatWon(BigInt value) {
  final negative = value.isNegative;
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return negative ? '-$buffer' : buffer.toString();
}

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$year.$month.$day $hour:$minute';
}
