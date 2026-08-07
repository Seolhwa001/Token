import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'features/period/management_period.dart';
import 'features/period/period_repository.dart';
import 'features/period/period_setup_page.dart';
import 'features/resource/resource.dart';
import 'features/resource/resource_repository.dart';

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

  ManagementPeriod? _activePeriod;
  List<Resource> _resources = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final period = await _periodRepository.loadActivePeriod();
    final resources = await _resourceRepository.loadAll();

    if (!mounted) return;
    setState(() {
      _activePeriod = period;
      _resources = resources;
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
                  onCreateResource: _createResource,
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
