import 'exchange_rate.dart';
import 'token_amount.dart';

TokenAmount wonToToken({
  required BigInt won,
  required ExchangeRate exchangeRate,
}) {
  final negative = won.isNegative;
  final absoluteWon = won.abs();
  final scaledNumerator = absoluteWon * BigInt.from(10000);
  final denominator = exchangeRate.minorWonPerToken;
  final quotient = scaledNumerator ~/ denominator;
  final remainder = scaledNumerator % denominator;
  final shouldRoundUp = remainder * BigInt.from(2) >= denominator;
  final rounded = shouldRoundUp ? quotient + BigInt.one : quotient;
  return TokenAmount.fromMinorUnits(negative ? -rounded : rounded);
}
