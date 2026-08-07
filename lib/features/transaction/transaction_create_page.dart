import 'package:flutter/material.dart';

import '../../core/exchange_rate.dart';
import '../../core/token_amount.dart';
import '../../core/token_converter.dart';
import '../resource/resource.dart';
import 'transaction.dart';

class TransactionCreatePage extends StatefulWidget {
  final List<Resource> resources;
  final ExchangeRate exchangeRate;

  const TransactionCreatePage({
    super.key,
    required this.resources,
    required this.exchangeRate,
  });

  @override
  State<TransactionCreatePage> createState() =>
      _TransactionCreatePageState();
}

class _TransactionCreatePageState extends State<TransactionCreatePage> {
  final _wonController = TextEditingController();
  final _memoController = TextEditingController();

  String? _resourceId;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.resources.isNotEmpty) {
      _resourceId = widget.resources.first.id;
    }
    _wonController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _wonController.removeListener(_refreshPreview);
    _wonController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  TokenAmount? get _previewAmount {
    final raw = _wonController.text.trim().replaceAll(',', '');
    if (raw.isEmpty) return null;
    try {
      final won = BigInt.parse(raw);
      if (won <= BigInt.zero) return null;
      return wonToToken(won: won, exchangeRate: widget.exchangeRate);
    } on FormatException {
      return null;
    }
  }

  void _save() {
    final resourceId = _resourceId;
    final rawWon = _wonController.text.trim().replaceAll(',', '');

    if (resourceId == null) {
      setState(() => _errorText = '사용할 자원을 선택하세요.');
      return;
    }

    BigInt won;
    try {
      won = BigInt.parse(rawWon);
    } on FormatException {
      setState(() => _errorText = '원화 금액을 숫자로 입력하세요.');
      return;
    }

    if (won <= BigInt.zero) {
      setState(() => _errorText = '소비 금액은 0원보다 커야 합니다.');
      return;
    }

    final tokenAmount =
        wonToToken(won: won, exchangeRate: widget.exchangeRate);
    final now = DateTime.now();

    Navigator.of(context).pop(
      TokenTransaction(
        id: '${now.microsecondsSinceEpoch}',
        resourceId: resourceId,
        wonAmount: won,
        tokenAmount: tokenAmount,
        appliedExchangeRate: widget.exchangeRate,
        memo: _memoController.text.trim(),
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _previewAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('거래 추가')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '소비를 기록하세요',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '현재 환율: ${widget.exchangeRate.toDisplayString()}원 = 1 TOKEN',
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _wonController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '금액(원)',
                  hintText: '예: 13855',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _resourceId,
                decoration: const InputDecoration(
                  labelText: '사용 자원',
                  border: OutlineInputBorder(),
                ),
                items: widget.resources
                    .map(
                      (resource) => DropdownMenuItem(
                        value: resource.id,
                        child: Text(
                          '${resource.name} · ${resource.balance.toDisplayString()} TOKEN',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _resourceId = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('차감 예정')),
                      Text(
                        preview == null
                            ? '-'
                            : '${preview.toDisplayString()} TOKEN',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('거래 저장'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
