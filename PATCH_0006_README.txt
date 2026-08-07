TOKEN Patch 0006 — UNCLASSIFIED Ledger Architecture

Priority: CRITICAL
Breaking Change: YES

수정:
- lib/features/ledger/ledger_entry.dart
- lib/features/ledger/ledger_calculator.dart
- lib/features/analytics/ledger_analytics.dart
- lib/features/transaction/transaction_pipeline.dart

추가:
- test/unclassified_ledger_test.dart

핵심:
- LedgerType: RESOURCE / UNCLASSIFIED / SYSTEM
- 미분류 거래도 UNCLASSIFIED Ledger 생성
- Total Consumption: RESOURCE + UNCLASSIFIED, SYSTEM 제외
- Resource Balance: RESOURCE Ledger만 합산
- UNCLASSIFIED -> RESOURCE 시 기존 Ledger 수정 금지
  +UNCLASSIFIED reverse + -RESOURCE 신규 기록
- Refund는 원본 LedgerType 유지
- Reclassification은 append-only
- 과거 ledgerType 없는 저장 Ledger는 RESOURCE로 호환 로드

.github/workflows는 수정하지 않습니다.
