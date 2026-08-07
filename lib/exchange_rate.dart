/// KRW per 1 TOKEN, stored as a positive integer amount of won.
///
/// Initial core assumption: exchange rate itself is whole KRW.
/// If design later allows fractional KRW exchange rates, this type must be
/// upgraded to a fixed-point representation as well.
class ExchangeRate {
  final BigInt wonPerToken;

  ExchangeRate(BigInt wonPerToken)
      : assert(wonPerToken > BigInt.zero, 'Exchange rate must be positive.'),
        wonPerToken = wonPerToken;

  factory ExchangeRate.fromInt(int wonPerToken) =>
      ExchangeRate(BigInt.from(wonPerToken));

  @override
  String toString() => wonPerToken.toString();
}
