import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'resource.dart';

class ResourceRepository {
  static const storageKey = 'token.resources.v2';

  Future<List<Resource>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Resource.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<List<Resource>> add(Resource resource) async {
    final updated = [...await loadAll(), resource];
    await saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<void> saveAll(List<Resource> resources) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(resources.map((item) => item.toJson()).toList()),
    );
  }
}
