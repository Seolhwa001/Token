import 'package:flutter_test/flutter_test.dart';

import 'package:token/core/exchange_rate.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/classification/classification.dart';
import 'package:token/features/classification/classification_rule.dart';
import 'package:token/features/classification/rule_engine.dart';
import 'package:token/features/transaction/transaction.dart';

TokenTransaction _tx({
  String merchant = '',
  String memo = '',
}) {
  return TokenTransaction(
    id: 'tx-rule',
    source: TransactionSource.manual,
    wonAmount: BigInt.from(10000),
    tokenAmount: TokenAmount.parse('100.00'),
    appliedExchangeRate: ExchangeRate.parse('100.00'),
    merchant: merchant,
    memo: memo,
    occurredAt: DateTime.utc(2026, 8, 7),
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

ClassificationRule _rule({
  required String id,
  required int priority,
  required List<String> include,
  List<String> exclude = const [],
  String resource = 'food',
  bool enabled = true,
  bool deleted = false,
}) {
  final now = DateTime.utc(2026, 8, 7);

  return ClassificationRule(
    id: id,
    enabled: enabled,
    priority: priority,
    includeKeywords: include,
    excludeKeywords: exclude,
    resourceId: resource,
    deleted: deleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('include keyword matches merchant', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'mcd',
          priority: 1,
          include: const ['맥도날드'],
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: '맥도날드 강남역점'),
    );

    expect(result.status, ClassificationStatus.autoClassified);
    expect(result.resourceId, 'food');
    expect(result.ruleId, 'mcd');
  });

  test('include keyword also matches memo', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'fuel',
          priority: 1,
          include: const ['주유'],
          resource: 'vehicle',
        ),
      ],
    );

    final result = engine.classify(
      _tx(
        merchant: 'GS칼텍스',
        memo: '출근 전 주유',
      ),
    );

    expect(result.resourceId, 'vehicle');
  });

  test('exclude keyword blocks otherwise matching rule', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'gs',
          priority: 1,
          include: const ['GS'],
          exclude: const ['상품권'],
          resource: 'vehicle',
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: 'GS 상품권'),
    );

    expect(result.status, ClassificationStatus.unclassified);
    expect(result.resourceId, isNull);
  });

  test('priority ASC wins and processing stops at first match', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'generic',
          priority: 20,
          include: const ['맥'],
          resource: 'other',
        ),
        _rule(
          id: 'specific',
          priority: 10,
          include: const ['맥도날드'],
          resource: 'food',
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: '맥도날드'),
    );

    expect(result.ruleId, 'specific');
    expect(result.resourceId, 'food');
  });

  test('disabled rule is ignored', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'disabled',
          priority: 1,
          include: const ['맥도날드'],
          enabled: false,
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: '맥도날드'),
    );

    expect(result.status, ClassificationStatus.unclassified);
  });

  test('soft deleted rule is ignored', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'deleted',
          priority: 1,
          include: const ['맥도날드'],
          deleted: true,
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: '맥도날드'),
    );

    expect(result.status, ClassificationStatus.unclassified);
  });

  test('matching is case insensitive', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'case',
          priority: 1,
          include: const ['STARBUCKS'],
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: 'Starbucks Gangnam'),
    );

    expect(result.status, ClassificationStatus.autoClassified);
  });

  test('no rule match returns UNCLASSIFIED', () {
    final engine = RuleEngine(
      rules: [
        _rule(
          id: 'mcd',
          priority: 1,
          include: const ['맥도날드'],
        ),
      ],
    );

    final result = engine.classify(
      _tx(merchant: '스타벅스'),
    );

    expect(result.status, ClassificationStatus.unclassified);
    expect(result.resourceId, isNull);
    expect(result.ruleId, isNull);
  });
}
