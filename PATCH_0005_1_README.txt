TOKEN Patch 0005.1 Hotfix

수정 파일:
- test/resource_test.dart
- test/transaction_test.dart

원인:
Patch 0005 Breaking Change에서 Resource.balance 및 Transaction.resourceId를 제거했으나
기존 Patch 0003/0004 테스트가 예전 구조를 참조하여 flutter analyze가 실패함.

앱 소스는 수정하지 않음.
