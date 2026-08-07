import 'exchange_rate.dart';
import 'token_amount.dart';

/// Converts KRW to TOKEN using decimal HALF_UP rounding at scale=2.
///
/// Binary floating point and floor/truncate conversion are not used.
TokenAmount wonToToken({
  required BigInt won,
  required ExchangeRate exchangeRate,
}) {
  final denominator = exchangeRate.wonPerToken;
  final negative = won.isNegative;
  final absoluteWon = won.abs();

  // Convert directly into hundredths of TOKEN.
  final scaledNumerator = absoluteWon * BigInt.from(100);
  final quotient = scaledNumerator ~/ denominator;
  final remainder = scaledNumerator % denominator;

  // HALF_UP: remainder/denominator >= 0.5 => round away from zero.
  final shouldRoundUp = remainder * BigInt.from(2) >= denominator;
  final rounded = shouldRoundUp ? quotient + BigInt.one : quotient;

  return TokenAmount.fromMinorUnits(negative ? -rounded : rounded);
}
