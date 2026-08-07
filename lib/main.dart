import 'package:flutter/material.dart';

import 'core/exchange_rate.dart';
import 'features/classification/classification.dart';
import 'features/classification/classification_repository.dart';
import 'features/classification/classification_rule.dart';
import 'features/classification/rule_engine.dart';
import 'features/classification/rule_repository.dart';
import 'features/home/home_page.dart';
import 'features/ledger/ledger_entry.dart';
import 'features/ledger/ledger_repository.dart';
import 'features/migration/pipeline_migration.dart';
import 'features/period/management_period.dart';
import 'features/period/period_repository.dart';
import 'features/period/period_setup_page.dart';
import 'features/resource/resource.dart';
import 'features/resource/resource_creation.dart';
import 'features/resource/resource_repository.dart';
import 'features/transaction/lifecycle_repository.dart';
import 'features/transaction/transaction.dart';
import 'features/transaction/transaction_pipeline.dart';
import 'features/transaction/transaction_repository.dart';
import 'features/transaction/transaction_submission.dart';

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
  final _periodRepository = PeriodRepository();
  final _resourceRepository = ResourceRepository();
  final _ledgerRepository = LedgerRepository();
  final _transactionRepository = TransactionRepository();
  final _classificationRepository = ClassificationRepository();
  final _ruleRepository = RuleRepository();
  final _lifecycleRepository = LifecycleRepository();

  final ExchangeRate _exchangeRate = ExchangeRate.fromInt(100);

  ManagementPeriod? _activePeriod;
  List<Resource> _resources = const [];
  List<LedgerEntry> _ledger = const [];
  List<TokenTransaction> _transactions = const [];
  List<ClassificationResult> _classifications = const [];
  bool _loading = true;

  late final TransactionPipeline _pipeline = TransactionPipeline(
    transactionRepository: _transactionRepository,
    classificationRepository: _classificationRepository,
    ledgerRepository: _ledgerRepository,
    lifecycleRepository: _lifecycleRepository,
    ruleEngine: const RuleEngine(),
    ruleRepository: _ruleRepository,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await PipelineMigration().runIfNeeded();

    final period = await _periodRepository.loadActivePeriod();
    final resources = await _resourceRepository.loadAll();
    final ledger = await _ledgerRepository.loadAll();
    final transactions = await _transactionRepository.loadAll();
    final classifications = await _classificationRepository.loadAll();

    if (!mounted) return;

    setState(() {
      _activePeriod = period;
      _resources = resources;
      _ledger = ledger;
      _transactions = transactions;
      _classifications = classifications;
      _loading = false;
    });
  }

  Future<void> _createPeriod(ManagementPeriod period) async {
    await _periodRepository.saveActivePeriod(period);

    if (!mounted) return;

    setState(() => _activePeriod = period);
  }

  Future<void> _createResource(ResourceCreation creation) async {
    final resources = await _resourceRepository.add(creation.resource);

    if (!creation.initialAmount.isZero) {
      await _ledgerRepository.append(
        LedgerEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}-initial-grant',
          resourceId: creation.resource.id,
          amount: creation.initialAmount,
          type: LedgerEntryType.initialGrant,
          description: '직접 지급',
          createdAt: DateTime.now(),
        ),
      );
    }

    final ledger = await _ledgerRepository.loadAll();

    if (!mounted) return;

    setState(() {
      _resources = resources;
      _ledger = ledger;
    });
  }

  Future<void> _createTransaction(
    TransactionSubmission submission,
  ) async {
    final result = await _pipeline.submit(
      submission.transaction,
      userResourceId: submission.userResourceId,
    );

    final transactions = await _transactionRepository.loadAll();
    final classifications = await _classificationRepository.loadAll();

    if (!mounted) return;

    setState(() {
      _ledger = result.ledger;
      _transactions = transactions;
      _classifications = classifications;
    });
  }

  Future<void> _classifyPending(
    TokenTransaction transaction,
    String resourceId,
  ) async {
    final ledger = await _pipeline.classifyPending(
      transaction: transaction,
      resourceId: resourceId,
    );

    final classifications = await _classificationRepository.loadAll();

    if (!mounted) return;

    setState(() {
      _ledger = ledger;
      _classifications = classifications;
    });
  }

  Future<void> _createSuggestedRule(
    TokenTransaction transaction,
    String resourceId,
  ) async {
    final keyword = transaction.merchant.trim();

    if (keyword.isEmpty) return;

    final allRules = await _ruleRepository.listAllIncludingDeleted();

    var maxPriority = 0;
    for (final rule in allRules) {
      if (rule.priority > maxPriority) {
        maxPriority = rule.priority;
      }
    }

    final now = DateTime.now();

    await _ruleRepository.insert(
      ClassificationRule(
        id: '${now.microsecondsSinceEpoch}-suggested-rule',
        priority: maxPriority + 1,
        includeKeywords: [keyword],
        resourceId: resourceId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TOKEN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: _loading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _activePeriod == null
              ? PeriodSetupPage(
                  onCreate: _createPeriod,
                )
              : HomePage(
                  activePeriod: _activePeriod!,
                  resources: _resources,
                  ledger: _ledger,
                  transactions: _transactions,
                  classifications: _classifications,
                  exchangeRate: _exchangeRate,
                  onCreateResource: _createResource,
                  onCreateTransaction: _createTransaction,
                  onClassifyPending: _classifyPending,
                  onCreateSuggestedRule: _createSuggestedRule,
                ),
    );
  }
}
