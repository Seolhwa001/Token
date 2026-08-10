import 'package:flutter/material.dart';

import '../../core/display_formatter.dart';
import '../classification/classification.dart';
import '../history/transaction_history_page.dart';
import '../ledger/ledger_entry.dart';
import '../transaction/transaction.dart';
import 'resource.dart';
import 'resource_detail_query.dart';

class ResourceDetailPage extends StatelessWidget {
  final Resource resource;
  final List<Resource> resources;
  final List<TokenTransaction> transactions;
  final List<ClassificationResult> classifications;
  final List<LedgerEntry> ledger;
  final Future<void> Function(TokenTransaction, BigInt)? onRefund;
  final Future<void> Function(TokenTransaction, String)? onReclassify;

  const ResourceDetailPage({
    super.key,
    required this.resource,
    required this.resources,
    required this.transactions,
    required this.classifications,
    required this.ledger,
    this.onRefund,
    this.onReclassify,
  });

  Future<void> _openTransaction(
    BuildContext context,
    TokenTransaction transaction,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionDetailPage(
          transaction: transaction,
          classifications: classifications
              .where((c) => c.transactionId == transaction.id)
              .toList(growable: false),
          ledger: ledger
              .where((e) => e.transactionId == transaction.id)
              .toList(growable: false),
          resources: resources,
          onRefund: onRefund,
          onReclassify: onReclassify,
        ),
      ),
    );

    // Home owns authoritative state. Close Resource Detail after an accounting
    // mutation so reopening it rebuilds from persisted/derived domain state.
    if (changed == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = const ResourceDetailQuery().build(
      resourceId: resource.id,
      transactions: transactions,
      classifications: classifications,
      ledger: ledger,
    );

    return Scaffold(
      appBar: AppBar(title: Text(resource.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(resource.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _Metric(
              label: '현재 TOKEN 잔액',
              value: DisplayFormatter.token(snapshot.balance),
            ),
            _Metric(
              label: '지급 TOKEN',
              value: DisplayFormatter.token(snapshot.granted),
            ),
            _Metric(
              label: '현재 유효 소비',
              value: DisplayFormatter.token(snapshot.effectiveConsumption),
            ),
            const SizedBox(height: 24),
            Text(
              '소비 내역 (${snapshot.transactions.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (snapshot.transactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('현재 이 자원에 귀속된 거래가 없습니다.')),
              )
            else
              ...snapshot.transactions.map((item) {
                final status = item.fullyRefunded
                    ? 'REFUNDED'
                    : item.partiallyRefunded
                        ? 'PARTIALLY_REFUNDED'
                        : null;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item.transaction.merchant.isEmpty
                          ? '가맹점 정보 없음'
                          : item.transaction.merchant,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text([
                        DisplayFormatter.dateTime(item.transaction.occurredAt),
                        if (status != null) status,
                      ].join(' · ')),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(DisplayFormatter.won(item.transaction.wonAmount)),
                        const SizedBox(height: 4),
                        Text(DisplayFormatter.token(item.effectiveConsumption)),
                      ],
                    ),
                    onTap: () => _openTransaction(context, item.transaction),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(label),
          trailing: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
}
