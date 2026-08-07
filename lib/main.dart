import 'package:flutter/material.dart';

import 'core/exchange_rate.dart';
import 'features/home/home_page.dart';
import 'features/period/management_period.dart';
import 'features/period/period_repository.dart';
import 'features/period/period_setup_page.dart';
import 'features/resource/resource.dart';
import 'features/resource/resource_repository.dart';
import 'features/transaction/transaction.dart';
import 'features/transaction/transaction_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TokenApp());
}

class TokenApp extends StatefulWidget {
  const TokenApp({super.key});

  @override
  State<TokenApp> createState() => _TokenAppState();
}

class _TokenAppState extends State<TokenApp> {
  final PeriodRepository _periodRepository = PeriodRepository();
  final ResourceRepository _resourceRepository = ResourceRepository();
  final TransactionRepository _transactionRepository =
      TransactionRepository();

  final ExchangeRate _exchangeRate = ExchangeRate.fromInt(100);

  ManagementPeriod? _activePeriod;
  List<Resource> _resources = const [];
  List<TokenTransaction> _transactions = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final period = await _periodRepository.loadActivePeriod();
    final resources = await _resourceRepository.loadAll();
    final transactions = await _transactionRepository.loadAll();

    if (!mounted) return;
    setState(() {
      _activePeriod = period;
      _resources = resources;
      _transactions = transactions;
      _loading = false;
    });
  }

  Future<void> _createPeriod(ManagementPeriod period) async {
    await _periodRepository.saveActivePeriod(period);
    if (!mounted) return;
    setState(() => _activePeriod = period);
  }

  Future<void> _createResource(Resource resource) async {
    final updated = await _resourceRepository.add(resource);
    if (!mounted) return;
    setState(() => _resources = updated);
  }

  Future<void> _createTransaction(TokenTransaction transaction) async {
    final resourceIndex = _resources.indexWhere(
      (resource) => resource.id == transaction.resourceId,
    );
    if (resourceIndex < 0) {
      throw StateError('Selected resource no longer exists.');
    }

    final oldResource = _resources[resourceIndex];
    final updatedResource = oldResource.copyWith(
      balance: oldResource.balance - transaction.tokenAmount,
    );

    final updatedResources = await _resourceRepository.replace(updatedResource);

    try {
      final updatedTransactions =
          await _transactionRepository.add(transaction);

      if (!mounted) return;
      setState(() {
        _resources = updatedResources;
        _transactions = updatedTransactions;
      });
    } catch (_) {
      await _resourceRepository.replace(oldResource);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TOKEN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: _loading
          ? const _LoadingPage()
          : _activePeriod == null
              ? PeriodSetupPage(onCreate: _createPeriod)
              : HomePage(
                  activePeriod: _activePeriod!,
                  resources: _resources,
                  transactions: _transactions,
                  exchangeRate: _exchangeRate,
                  onCreateResource: _createResource,
                  onCreateTransaction: _createTransaction,
                ),
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
