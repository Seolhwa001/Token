import 'package:flutter/material.dart';

import '../ledger/ledger_entry.dart';
import '../transaction/transaction.dart';

/// Returns only transactions that currently have an effective
/// UNCLASSIFIED debit in the append-only Ledger.
///
/// An UNCLASSIFIED debit disappears from the pending list only when another
/// Ledger entry references it through reversesLedgerEntryId.
List<TokenTransaction> pendingUnclassifiedTransactions({
  required List<TokenTransaction> transactions,
  required List<LedgerEntry> ledger,
}) {
  final pendingTransactionIds = <String>{};

  for (final entry in ledger) {
    if (entry.ledgerType != LedgerType.unclassified ||
        !entry.amount.isNegative ||
        entry.transactionId == null) {
      continue;
    }

    final reversed = ledger.any(
      (candidate) => candidate.reversesLedgerEntryId == entry.id,
    );

    if (!reversed) {
      pendingTransactionIds.add(entry.transactionId!);
    }
  }

  final result = transactions
      .where((transaction) => pendingTransactionIds.contains(transaction.id))
      .toList(growable: false);

  result.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  return result;
}

class UnclassifiedInspectorPage extends StatelessWidget {
  final List<TokenTransaction> transactions;
  final List<LedgerEntry> ledger;

  const UnclassifiedInspectorPage({
    super.key,
    required this.transactions,
    required this.ledger,
  });

  @override
  Widget build(BuildContext context) {
    final pending = pendingUnclassifiedTransactions(
      transactions: transactions,
      ledger: ledger,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('미분류 거래')),
      body: SafeArea(
        child: pending.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: pending.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _UnclassifiedTransactionCard(
                    transaction: pending[index],
                  );
                },
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 52),
            const SizedBox(height: 16),
            Text(
              '미분류 거래가 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '아직 특정 자원에 귀속되지 않은 거래가 여기에 표시됩니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnclassifiedTransactionCard extends StatelessWidget {
  final TokenTransaction transaction;

  const _UnclassifiedTransactionCard({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final merchant =
        transaction.merchant.isEmpty ? '가맹점 정보 없음' : transaction.merchant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    merchant,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                const Chip(label: Text('미분류')),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${transaction.tokenAmount.toDisplayString()} TOKEN',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('${_formatWon(transaction.wonAmount)}원'),
            const SizedBox(height: 10),
            Text(
              _formatDateTime(transaction.occurredAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (transaction.memo.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('메모: ${transaction.memo}'),
            ],
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
