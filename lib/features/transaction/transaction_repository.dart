import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'transaction.dart';

class TransactionRepository {
  static const storageKey = 'token.transactions.v2';

  Future<void> insert(TokenTransaction transaction) async {
    final transactions = await list();

    if (transactions.any((item) => item.id == transaction.id)) {
      throw StateError('Transaction already exists: ${transaction.id}');
    }

    await _write([...transactions, transaction]);
  }

  Future<TokenTransaction?> get(String id) async {
    for (final transaction in await list()) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  Future<List<TokenTransaction>> list() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(
      decoded.map(
        (item) => TokenTransaction.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      ),
    );
  }

  Future<List<TokenTransaction>> loadAll() => list();

  Future<List<TokenTransaction>> append(TokenTransaction transaction) async {
    await insert(transaction);
    return list();
  }

  Future<void> seedIfEmpty(List<TokenTransaction> transactions) async {
    if ((await list()).isNotEmpty || transactions.isEmpty) return;

    final ids = <String>{};
    for (final transaction in transactions) {
      if (!ids.add(transaction.id)) {
        throw StateError(
          'Duplicate Transaction id in migration seed: ${transaction.id}',
        );
      }
    }

    await _write(transactions);
  }

  Future<void> _write(List<TokenTransaction> transactions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }
}
