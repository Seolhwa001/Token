import 'package:flutter/material.dart';

import '../../core/exchange_rate.dart';
import '../ledger/ledger_entry.dart';
import '../period/management_period.dart';
import '../resource/resource.dart';
import '../resource/resource_create_page.dart';
import '../resource/resource_creation.dart';
import '../resource/widgets/resource_card.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_create_page.dart';
import '../transaction/transaction_submission.dart';
import '../unclassified/unclassified_inspector_page.dart';

class HomePage extends StatelessWidget {
  final ManagementPeriod activePeriod;
  final List<Resource> resources;
  final List<LedgerEntry> ledger;
  final List<TokenTransaction> transactions;
  final ExchangeRate exchangeRate;
  final Future<void> Function(ResourceCreation creation) onCreateResource;
  final Future<void> Function(TransactionSubmission submission)
      onCreateTransaction;

  const HomePage({
    super.key,
    required this.activePeriod,
    required this.resources,
    required this.ledger,
    required this.transactions,
    required this.exchangeRate,
    required this.onCreateResource,
    required this.onCreateTransaction,
  });

  Future<void> _openCreateResource(BuildContext context) async {
    final creation = await Navigator.of(context).push<ResourceCreation>(
      MaterialPageRoute(builder: (_) => const ResourceCreatePage()),
    );

    if (creation != null) {
      await onCreateResource(creation);
    }
  }

  Future<void> _openCreateTransaction(BuildContext context) async {
    final submission = await Navigator.of(context).push<TransactionSubmission>(
      MaterialPageRoute(
        builder: (_) => TransactionCreatePage(
          resources: resources,
          ledger: ledger,
          exchangeRate: exchangeRate,
        ),
      ),
    );

    if (submission == null) return;

    await onCreateTransaction(submission);

    if (!context.mounted) return;

    final message = submission.userResourceId == null
        ? '미분류 거래로 저장되었습니다.'
        : '거래가 저장되었습니다.';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _openUnclassifiedInspector(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnclassifiedInspectorPage(
          transactions: transactions,
          ledger: ledger,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = activePeriod.remainingDaysOn(DateTime.now());
    final unclassifiedCount = pendingUnclassifiedTransactions(
      transactions: transactions,
      ledger: ledger,
    ).length;

    return Scaffold(
      appBar: AppBar(title: const Text('TOKEN')),
      floatingActionButton: resources.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openCreateTransaction(context),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('거래'),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '내가 사용할 수 있는 자원',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '현재 관리 기간',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatDate(activePeriod.startDate)} ~ '
                        '${_formatDate(activePeriod.endDate)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        remaining > 0
                            ? '남은 기간 $remaining일'
                            : '설정한 기간이 종료되었습니다.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: const Text('미분류 거래'),
                  subtitle: Text('$unclassifiedCount건'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openUnclassifiedInspector(context),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: resources.isEmpty
                    ? Center(
                        child: FilledButton.icon(
                          onPressed: () => _openCreateResource(context),
                          icon: const Icon(Icons.add),
                          label: const Text('자원 만들기'),
                        ),
                      )
                    : Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _openCreateResource(context),
                              icon: const Icon(Icons.add),
                              label: const Text('자원 추가'),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: resources.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) => ResourceCard(
                                resource: resources[index],
                                ledger: ledger,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.'
    '${value.day.toString().padLeft(2, '0')}';
