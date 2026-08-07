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

  const TransactionHistoryPage({
    super.key,
    required this.transactions,
    required this.classifications,
    required this.ledger,
    required this.resources,
  });

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
                    (e) => e.transactionId == tx.id && e.type == LedgerEntryType.refund,
                  );
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(tx.merchant.isEmpty ? '가맹점 정보 없음' : tx.merchant),
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
                      onTap: () => Navigator.of(context).push(
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
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class TransactionDetailPage extends StatelessWidget {
  final TokenTransaction transaction;
  final List<ClassificationResult> classifications;
  final List<LedgerEntry> ledger;
  final List<Resource> resources;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.classifications,
    required this.ledger,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    final classHistory = [...classifications]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ledgerHistory = [...ledger]
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
              transaction.merchant.isEmpty ? '가맹점 정보 없음' : transaction.merchant,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _Info('거래일시', DisplayFormatter.dateTime(transaction.occurredAt)),
            _Info('원화', DisplayFormatter.won(transaction.wonAmount)),
            _Info('TOKEN', DisplayFormatter.token(transaction.tokenAmount)),
            _Info(
              '적용 환율',
              DisplayFormatter.exchangeRate(transaction.appliedExchangeRate),
            ),
            _Info(
              '현재 자원',
              _resourceName(current?.resourceId, resources) ?? '미분류',
            ),
            _Info('분류 상태', _classificationLabel(current)),
            _Info('환불 상태', refunds.isEmpty ? '환불 없음' : '환불 기록 있음'),
            if (transaction.memo.isNotEmpty) _Info('메모', transaction.memo),
            const SizedBox(height: 28),
            _Section('분류 이력', classHistory.length),
            if (classHistory.isEmpty)
              const _Empty('분류 이력이 없습니다.')
            else
              ...classHistory.map(
                (c) => _Timeline(
                  title: _classificationLabel(c),
                  value: _resourceName(c.resourceId, resources) ?? '미분류',
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
                      _resourceName(e.resourceId, resources) ?? e.resourceId!,
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
                  detail: e.reversesLedgerEntryId == null
                      ? null
                      : 'reverseOf=${e.reversesLedgerEntryId}',
                ),
              ),
          ],
        ),
      ),
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
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(text));
}
