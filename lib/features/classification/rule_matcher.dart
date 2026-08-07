import '../transaction/transaction.dart';
import 'classification_rule.dart';

class RuleMatcher {
  const RuleMatcher();

  bool matches(
    ClassificationRule rule,
    TokenTransaction transaction,
  ) {
    if (!rule.enabled || rule.deleted) return false;

    final searchable = _normalize(
      '${transaction.merchant} ${transaction.memo}',
    );

    final includes = rule.includeKeywords
        .map(_normalize)
        .where((keyword) => keyword.isNotEmpty)
        .toList(growable: false);

    if (includes.isEmpty) return false;

    final includeMatched = includes.any(searchable.contains);
    if (!includeMatched) return false;

    final excludes = rule.excludeKeywords
        .map(_normalize)
        .where((keyword) => keyword.isNotEmpty);

    if (excludes.any(searchable.contains)) return false;

    return true;
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
