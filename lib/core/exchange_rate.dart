/// Fixed-point KRW-per-TOKEN exchange rate with scale = 2.
class ExchangeRate implements Comparable<ExchangeRate> {
  static const int scale = 2;
  static final BigInt _factor = BigInt.from(100);
  final BigInt minorWonPerToken;

  ExchangeRate._(this.minorWonPerToken) {
    if (minorWonPerToken <= BigInt.zero) {
      throw ArgumentError.value(minorWonPerToken, 'minorWonPerToken',
          'Exchange rate must be positive.');
    }
  }

  factory ExchangeRate.fromInt(int wonPerToken) =>
      ExchangeRate._(BigInt.from(wonPerToken) * _factor);

  factory ExchangeRate.parse(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Exchange rate cannot be empty.');
    }
    if (trimmed.startsWith('-')) {
      throw const FormatException('Exchange rate must be positive.');
    }
    final unsigned = trimmed.startsWith('+') ? trimmed.substring(1) : trimmed;
    final parts = unsigned.split('.');
    if (parts.length > 2) throw FormatException('Invalid exchange rate: $value');
    final whole = parts[0].isEmpty ? BigInt.zero : BigInt.parse(parts[0]);
    final raw = parts.length == 2 ? parts[1] : '';
    if (raw.length > scale) {
      throw FormatException('Exchange rate supports at most 2 decimal places: $value');
    }
    final frac = raw.padRight(scale, '0');
    final minor = whole * _factor +
        (frac.isEmpty ? BigInt.zero : BigInt.parse(frac));
    if (minor <= BigInt.zero) {
      throw const FormatException('Exchange rate must be positive.');
    }
    return ExchangeRate._(minor);
  }

  String toStorageString() {
    final whole = minorWonPerToken ~/ _factor;
    final fraction = (minorWonPerToken % _factor).toString().padLeft(scale, '0');
    return '$whole.$fraction';
  }

  String toDisplayString() {
    final storage = toStorageString();
    if (storage.endsWith('.00')) return storage.substring(0, storage.length - 3);
    if (storage.endsWith('0')) return storage.substring(0, storage.length - 1);
    return storage;
  }

  @override
  int compareTo(ExchangeRate other) =>
      minorWonPerToken.compareTo(other.minorWonPerToken);

  @override
  bool operator ==(Object other) =>
      other is ExchangeRate && other.minorWonPerToken == minorWonPerToken;

  @override
  int get hashCode => minorWonPerToken.hashCode;

  @override
  String toString() => toStorageString();
}
