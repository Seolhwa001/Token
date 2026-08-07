import 'package:flutter/material.dart';

import '../resource.dart';

class ResourceCard extends StatelessWidget {
  final Resource resource;

  const ResourceCard({
    super.key,
    required this.resource,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 56,
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
                  Text(
                    resource.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${resource.balance.toDisplayString()} TOKEN',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: negative
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
