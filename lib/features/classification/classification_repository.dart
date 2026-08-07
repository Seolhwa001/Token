import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'classification.dart';

class ClassificationRepository {
  static const storageKey = 'token.classifications.v1';

  Future<List<ClassificationResult>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ClassificationResult.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<List<ClassificationResult>> append(ClassificationResult result) async {
    final updated = [...await loadAll(), result];
    await saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<void> saveAll(List<ClassificationResult> results) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(results.map((item) => item.toJson()).toList()),
    );
  }
}
