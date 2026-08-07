import '../transaction/transaction.dart';
import 'classification.dart';
import 'classification_rule.dart';
import 'rule_matcher.dart';

class RuleEngine {
  final List<ClassificationRule> rules;
  final RuleMatcher matcher;

  const RuleEngine({
    this.rules = const [],
    this.matcher = const RuleMatcher(),
  });

  ClassificationResult classify(TokenTransaction transaction) {
    return classifyWithRules(
      transaction,
      rules,
    );
  }

  ClassificationResult classifyWithRules(
    TokenTransaction transaction,
    Iterable<ClassificationRule> sourceRules,
  ) {
    final ordered = sourceRules
        .where((rule) => rule.enabled && !rule.deleted)
        .toList(growable: false)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    ClassificationRule? matched;

    for (final rule in ordered) {
      if (matcher.matches(rule, transaction)) {
        matched = rule;
        break;
      }
    }

    final now = DateTime.now();

    if (matched == null) {
      return ClassificationResult(
        id: '${now.microsecondsSinceEpoch}-classification',
        transactionId: transaction.id,
        status: ClassificationStatus.unclassified,
        createdAt: now,
      );
    }

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
