import '../transaction/transaction.dart';
import 'classification.dart';
import 'classification_rule.dart';

class RuleEngine {
  final List<ClassificationRule> rules;

  const RuleEngine({this.rules = const []});

  ClassificationResult classify(TokenTransaction transaction) {
    final candidates = rules.where((rule) {
      if (!rule.enabled) return false;
      final keyword = rule.keyword.toLowerCase();
      return transaction.merchant.toLowerCase().contains(keyword) ||
          transaction.memo.toLowerCase().contains(keyword);
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));

    final now = DateTime.now();
    if (candidates.isEmpty) {
      return ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-classification',
        transactionId: transaction.id,
        status: ClassificationStatus.unclassified,
        createdAt: now,
      );
    }

    final matched = candidates.first;
    return ClassificationResult(
      id: '${now.microsecondsSinceEpoch}-classification',
      transactionId: transaction.id,
      status: ClassificationStatus.autoClassified,
      resourceId: matched.resourceId,
      ruleId: matched.id,
      createdAt: now,
    );
  }
}
