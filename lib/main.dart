import 'package:flutter/material.dart';

import 'features/home/home_page.dart';
import 'features/period/management_period.dart';
import 'features/period/period_repository.dart';
import 'features/period/period_setup_page.dart';

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
  ManagementPeriod? _activePeriod;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final period = await _periodRepository.loadActivePeriod();
    if (!mounted) return;
    setState(() {
      _activePeriod = period;
      _loading = false;
    });
  }

  Future<void> _createPeriod(ManagementPeriod period) async {
    await _periodRepository.saveActivePeriod(period);
    if (!mounted) return;
    setState(() => _activePeriod = period);
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
              : HomePage(activePeriod: _activePeriod!),
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
