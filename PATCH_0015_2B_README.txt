TOKEN Patch 0015.2b — Pending Widget Regression Fix

Cause:
The existing PendingDetail widget test intentionally constructs the page with
an empty Ledger. Patch 0015.2 interpreted empty Ledger as zero effective
consumption, disabled classification, and broke the Sprint 2 regression test.

Fix:
- When PendingDetail receives Ledger entries, use effective UNCLASSIFIED
  remainder (refund-aware behavior).
- When Ledger is empty, preserve the pre-existing behavior and use the
  Transaction TOKEN amount as the classification target.

This preserves the new full/partial-refund Pending behavior in production while
keeping the existing widget contract and regression test valid.
