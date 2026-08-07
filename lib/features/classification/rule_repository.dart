import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'classification_rule.dart';

class RuleRepository {
  static const storageKey = 'token.classification_rules.v1';

  Future<void> insert(ClassificationRule rule) async {
    final rules = await _listAll();

    if (rules.any((item) => item.id == rule.id)) {
      throw StateError('Rule already exists: ${rule.id}');
    }

    _assertUniquePriority(
      rule.priority,
      rules.where((item) => !item.deleted),
    );

    await _write([...rules, rule]);
  }

  Future<void> update(ClassificationRule rule) async {
    final rules = await _listAll();
    final index = rules.indexWhere((item) => item.id == rule.id);

    if (index < 0) {
      throw StateError('Rule not found: ${rule.id}');
    }

    if (rules[index].deleted) {
      throw StateError('Deleted rule cannot be updated: ${rule.id}');
    }

    _assertUniquePriority(
      rule.priority,
      rules.where((item) => !item.deleted && item.id != rule.id),
    );

    final updated = [...rules];
    updated[index] = rule;
    await _write(updated);
  }

  Future<void> softDelete(String id) async {
    final rules = await _listAll();
    final index = rules.indexWhere((item) => item.id == id);

    if (index < 0) {
      throw StateError('Rule not found: $id');
    }

    final existing = rules[index];
    if (existing.deleted) return;

    final updated = [...rules];
    updated[index] = existing.copyWith(
      enabled: false,
      deleted: true,
      updatedAt: DateTime.now(),
    );

    await _write(updated);
  }

  Future<List<ClassificationRule>> listEnabled() async {
    final rules = (await _listAll())
        .where((item) => item.enabled && !item.deleted)
        .toList(growable: false)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return List.unmodifiable(rules);
  }

  Future<List<ClassificationRule>> listAllIncludingDeleted() => _listAll();

  void _assertUniquePriority(
    int priority,
    Iterable<ClassificationRule> rules,
  ) {
    if (rules.any((item) => item.priority == priority)) {
      throw StateError('Duplicate rule priority is forbidden: $priority');
    }
  }

  Future<List<ClassificationRule>> _listAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);

    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return List.unmodifiable(
      decoded.map(
        (item) => ClassificationRule.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      ),
    );
  }

  Future<void> _write(List<ClassificationRule> rules) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      storageKey,
      jsonEncode(rules.map((item) => item.toJson()).toList()),
    );
  }
}
