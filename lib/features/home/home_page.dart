import 'package:flutter/material.dart';

import '../period/management_period.dart';
import '../resource/resource.dart';
import '../resource/resource_create_page.dart';
import '../resource/widgets/resource_card.dart';

class HomePage extends StatelessWidget {
  final ManagementPeriod activePeriod;
  final List<Resource> resources;
  final Future<void> Function(Resource resource) onCreateResource;

  const HomePage({
    super.key,
    required this.activePeriod,
    required this.resources,
    required this.onCreateResource,
  });

  Future<void> _openCreateResource(BuildContext context) async {
    final resource = await Navigator.of(context).push<Resource>(
      MaterialPageRoute(
        builder: (_) => const ResourceCreatePage(),
      ),
    );

    if (resource != null) {
      await onCreateResource(resource);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = activePeriod.remainingDaysOn(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('TOKEN')),
      floatingActionButton: resources.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _openCreateResource(context),
              child: const Icon(Icons.add),
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
                        '${_formatDate(activePeriod.startDate)} ~ ${_formatDate(activePeriod.endDate)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        remaining > 0
                            ? '남은 기간 $remaining일'
                            : '설정한 기간이 종료되었습니다.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: resources.isEmpty
                    ? _EmptyResources(
                        onCreate: () => _openCreateResource(context),
                      )
                    : ListView.separated(
                        itemCount: resources.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return ResourceCard(resource: resources[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResources extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyResources({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            '아직 TOKEN 자원이 없습니다.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text('사용할 수 있는 자원을 직접 만들어보세요.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('자원 만들기'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
