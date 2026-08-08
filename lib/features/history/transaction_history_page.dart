import 'package:flutter/material.dart';

import '../../core/display_formatter.dart';
import '../classification/classification.dart';
import '../ledger/ledger_entry.dart';
import '../resource/resource.dart';
import '../transaction/transaction.dart';

class TransactionHistoryPage extends StatelessWidget {
  final List<TokenTransaction> transactions;
  final List<ClassificationResult> classifications;
  final List<LedgerEntry> ledger;
  final List<Resource> resources;
  final Future<void> Function(TokenTransaction, BigInt)? onRefund;
  final Future<void> Function(TokenTransaction, String)? onReclassify;

  const TransactionHistoryPage({
    super.key,
    required this.transactions,
    required this.classifications,
    required this.ledger,
    required this.resources,
    this.onRefund,
    this.onReclassify,
  });

  Future<void> _openDetail(
    BuildContext context,
    TokenTransaction tx,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(
          transaction: tx,
          classifications: classifications
              .where((c) => c.transactionId == tx.id)
              .toList(growable: false),
          ledger: ledger
              .where((e) => e.transactionId == tx.id)
              .toList(growable: false),
          resources: resources,
          onRefund: onRefund,
          onReclassify: onReclassify,
        ),
      ),
    );

    // Parent Home owns the authoritative accounting state.
    // After a mutation, close History once so reopening shows refreshed data.
    if (changed == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...transactions]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return Scaffold(
      appBar: AppBar(title: const Text('거래 내역')),
      body: SafeArea(
        child: sorted.isEmpty
            ? const Center(child: Text('아직 거래가 없습니다.'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tx = sorted[index];
                  final current = _current(tx.id, classifications);
                  final refunded = ledger.any(
                    (e) =>
                        e.transactionId == tx.id &&
                        e.type == LedgerEntryType.refund,
                  );

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        tx.merchant.isEmpty ? '가맹점 정보 없음' : tx.merchant,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DisplayFormatter.dateTime(tx.occurredAt)),
                            const SizedBox(height: 4),
                            Text(
                              '${_resourceName(current?.resourceId, resources) ?? '미분류'}'
                              ' · ${_classificationLabel(current)}'
                              '${refunded ? ' · 환불' : ''}',
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DisplayFormatter.won(tx.wonAmount),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(DisplayFormatter.token(tx.tokenAmount)),
                        ],
                      ),
                      onTap: () => _openDetail(context, tx),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class TransactionDetailPage extends StatefulWidget {
  final TokenTransaction transaction;
  final List<ClassificationResult> classifications;
  final List<LedgerEntry> ledger;
  final List<Resource> resources;
  final Future<void> Function(TokenTransaction, BigInt)? onRefund;
  final Future<void> Function(TokenTransaction, String)? onReclassify;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.classifications,
    required this.ledger,
    required this.resources,
    this.onRefund,
    this.onReclassify,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _busy = false;

  BigInt get _remainingWon {
    var refundedMinor = BigInt.zero;
    for (final e in widget.ledger) {
      if (e.type == LedgerEntryType.refund && !e.amount.isNegative) {
        refundedMinor += e.amount.minorUnits;
      }
    }

    final refundedWon =
        (refundedMinor * widget.transaction.appliedExchangeRate.minorWonPerToken) ~/
            BigInt.from(10000);
    final remaining = widget.transaction.wonAmount - refundedWon;
    return remaining.isNegative ? BigInt.zero : remaining;
  }

  Future<void> _refund() async {
    if (_remainingWon <= BigInt.zero || _busy) return;

    final amount = await showDialog<BigInt>(
      context: context,
      builder: (dialogContext) => _RefundDialog(
        remainingWon: _remainingWon,
      ),
    );

    if (!mounted || amount == null) return;

    // UI validation is performed inside _RefundDialog.
    // Keep this guard as a second boundary before the Core pipeline.
    if (amount <= BigInt.zero || amount > _remainingWon) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환불 가능 범위의 금액을 입력하세요.')),
      );
      return;
    }

    final callback = widget.onRefund;
    if (callback == null) return;

    setState(() => _busy = true);
    try {
      await callback(widget.transaction, amount);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${DisplayFormatter.won(amount)} 환불 완료')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('환불 실패: $error')),
      );
    }
  }

  Future<void> _reclassify() async {
    final current = widget.classifications.isEmpty
        ? null
        : ([...widget.classifications]
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt)))
            .last;

    String? selected = widget.resources
        .where((r) => r.id != current?.resourceId)
        .map((r) => r.id)
        .cast<String?>()
        .firstOrNull;

    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택할 다른 자원이 없습니다.')),
      );
      return;
    }

    final resourceId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('재분류'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(
              labelText: '새 자원',
              border: OutlineInputBorder(),
            ),
            items: widget.resources
                .where((r) => r.id != current?.resourceId)
                .map(
                  (r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => setDialogState(() => selected = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(selected),
              child: const Text('재분류'),
            ),
          ],
        ),
      ),
    );

    if (resourceId == null) return;

    setState(() => _busy = true);
    try {
      final callback = widget.onReclassify;
      if (callback == null) return;
      await callback(widget.transaction, resourceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재분류가 완료되었습니다.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('재분류 실패: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classHistory = [...widget.classifications]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ledgerHistory = [...widget.ledger]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final refunds = ledgerHistory
        .where((e) => e.type == LedgerEntryType.refund)
        .toList(growable: false);
    final current = classHistory.isEmpty ? null : classHistory.last;

    return Scaffold(
      appBar: AppBar(title: const Text('거래 상세')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              widget.transaction.merchant.isEmpty
                  ? '가맹점 정보 없음'
                  : widget.transaction.merchant,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _Info(
              '거래일시',
              DisplayFormatter.dateTime(widget.transaction.occurredAt),
            ),
            _Info('원화', DisplayFormatter.won(widget.transaction.wonAmount)),
            _Info(
              'TOKEN',
              DisplayFormatter.token(widget.transaction.tokenAmount),
            ),
            _Info(
              '적용 환율',
              DisplayFormatter.exchangeRate(
                widget.transaction.appliedExchangeRate,
              ),
            ),
            _Info(
              '현재 자원',
              _resourceName(current?.resourceId, widget.resources) ?? '미분류',
            ),
            _Info('분류 상태', _classificationLabel(current)),
            _Info(
              '환불 가능',
              DisplayFormatter.won(_remainingWon),
            ),
            if (widget.transaction.memo.isNotEmpty)
              _Info('메모', widget.transaction.memo),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ||
                            _remainingWon <= BigInt.zero ||
                            widget.onReclassify == null
                        ? null
                        : _reclassify,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('재분류'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ||
                            _remainingWon <= BigInt.zero ||
                            widget.onRefund == null
                        ? null
                        : _refund,
                    icon: const Icon(Icons.undo),
                    label: const Text('환불'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _Section('분류 이력', classHistory.length),
            if (classHistory.isEmpty)
              const _Empty('분류 이력이 없습니다.')
            else
              ...classHistory.map(
                (c) => _Timeline(
                  title: _classificationLabel(c),
                  value:
                      _resourceName(c.resourceId, widget.resources) ?? '미분류',
                  time: c.createdAt,
                  detail: c.ruleId == null ? null : 'Rule: ${c.ruleId}',
                ),
              ),
            const SizedBox(height: 24),
            _Section('Ledger 이력', ledgerHistory.length),
            if (ledgerHistory.isEmpty)
              const _Empty('Ledger 이력이 없습니다.')
            else
              ...ledgerHistory.map(
                (e) => _Timeline(
                  title: _ledgerLabel(e.type),
                  value: DisplayFormatter.token(e.amount),
                  time: e.createdAt,
                  detail: [
                    if (e.resourceId != null)
                      _resourceName(e.resourceId, widget.resources) ??
                          e.resourceId!,
                    e.ledgerType.name.toUpperCase(),
                    if (e.reversesLedgerEntryId != null)
                      'reverseOf=${e.reversesLedgerEntryId}',
                  ].join(' · '),
                ),
              ),
            const SizedBox(height: 24),
            _Section('환불 이력', refunds.length),
            if (refunds.isEmpty)
              const _Empty('환불 이력이 없습니다.')
            else
              ...refunds.map(
                (e) => _Timeline(
                  title: '환불',
                  value: DisplayFormatter.token(e.amount),
                  time: e.createdAt,
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _RefundDialog extends StatefulWidget {
  final BigInt remainingWon;

  const _RefundDialog({
    required this.remainingWon,
  });

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.remainingWon.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim().replaceAll(',', '');
    final amount = BigInt.tryParse(raw);

    if (amount == null) {
      setState(() => _errorText = '환불 금액을 숫자로 입력하세요.');
      return;
    }
    if (amount <= BigInt.zero) {
      setState(() => _errorText = '환불 금액은 0원보다 커야 합니다.');
      return;
    }
    if (amount > widget.remainingWon) {
      setState(() {
        _errorText =
            '환불 가능 금액 ${DisplayFormatter.won(widget.remainingWon)}을 초과했습니다.';
      });
      return;
    }

    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('환불 처리'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '남은 환불 가능 금액: '
              '${DisplayFormatter.won(widget.remainingWon)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '환불 금액(원)',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_errorText != null) {
                  setState(() => _errorText = null);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(widget.remainingWon),
          child: const Text('전액 환불'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('환불'),
        ),
      ],
    );
  }
}

ClassificationResult? _current(
  String txId,
  List<ClassificationResult> classifications,
) {
  final list = classifications.where((c) => c.transactionId == txId).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return list.isEmpty ? null : list.last;
}

String? _resourceName(String? id, List<Resource> resources) {
  if (id == null) return null;
  for (final r in resources) {
    if (r.id == id) return r.name;
  }
  return id;
}

String _classificationLabel(ClassificationResult? result) {
  if (result == null) return '분류 기록 없음';
  switch (result.status) {
    case ClassificationStatus.autoClassified:
      return '자동분류';
    case ClassificationStatus.userClassified:
      return '사용자 분류';
    case ClassificationStatus.unclassified:
      return '미분류';
  }
}

String _ledgerLabel(LedgerEntryType type) {
  switch (type) {
    case LedgerEntryType.initialGrant:
      return '직접 지급';
    case LedgerEntryType.purchase:
      return '소비';
    case LedgerEntryType.refund:
      return '환불';
    case LedgerEntryType.reversal:
      return '역분개';
    case LedgerEntryType.reclassification:
      return '재분류';
    case LedgerEntryType.migrationOpening:
      return '마이그레이션';
  }
}

class _Info extends StatelessWidget {
  final String label;
  final String value;
  const _Info(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  final String title;
  final int count;
  const _Section(this.title, this.count);

  @override
  Widget build(BuildContext context) =>
      Text('$title ($count)', style: Theme.of(context).textTheme.titleMedium);
}

class _Timeline extends StatelessWidget {
  final String title;
  final String value;
  final DateTime time;
  final String? detail;

  const _Timeline({
    required this.title,
    required this.value,
    required this.time,
    this.detail,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title)),
                  Text(value, style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DisplayFormatter.dateTime(time),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(detail!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
