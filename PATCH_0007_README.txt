TOKEN Patch 0007 — UNCLASSIFIED UI Integration

Sprint 1 Final Core UI

수정:
- lib/features/transaction/transaction_create_page.dart
- lib/features/home/home_page.dart

추가:
- test/transaction_create_page_test.dart

변경:
1. 거래 분류 기본값을 '미분류로 저장'으로 명시
2. 미분류 선택 시 userResourceId = null
3. Resource 선택 시 기존 RESOURCE Ledger Pipeline 사용
4. 미분류 저장 후 Snackbar 표시
5. Resource 거래 저장 후 Snackbar 표시
6. 거래 화면 Column/Spacer 제거, ListView로 변경
7. 키보드가 올라와도 스크롤 가능하게 하여 Bottom Overflow 제거
8. Core TransactionPipeline/Ledger 로직은 수정하지 않음
