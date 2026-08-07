import 'package:flutter/material.dart';
import '../../core/token_amount.dart';
import 'resource.dart';
import 'resource_creation.dart';

class ResourceCreatePage extends StatefulWidget {
  const ResourceCreatePage({super.key});

  @override
  State<ResourceCreatePage> createState() => _ResourceCreatePageState();
}

class _ResourceCreatePageState extends State<ResourceCreatePage> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '0');
  String _selectedColorKey = 'teal';
  String? _errorText;

  static const _colors = <String, Color>{
    'teal': Colors.teal,
    'blue': Colors.blue,
    'green': Colors.green,
    'orange': Colors.orange,
    'purple': Colors.purple,
    'red': Colors.red,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = '자원 이름을 입력하세요.');
      return;
    }

    TokenAmount initialAmount;
    try {
      initialAmount = TokenAmount.parse(_amountController.text);
    } on FormatException {
      setState(() => _errorText = 'TOKEN은 소수 둘째 자리까지 입력할 수 있습니다.');
      return;
    }

    final now = DateTime.now();
    Navigator.of(context).pop(
      ResourceCreation(
        resource: Resource(
          id: '${now.microsecondsSinceEpoch}',
          name: name,
          colorKey: _selectedColorKey,
          createdAt: now,
        ),
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 자원')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('사용할 자원을 만드세요',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('초기 TOKEN 지급도 Ledger에 기록됩니다. 음수도 허용됩니다.'),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '자원 이름',
                  hintText: '예: 식비, 차량비, 여가',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: '초기 TOKEN',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text('색상', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _colors.entries.map((entry) {
                  final selected = entry.key == _selectedColorKey;
                  return InkWell(
                    onTap: () => setState(() => _selectedColorKey = entry.key),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                            : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 20),
                Text(_errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _create,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('자원 생성'),
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
