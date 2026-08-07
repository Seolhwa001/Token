TOKEN Patch 0004 — Transaction MVP

수정:
- lib/main.dart
- lib/core/exchange_rate.dart
- lib/core/token_converter.dart
- lib/features/home/home_page.dart
- lib/features/resource/resource.dart
- lib/features/resource/resource_repository.dart
- lib/features/resource/widgets/resource_card.dart

추가:
- lib/features/transaction/transaction.dart
- lib/features/transaction/transaction_repository.dart
- lib/features/transaction/transaction_create_page.dart
- test/exchange_rate_test.dart
- test/transaction_test.dart

기능:
- 원화 거래 입력
- 100원 = 1 TOKEN MVP 환율
- HALF_UP / scale=2
- appliedExchangeRate 고정 저장
- 거래 저장 시 자원 잔액 차감
- 음수 TOKEN 허용
- 오늘 소비량 카드 표시
- ExchangeRate도 Fixed Point(scale=2)

적용:
저장소 루트 기준 경로 그대로 덮어쓰기/추가합니다.
.github/workflows는 수정하지 않습니다.
