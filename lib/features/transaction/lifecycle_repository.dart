import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lifecycle_event.dart';

class LifecycleRepository {
  static const storageKey = 'token.transaction_lifecycle.v1';

  Future<List<TransactionLifecycleEvent>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TransactionLifecycleEvent.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> append(TransactionLifecycleEvent event) async {
    final current = await loadAll();
    await saveAll([...current, event]);
  }

  Future<void> saveAll(List<TransactionLifecycleEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(events.map((item) => item.toJson()).toList()),
    );
  }
}
