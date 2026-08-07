class ClassificationRule {
  final String id;
  final String keyword;
  final String resourceId;
  final bool enabled;
  final int priority;

  const ClassificationRule({
    required this.id,
    required this.keyword,
    required this.resourceId,
    this.enabled = true,
    this.priority = 0,
  });
}
