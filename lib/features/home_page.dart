import 'package:flutter/material.dart';

import '../period/management_period.dart';

class HomePage extends StatelessWidget {
  final ManagementPeriod activePeriod;

  const HomePage({
    super.key,
    required this.activePeriod,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = activePeriod.remainingDaysOn(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('TOKEN')),
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
                        '${_formatDate(activePeriod.startDate)} ~ ${_formatDate(activePeriod.endDate)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        remaining > 0 ? '남은 기간 $remaining일' : '설정한 기간이 종료되었습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('아직 TOKEN 자원이 없습니다.'),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
