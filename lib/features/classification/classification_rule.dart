class ClassificationRule {
  final String id;
  final bool enabled;
  final int priority;
  final List<String> includeKeywords;
  final List<String> excludeKeywords;
  final String resourceId;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClassificationRule({
    required this.id,
    required this.resourceId,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.enabled = true,
    this.includeKeywords = const [],
    this.excludeKeywords = const [],
    this.deleted = false,
  }) : assert(
          includeKeywords.length > 0,
          'At least one include keyword is required.',
        );

  String get keyword => includeKeywords.first;

  ClassificationRule copyWith({
    bool? enabled,
    int? priority,
    List<String>? includeKeywords,
    List<String>? excludeKeywords,
    String? resourceId,
    bool? deleted,
    DateTime? updatedAt,
  }) {
    return ClassificationRule(
      id: id,
      enabled: enabled ?? this.enabled,
      priority: priority ?? this.priority,
      includeKeywords: includeKeywords ?? this.includeKeywords,
      excludeKeywords: excludeKeywords ?? this.excludeKeywords,
      resourceId: resourceId ?? this.resourceId,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'enabled': enabled,
        'priority': priority,
        'includeKeywords': includeKeywords,
        'excludeKeywords': excludeKeywords,
        'resourceId': resourceId,
        'deleted': deleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ClassificationRule.fromJson(Map<String, Object?> json) {
    final legacyKeyword = json['keyword'] as String?;
    final include = (json['includeKeywords'] as List<dynamic>?)
            ?.map((item) => item as String)
            .toList(growable: false) ??
        [
          if (legacyKeyword != null && legacyKeyword.isNotEmpty) legacyKeyword,
        ];

    return ClassificationRule(
      id: json['id'] as String,
      enabled: (json['enabled'] as bool?) ?? true,
      priority: json['priority'] as int,
      includeKeywords: include,
      excludeKeywords: (json['excludeKeywords'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList(growable: false) ??
          const [],
      resourceId: json['resourceId'] as String,
      deleted: (json['deleted'] as bool?) ?? false,
      createdAt: DateTime.parse(
        (json['createdAt'] as String?) ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updatedAt'] as String?) ??
            (json['createdAt'] as String?) ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
    );
  }
}
