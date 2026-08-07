import 'package:flutter/material.dart';

import 'core/exchange_rate.dart';
import 'core/token_converter.dart';

void main() {
  runApp(const TokenApp());
}

class TokenApp extends StatelessWidget {
  const TokenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TOKEN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TokenHomePage(),
    );
  }
}

class TokenHomePage extends StatelessWidget {
  const TokenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sample = wonToToken(
      won: BigInt.from(13855),
      exchangeRate: ExchangeRate.fromInt(100),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('TOKEN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내가 사용할 수 있는 자원',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('Core build check'),
                subtitle: Text('13,855원 / 100원 = ${sample.toDisplayString()} TOKEN'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('현재 단계: TOKEN Core 초기 골격'),
          ],
        ),
      ),
    );
  }
}
