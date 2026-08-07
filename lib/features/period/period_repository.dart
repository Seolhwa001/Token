import 'package:shared_preferences/shared_preferences.dart';

import 'management_period.dart';

class PeriodRepository {
  static const _startKey = 'active_period_start';
  static const _endKey = 'active_period_end';

  Future<ManagementPeriod?> loadActivePeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getString(_startKey);
    final end = prefs.getString(_endKey);

    if (start == null || end == null) return null;

    try {
      return ManagementPeriod(
        startDate: DateTime.parse(start),
        endDate: DateTime.parse(end),
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  Future<void> saveActivePeriod(ManagementPeriod period) async {
    final prefs = await SharedPreferences.getInstance();
    final data = period.toMap();
    await prefs.setString(_startKey, data['startDate']!);
    await prefs.setString(_endKey, data['endDate']!);
  }
}
