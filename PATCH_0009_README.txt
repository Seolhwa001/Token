TOKEN Patch 0009 — Sprint 1 Core Verification

IMPORTANT:
- Verification only.
- No production code changes.
- No UI changes.
- No Sprint 2 feature implementation.

Added:
- test/sprint1_core_verification_test.dart

Automated verification:
1. Reverse Ledger
2. Reclassification
3. Original Ledger record remains unchanged
4. Resource Balance = SUM(RESOURCE Ledger)
5. Analytics = RESOURCE + UNCLASSIFIED, SYSTEM excluded
6. Persistence after simulated restart
7. AppliedExchangeRate preservation
8. Historical Ledger unchanged after default exchange-rate change

STATIC AUDIT FINDING:
lib/features/ledger/ledger_repository.dart currently exposes public saveAll().
This permits replacing the full stored Ledger list and therefore does not
strictly enforce Center's INSERT-only / no UPDATE / no DELETE rule at the
repository boundary.

No production fix is included because Sprint 1 scope/architecture is frozen.
This finding must be reported to Center for approval before changing Core code.
