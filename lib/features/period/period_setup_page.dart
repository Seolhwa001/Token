import 'package:flutter/material.dart';

import 'management_period.dart';

class PeriodSetupPage extends StatefulWidget {
  final Future<void> Function(ManagementPeriod period) onCreate;

  const PeriodSetupPage({
    super.key,
    required this.onCreate,
  });

  @override
  State<PeriodSetupPage> createState() => _PeriodSetupPageState();
}

class _PeriodSetupPageState extends State<PeriodSetupPage> {
  late DateTime _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final initial = _endDate ?? _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _create() async {
    final end = _endDate;
    if (end == null || _saving) return;

    final period = ManagementPeriod(
      startDate: _startDate,
      endDate: end,
    );

    setState(() => _saving = true);
    try {
      await widget.onCreate(period);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TOKEN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '첫 관리 기간을 설정하세요',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'TOKEN은 달력의 월 단위가 아니라, 직접 정한 기간을 기준으로 자원을 관리합니다.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              _DateField(
                label: '시작일',
                value: _formatDate(_startDate),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 12),
              _DateField(
                label: '종료일',
                value: _endDate == null ? '선택하세요' : _formatDate(_endDate!),
                onTap: _pickEndDate,
              ),
              if (_endDate != null) ...[
                const SizedBox(height: 20),
                Text(
                  '총 ${_endDate!.difference(_startDate).inDays + 1}일',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _endDate == null || _saving ? null : _create,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(_saving ? '생성 중...' : '이 기간으로 시작'),
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
              const Icon(Icons.calendar_today_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) =>
    '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
