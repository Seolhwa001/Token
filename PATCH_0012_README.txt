TOKEN Patch 0012 — Rule Engine Complete

Sprint 2 Phase 2

Implemented:
- RuleMatcher
- Include Keywords
- Exclude Keywords
- Enabled filtering
- Soft Deleted filtering
- Priority ASC
- First Match -> Stop
- Case-insensitive matching
- Merchant + Memo matching
- Persisted RuleRepository integration with TransactionPipeline
- AUTO_CLASSIFIED -> RESOURCE Ledger
- No Match -> UNCLASSIFIED Ledger

Compatibility:
- RuleEngine(rules: [...]) remains supported for existing tests.
- Existing manual classification flow remains unchanged.
- Existing refund/reclassification flow remains unchanged.

UI:
- No Rule CRUD UI in this patch.
- No Pending Queue modification in this patch.

Tests:
- Rule Engine unit tests
- Automatic Classification Pipeline tests
- Sprint 1 regression suite remains active.
