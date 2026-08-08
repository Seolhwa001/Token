import 'package:flutter/material.dart';

import '../../core/display_formatter.dart';
import '../../core/exchange_rate.dart';
import '../classification/classification.dart';
import '../history/transaction_history_page.dart';
import '../ledger/ledger_entry.dart';
import '../pending/pending_queue_page.dart';
import '../period/management_period.dart';
import '../resource/resource.dart';
import '../resource/resource_create_page.dart';
import '../resource/resource_creation.dart';
import '../resource/widgets/resource_card.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_create_page.dart';
import '../transaction/transaction_submission.dart';

class HomePage extends StatelessWidget {
  final ManagementPeriod activePeriod;
  final List<Resource> resources;
  final List<LedgerEntry> ledger;
  final List<TokenTransaction> transactions;
  final List<ClassificationResult> classifications;
  final ExchangeRate exchangeRate;
  final Future<void> Function(ResourceCreation creation) onCreateResource;
  final Future<void> Function(TransactionSubmission submission)
      onCreateTransaction;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onClassifyPending;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onCreateSuggestedRule;
  final Future<void> Function(
    TokenTransaction transaction,
    BigInt wonAmount,
  ) onRefundTransaction;
  final Future<void> Function(
    TokenTransaction transaction,
    String resourceId,
  ) onReclassifyTransaction;

  const HomePage({
    super.key,
    required this.activePeriod,
    required this.resources,
    required this.ledger,
    required this.transactions,
    required this.classifications,
    required this.exchangeRate,
    required this.onCreateResource,
    required this.onCreateTransaction,
    required this.onClassifyPending,
    required this.onCreateSuggestedRule,
    required this.onRefundTransaction,
    required this.onReclassifyTransaction,
  });

  Future<void> _openCreateResource(BuildContext context) async {
    final creation = await Navigator.of(context).push<ResourceCreation>(
      MaterialPageRoute(builder: (_) => const ResourceCreatePage()),
    );
    if (creation != null) await onCreateResource(creation);
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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            submission.userResourceId == null
                ? '거래를 저장했습니다. 자동분류되지 않으면 분류 대기로 이동합니다.'
                : '거래가 저장되었습니다.',
          ),
        ),
      );
  }

  void _openPendingQueue(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PendingQueuePage(
          transactions: transactions,
          classifications: classifications,
          resources: resources,
          ledger: ledger,
          onClassify: onClassifyPending,
          onCreateSuggestedRule: onCreateSuggestedRule,
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionHistoryPage(
          transactions: transactions,
          classifications: classifications,
          ledger: ledger,
          resources: resources,
          onRefund: onRefundTransaction,
          onReclassify: onReclassifyTransaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = activePeriod.remainingDaysOn(DateTime.now());
    final pendingCount = pendingTransactionsFromCurrentClassification(
      transactions: transactions,
      classifications: classifications,
    ).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TOKEN'),
        actions: [
          IconButton(
            tooltip: '거래 내역',
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
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
                        '${DisplayFormatter.date(activePeriod.startDate)} ~ '
                        '${DisplayFormatter.date(activePeriod.endDate)}',
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
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.pending_actions_outlined),
                        title: const Text('분류 대기'),
                        subtitle: Text(pendingCount == 0 ? '없음' : '$pendingCount건'),
                        onTap: () => _openPendingQueue(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('거래 내역'),
                        subtitle: Text('${transactions.length}건'),
                        onTap: () => _openHistory(context),
                      ),
                    ),
                  ),
                ],
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
