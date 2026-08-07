import 'exchange_rate.dart';
import 'token_amount.dart';

class DisplayFormatter {
  const DisplayFormatter._();

  static String integer(BigInt value) {
    final negative = value.isNegative;
    final digits = value.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return '${negative ? '-' : ''}$out';
  }

  static String won(BigInt value) => '${integer(value)}원';

  static String token(TokenAmount value, {bool withUnit = true}) {
    final raw = value.toDisplayString();
    final negative = raw.startsWith('-');
    final unsigned = negative ? raw.substring(1) : raw;
    final parts = unsigned.split('.');
    final whole = integer(BigInt.parse(parts[0]));
    final fraction = parts.length == 2 ? '.${parts[1]}' : '';
    final formatted = '${negative ? '-' : ''}$whole$fraction';
    return withUnit ? '$formatted TOKEN' : formatted;
  }

  static String exchangeRate(ExchangeRate value) {
    final raw = value.toDisplayString();
    final parts = raw.split('.');
    final whole = integer(BigInt.parse(parts[0]));
    final fraction = parts.length == 2 ? '.${parts[1]}' : '';
    return '$whole$fraction원 = 1 TOKEN';
  }

  static String date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.'
      '${value.day.toString().padLeft(2, '0')}';

  static String dateTime(DateTime value) =>
      '${date(value)} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
