enum ClassificationStatus {
  autoClassified,
  userClassified,
  unclassified,
}

class ClassificationResult {
  final String id;
  final String transactionId;
  final ClassificationStatus status;
  final String? resourceId;
  final String? ruleId;
  final DateTime createdAt;

  const ClassificationResult({
    required this.id,
    required this.transactionId,
    required this.status,
    required this.createdAt,
    this.resourceId,
    this.ruleId,
  });

  bool get isClassified =>
      status != ClassificationStatus.unclassified && resourceId != null;

  Map<String, Object?> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'status': status.name,
        'resourceId': resourceId,
        'ruleId': ruleId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ClassificationResult.fromJson(Map<String, Object?> json) =>
      ClassificationResult(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        status: ClassificationStatus.values.byName(json['status'] as String),
        resourceId: json['resourceId'] as String?,
        ruleId: json['ruleId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
