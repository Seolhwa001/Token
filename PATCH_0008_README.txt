TOKEN Patch 0008 — UNCLASSIFIED Inspector

Sprint 1 Core Verification

수정:
- lib/main.dart
- lib/features/home/home_page.dart

추가:
- lib/features/unclassified/unclassified_inspector_page.dart
- test/unclassified_inspector_test.dart

기능:
- Home에 '미분류 거래 N건' 표시
- 조회 전용 Inspector 화면
- 가맹점 / TOKEN / 원화 / 거래일시 / 메모 표시
- 아직 유효한 UNCLASSIFIED Ledger만 표시
- 역분개되어 Resource로 분류된 거래는 Inspector에서 자동 제외
- 앱 재실행 시 TransactionRepository에서 거래 원본을 다시 불러옴
- 분류 / 수정 / 삭제 / 환불 기능 없음

Core Ledger 및 Transaction Pipeline은 수정하지 않습니다.
