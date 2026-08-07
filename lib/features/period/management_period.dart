class ManagementPeriod {
  final DateTime startDate;
  final DateTime endDate;

  ManagementPeriod({
    required DateTime startDate,
    required DateTime endDate,
  })  : startDate = _dateOnly(startDate),
        endDate = _dateOnly(endDate) {
    if (_dateOnly(endDate).isBefore(_dateOnly(startDate))) {
      throw ArgumentError('endDate must not be before startDate');
    }
  }

  int get totalDays => endDate.difference(startDate).inDays + 1;

  int remainingDaysOn(DateTime now) {
    final today = _dateOnly(now);
    if (today.isAfter(endDate)) return 0;
    if (today.isBefore(startDate)) return totalDays;
    return endDate.difference(today).inDays + 1;
  }

  Map<String, String> toMap() => {
        'startDate': _toIsoDate(startDate),
        'endDate': _toIsoDate(endDate),
      };

  factory ManagementPeriod.fromMap(Map<String, String> map) {
    final start = map['startDate'];
    final end = map['endDate'];
    if (start == null || end == null) {
      throw const FormatException('ManagementPeriod fields are missing');
    }
    return ManagementPeriod(
      startDate: DateTime.parse(start),
      endDate: DateTime.parse(end),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _toIsoDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
