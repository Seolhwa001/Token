import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/token_amount.dart';
import 'package:token/features/resource/resource.dart';

void main() {
  test('resource preserves decimal TOKEN balance', () {
    final resource = Resource(
      id: 'resource-1',
      name: '식비',
      balance: TokenAmount.parse('138.50'),
      colorKey: 'teal',
      createdAt: DateTime.utc(2026, 8, 7),
    );

    expect(resource.balance.toStorageString(), '138.50');
    expect(resource.balance.toDisplayString(), '138.5');
  });

  test('resource allows negative initial TOKEN', () {
    final resource = Resource(
      id: 'resource-2',
      name: '여가',
      balance: TokenAmount.parse('-12.34'),
      colorKey: 'purple',
      createdAt: DateTime.utc(2026, 8, 7),
    );

    expect(resource.balance.isNegative, isTrue);
    expect(resource.balance.toDisplayString(), '-12.34');
  });

  test('resource JSON round trip is lossless', () {
    final source = Resource(
      id: 'resource-3',
      name: '차량비',
      balance: TokenAmount.parse('100.00'),
      colorKey: 'blue',
      createdAt: DateTime.utc(2026, 8, 7, 12, 30),
    );

    final restored = Resource.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.name, source.name);
    expect(restored.balance, source.balance);
    expect(restored.colorKey, source.colorKey);
    expect(restored.createdAt, source.createdAt);
  });
}
