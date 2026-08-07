import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ledger_entry.dart';

class LedgerRepository {
  static const storageKey = 'token.ledger.v1';

  Future<List<LedgerEntry>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => LedgerEntry.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<List<LedgerEntry>> append(LedgerEntry entry) async {
    final updated = [...await loadAll(), entry];
    await saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<List<LedgerEntry>> appendAll(List<LedgerEntry> entries) async {
    final updated = [...await loadAll(), ...entries];
    await saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<void> saveAll(List<LedgerEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(entries.map((item) => item.toJson()).toList()),
    );
  }
}
