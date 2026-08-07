import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'ledger_entry.dart';

class LedgerRepository {
  static const storageKey = 'token.ledger.v1';

  Future<List<LedgerEntry>> append(LedgerEntry entry) async {
    return appendAll([entry]);
  }

  Future<List<LedgerEntry>> appendAll(List<LedgerEntry> entries) async {
    if (entries.isEmpty) return _listAll();

    final current = await _listAll();
    final knownIds = current.map((item) => item.id).toSet();

    for (final entry in entries) {
      if (!knownIds.add(entry.id)) {
        throw StateError('Ledger entry already exists: ${entry.id}');
      }
    }

    final updated = [...current, ...entries];
    await _write(updated);
    return List.unmodifiable(updated);
  }

  Future<List<LedgerEntry>> listByTransaction(String transactionId) async {
    return List.unmodifiable(
      (await _listAll())
          .where((entry) => entry.transactionId == transactionId),
    );
  }

  Future<List<LedgerEntry>> listByResource(String resourceId) async {
    return List.unmodifiable(
      (await _listAll()).where(
        (entry) =>
            entry.ledgerType == LedgerType.resource &&
            entry.resourceId == resourceId,
      ),
    );
  }

  Future<List<LedgerEntry>> loadAll() => _listAll();

  Future<void> seedIfEmpty(List<LedgerEntry> entries) async {
    if ((await _listAll()).isNotEmpty || entries.isEmpty) return;

    final ids = <String>{};
    for (final entry in entries) {
      if (!ids.add(entry.id)) {
        throw StateError(
          'Duplicate Ledger id in migration seed: ${entry.id}',
        );
      }
    }

    await _write(entries);
  }

  Future<List<LedgerEntry>> _listAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(
      decoded.map(
        (item) => LedgerEntry.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      ),
    );
  }

  Future<void> _write(List<LedgerEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(entries.map((item) => item.toJson()).toList()),
    );
  }
}
