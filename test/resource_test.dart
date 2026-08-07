import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/ledger/ledger_calculator.dart';
import 'package:token/features/ledger/ledger_entry.dart';
import 'package:token/features/resource/resource.dart';

void main() {
  test('resource stores metadata only', () {
    final resource = Resource(
      id: 'resource-1',
      name: '식비',
      colorKey: 'teal',
      createdAt: DateTime.utc(2026, 8, 7),
    );

    final restored = Resource.fromJson(resource.toJson());

    expect(restored.id, resource.id);
    expect(restored.name, resource.name);
    expect(restored.colorKey, resource.colorKey);
    expect(restored.createdAt, resource.createdAt);
  });

  test('resource balance is derived from Ledger', () {
    final ledger = [
      LedgerEntry(
        id: 'grant',
        resourceId: 'resource-1',
        amount: TokenAmount.parse('100.00'),
        type: LedgerEntryType.initialGrant,
        description: '직접 지급',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'purchase',
        resourceId: 'resource-1',
        amount: TokenAmount.parse('-12.34'),
        type: LedgerEntryType.purchase,
        description: '소비',
        transactionId: 'tx-1',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final balance = const LedgerCalculator()
        .balanceForResource('resource-1', ledger);

    expect(balance.toStorageString(), '87.66');
  });

  test('Ledger-derived balance may be negative', () {
    final ledger = [
      LedgerEntry(
        id: 'grant',
        resourceId: 'resource-2',
        amount: TokenAmount.parse('20.00'),
        type: LedgerEntryType.initialGrant,
        description: '직접 지급',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
      LedgerEntry(
        id: 'purchase',
        resourceId: 'resource-2',
        amount: TokenAmount.parse('-30.00'),
        type: LedgerEntryType.purchase,
        description: '소비',
        transactionId: 'tx-2',
        createdAt: DateTime.utc(2026, 8, 7),
      ),
    ];

    final balance = const LedgerCalculator()
        .balanceForResource('resource-2', ledger);

    expect(balance.toStorageString(), '-10.00');
  });
}
