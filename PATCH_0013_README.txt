TOKEN Patch 0013 — Pending Queue + Manual Classification

Sprint 2 Phase 3/4

Implemented:
- Pending Queue derived from CURRENT Classification == UNCLASSIFIED
- Pending List
- Pending Detail
- Resource Selection
- Manual Classification
- UNCLASSIFIED Reverse Ledger
- RESOURCE Ledger append
- Classification append
- Pending item removed immediately after classification
- Optional rule suggestion after manual classification
- YES -> merchant-based include keyword rule is created
- NO -> one-time classification only

Important:
- Pending Queue is NOT stored as an Entity.
- Ledger remains append-only.
- Classification remains append-only.
- Transaction remains immutable.
- Existing UNCLASSIFIED Inspector is superseded by Pending Queue.
- No hard delete.
- No transaction mutation.

Tests:
- Pending derivation from current classification
- Pending detail widget flow
- Manual classification Ledger integrity
- Sprint 1 regression remains active
- Patch 0011/0012 tests remain active
