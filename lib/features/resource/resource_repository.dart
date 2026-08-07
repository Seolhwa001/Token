import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'resource.dart';

class ResourceRepository {
  static const _storageKey = 'token.resources.v1';

  Future<List<Resource>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) =>
            Resource.fromJson(Map<String, Object?>.from(item as Map)))
        .toList(growable: false);
  }

  Future<List<Resource>> add(Resource resource) async {
    final current = await loadAll();
    final updated = [...current, resource];
    await _saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<List<Resource>> replace(Resource resource) async {
    final current = await loadAll();
    final index = current.indexWhere((item) => item.id == resource.id);
    if (index < 0) throw StateError('Resource not found: ${resource.id}');
    final updated = [...current];
    updated[index] = resource;
    await _saveAll(updated);
    return List.unmodifiable(updated);
  }

  Future<void> _saveAll(List<Resource> resources) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(resources.map((item) => item.toJson()).toList()),
    );
  }
}
