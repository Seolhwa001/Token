import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'transaction.dart';

class TransactionRepository {
  static const _storageKey = 'token.transactions.v1';

  Future<List<TokenTransaction>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => TokenTransaction.fromJson(
              Map<String, Object?>.from(item as Map),
            ))
        .toList(growable: false);
  }

  Future<List<TokenTransaction>> add(TokenTransaction transaction) async {
    final current = await loadAll();
    final updated = [...current, transaction];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    return List.unmodifiable(updated);
  }

  Future<List<TokenTransaction>> loadByResource(String resourceId) async {
    final all = await loadAll();
    return all
        .where((transaction) => transaction.resourceId == resourceId)
        .toList(growable: false);
  }
}
