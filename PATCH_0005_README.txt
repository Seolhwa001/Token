TOKEN Patch 0005 — Transaction Pipeline Architecture

CRITICAL / BREAKING CHANGE

Transaction -> Classification -> Ledger -> Resource Balance -> Analytics

주요 변경:
- Transaction에서 resourceId 제거
- Resource에서 balance 제거
- Resource Balance = SUM(Ledger.amount)
- Classification 독립 계층
- Ledger append-only
- Analytics는 Ledger만 읽음
- Lifecycle은 Transaction 외부 append-only event
- Refund = reverse Ledger
- Reclassification = reversal + new Ledger
- UNCLASSIFIED = no Ledger
- TransactionSource 확장 포인트 추가
- 기존 v1 데이터 자동 1회 마이그레이션

ZIP은 변경/추가 파일만 포함합니다.
