TOKEN Patch 0014A — Transaction History Widget Test Fix

Cause:
The Refund History section is below the initial viewport in a lazy ListView.
The previous widget test asserted '환불 이력 (0)' before scrolling it into view.

Fix:
- No production code changes.
- No Core changes.
- No UI behavior changes.
- Test now scrolls to Refund History before asserting it.

Expected:
flutter analyze PASS
flutter test PASS
APK build resumes.
