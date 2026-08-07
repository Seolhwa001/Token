/// Fixed-point TOKEN amount with scale = 2.
///
/// Internally stores hundredths of TOKEN as [BigInt].
/// No binary floating point is used.
class TokenAmount implements Comparable<TokenAmount> {
  static const int scale = 2;
  static final BigInt _factor = BigInt.from(100);

  final BigInt minorUnits;

  const TokenAmount._(this.minorUnits);

  factory TokenAmount.fromMinorUnits(BigInt minorUnits) =>
      TokenAmount._(minorUnits);

  factory TokenAmount.fromInt(int wholeTokens) =>
      TokenAmount._(BigInt.from(wholeTokens) * _factor);

  factory TokenAmount.parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('TOKEN amount cannot be empty.');
    }

    final negative = trimmed.startsWith('-');
    final unsigned = (trimmed.startsWith('-') || trimmed.startsWith('+'))
        ? trimmed.substring(1)
        : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2) {
      throw FormatException('Invalid TOKEN amount: $value');
    }

    final whole = parts[0].isEmpty ? BigInt.zero : BigInt.parse(parts[0]);
    final fractionalRaw = parts.length == 2 ? parts[1] : '';
    if (fractionalRaw.length > scale) {
      throw FormatException('TOKEN supports at most 2 decimal places: $value');
    }

    final fractional = fractionalRaw.padRight(scale, '0');
    final minor = whole * _factor +
        (fractional.isEmpty ? BigInt.zero : BigInt.parse(fractional));
    return TokenAmount._(negative ? -minor : minor);
  }

  TokenAmount operator +(TokenAmount other) =>
      TokenAmount._(minorUnits + other.minorUnits);

  TokenAmount operator -(TokenAmount other) =>
      TokenAmount._(minorUnits - other.minorUnits);

  TokenAmount operator -() => TokenAmount._(-minorUnits);

  bool get isNegative => minorUnits.isNegative;
  bool get isZero => minorUnits == BigInt.zero;

  /// Canonical storage form: always exactly 2 decimal places.
  String toStorageString() {
    final negative = minorUnits.isNegative;
    final abs = minorUnits.abs();
    final whole = abs ~/ _factor;
    final fraction = (abs % _factor).toString().padLeft(scale, '0');
    return '${negative ? '-' : ''}$whole.$fraction';
  }

  /// Display-only formatting:
  /// 120.00 -> 120
  /// 138.50 -> 138.5
  /// 138.55 -> 138.55
  String toDisplayString() {
    final storage = toStorageString();
    if (storage.endsWith('.00')) return storage.substring(0, storage.length - 3);
    if (storage.endsWith('0')) return storage.substring(0, storage.length - 1);
    return storage;
  }

  @override
  int compareTo(TokenAmount other) => minorUnits.compareTo(other.minorUnits);

  @override
  bool operator ==(Object other) =>
      other is TokenAmount && other.minorUnits == minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;

  @override
  String toString() => toStorageString();
}
