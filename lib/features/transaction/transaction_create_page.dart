import 'package:flutter/material.dart';

import '../../core/exchange_rate.dart';
import '../ledger/ledger_calculator.dart';
import '../ledger/ledger_entry.dart';
import '../resource/resource.dart';
import 'transaction_provider.dart';
import 'transaction_submission.dart';

class TransactionCreatePage extends StatefulWidget {
  final List<Resource> resources;
  final List<LedgerEntry> ledger;
  final ExchangeRate exchangeRate;

  const TransactionCreatePage({
    super.key,
    required this.resources,
    required this.ledger,
    required this.exchangeRate,
  });

  @override
  State<TransactionCreatePage> createState() =>
      _TransactionCreatePageState();
}

class _TransactionCreatePageState extends State<TransactionCreatePage> {
  static const _unclassifiedValue = '__UNCLASSIFIED__';

  final _wonController = TextEditingController();
  final _merchantController = TextEditingController();
  final _memoController = TextEditingController();
  final _provider = ManualTransactionProvider();
  final _calculator = const LedgerCalculator();

  String _classificationSelection = _unclassifiedValue;
  String? _errorText;

  String? get _selectedResourceId =>
      _classificationSelection == _unclassifiedValue
          ? null
          : _classificationSelection;

  @override
  void dispose() {
    _wonController.dispose();
    _merchantController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _save() {
    final rawWon = _wonController.text.trim().replaceAll(',', '');

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

    final now = DateTime.now();

    Navigator.of(context).pop(
      TransactionSubmission(
        transaction: _provider.create(
          id: '${now.microsecondsSinceEpoch}',
          wonAmount: won,
          exchangeRate: widget.exchangeRate,
          merchant: _merchantController.text.trim(),
          memo: _memoController.text.trim(),
          occurredAt: now,
        ),
        userResourceId: _selectedResourceId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('거래 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              '소비를 기록하세요',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '현재 환율: '
              '${widget.exchangeRate.toDisplayString()}원 = 1 TOKEN',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _wonController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '금액(원)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _merchantController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '가맹점 (선택)',
                hintText: '예: 맥도날드',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _classificationSelection,
              decoration: const InputDecoration(
                labelText: '분류',
                helperText:
                    '미분류로 저장하면 전체 소비에는 반영되지만 '
                    '특정 자원 잔액은 변하지 않습니다.',
                helperMaxLines: 2,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: _unclassifiedValue,
                  child: Text('미분류로 저장'),
                ),
                ...widget.resources.map((resource) {
                  final balance = _calculator.balanceForResource(
                    resource.id,
                    widget.ledger,
                  );

                  return DropdownMenuItem(
                    value: resource.id,
                    child: Text(
                      '${resource.name} · '
                      '${balance.toDisplayString()} TOKEN',
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _classificationSelection = value;
                  _errorText = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: '메모 (선택)',
                border: OutlineInputBorder(),
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
            const SizedBox(height: 32),
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
    );
  }
}
