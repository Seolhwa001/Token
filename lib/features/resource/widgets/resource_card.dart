import 'package:flutter/material.dart';

import '../../transaction/transaction.dart';
import '../resource.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final List<TokenTransaction> transactions;

  const ResourceCard({
    super.key,
    required this.resource,
    this.transactions = const [],
  });

  static const _colors = <String, Color>{
    'teal': Colors.teal,
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'red': Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[resource.colorKey] ?? Colors.teal;
    final negative = resource.balance.isNegative;
    final todayTransactions = transactions.where(
      (transaction) =>
          transaction.resourceId == resource.id &&
          _isSameDay(transaction.createdAt, DateTime.now()),
    );

    final todaySpent = todayTransactions.fold(
      BigInt.zero,
      (sum, transaction) => sum + transaction.tokenAmount.minorUnits,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(resource.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '${resource.balance.toDisplayString()} TOKEN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: negative
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  if (todaySpent != BigInt.zero) ...[
                    const SizedBox(height: 6),
                    Text(
                      '오늘 소비 ${_formatMinorUnits(todaySpent)} TOKEN',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatMinorUnits(BigInt minorUnits) {
  final negative = minorUnits.isNegative;
  final abs = minorUnits.abs();
  final whole = abs ~/ BigInt.from(100);
  final fraction = (abs % BigInt.from(100)).toString().padLeft(2, '0');
  var text = '${negative ? '-' : ''}$whole.$fraction';
  if (text.endsWith('.00')) return text.substring(0, text.length - 3);
  if (text.endsWith('0')) return text.substring(0, text.length - 1);
  return text;
}
