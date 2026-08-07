TOKEN Patch 0011 — Sprint 2 Repository Contracts

Phase 1: Repository Layer
UI changes: NONE

Implemented contracts:
- TransactionRepository
  - insert
  - get
  - list
- ClassificationRepository
  - append
  - getCurrent
  - getHistory
- LedgerRepository
  - append
  - listByTransaction
  - listByResource
- RuleRepository
  - insert
  - update
  - softDelete
  - listEnabled
- RefundRepository
  - append
  - listByTransaction

Repository enforcement:
- Duplicate Transaction IDs rejected
- Duplicate Classification IDs rejected
- Duplicate Ledger IDs rejected
- Duplicate active Rule priorities rejected
- Rule hard delete is not implemented
- Ledger public saveAll removed
- Transaction public saveAll removed
- Classification public saveAll removed
- Legacy migration uses seedIfEmpty initialization only

Rule model prepared for Sprint 2:
- Enabled
- Priority
- Include Keywords
- Exclude Keywords
- Resource
- Soft Delete
- Legacy keyword getter retained temporarily for Sprint 1 RuleEngine compatibility

No UI or Rule Engine matching behavior is changed by this patch.
