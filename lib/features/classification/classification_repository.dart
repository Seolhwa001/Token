import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'classification.dart';

class ClassificationRepository {
  static const storageKey = 'token.classifications.v1';

  Future<void> append(ClassificationResult result) async {
    final all = await _listAll();

    if (all.any((item) => item.id == result.id)) {
      throw StateError('Classification already exists: ${result.id}');
    }

    await _write([...all, result]);
  }

  Future<ClassificationResult?> getCurrent(String transactionId) async {
    final history = await getHistory(transactionId);
    if (history.isEmpty) return null;
    return history.last;
  }

  Future<List<ClassificationResult>> getHistory(String transactionId) async {
    final history = (await _listAll())
        .where((item) => item.transactionId == transactionId)
        .toList(growable: false)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return List.unmodifiable(history);
  }

  Future<List<ClassificationResult>> loadAll() => _listAll();

  Future<void> seedIfEmpty(List<ClassificationResult> results) async {
    if ((await _listAll()).isNotEmpty || results.isEmpty) return;

    final ids = <String>{};
    for (final result in results) {
      if (!ids.add(result.id)) {
        throw StateError(
          'Duplicate Classification id in migration seed: ${result.id}',
        );
      }
    }

    await _write(results);
  }

  Future<List<ClassificationResult>> _listAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(
      decoded.map(
        (item) => ClassificationResult.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      ),
    );
  }

  Future<void> _write(List<ClassificationResult> results) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(results.map((item) => item.toJson()).toList()),
    );
  }
}
