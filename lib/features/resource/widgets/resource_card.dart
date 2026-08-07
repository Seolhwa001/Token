import 'package:flutter/material.dart';
import '../../analytics/ledger_analytics.dart';
import '../../ledger/ledger_calculator.dart';
import '../../ledger/ledger_entry.dart';
import '../resource.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;
  final List<LedgerEntry> ledger;

  const ResourceCard({
    super.key,
    required this.resource,
    required this.ledger,
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
    const calculator = LedgerCalculator();
    const analytics = LedgerAnalytics();
    final color = _colors[resource.colorKey] ?? Colors.teal;
    final balance = calculator.balanceForResource(resource.id, ledger);
    final todaySpent = analytics.spentForResourceOnDay(
      resourceId: resource.id,
      day: DateTime.now(),
      ledger: ledger,
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
                  Text(resource.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    '${balance.toDisplayString()} TOKEN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: balance.isNegative
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                  if (!todaySpent.isZero) ...[
                    const SizedBox(height: 6),
                    Text('오늘 소비 ${todaySpent.toDisplayString()} TOKEN'),
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
