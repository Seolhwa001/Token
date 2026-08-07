import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'transaction.dart';

class TransactionRepository {
  static const storageKey = 'token.transactions.v2';

  Future<List<TokenTransaction>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TokenTransaction.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<List<TokenTransaction>> append(TokenTransaction transaction) async {
    final updated = [...await loadAll(), transaction];
    await saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<void> saveAll(List<TokenTransaction> transactions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }
}
