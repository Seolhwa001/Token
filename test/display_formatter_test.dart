import 'package:flutter_test/flutter_test.dart';
import 'package:token/core/display_formatter.dart';
import 'package:token/core/token_amount.dart';

void main() {
  test('won uses thousands separators', () {
    expect(DisplayFormatter.won(BigInt.from(13500)), '13,500원');
    expect(DisplayFormatter.won(BigInt.from(1234567)), '1,234,567원');
  });

  test('TOKEN uses thousands separators and preserves display trim rule', () {
    expect(
      DisplayFormatter.token(TokenAmount.parse('12345.00')),
      '12,345 TOKEN',
    );
    expect(
      DisplayFormatter.token(TokenAmount.parse('12345.50')),
      '12,345.5 TOKEN',
    );
    expect(
      DisplayFormatter.token(TokenAmount.parse('12345.67')),
      '12,345.67 TOKEN',
    );
    expect(
      DisplayFormatter.token(TokenAmount.parse('-12345.67')),
      '-12,345.67 TOKEN',
    );
  });
}
