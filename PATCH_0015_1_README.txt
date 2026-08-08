TOKEN Patch 0015.1 Hotfix

Fixes
1. Keyboard RenderFlex overflow
   - Transaction Create uses scrollable keyboard-safe layout.
   - Resource Create changed from fixed Column + Spacer to ListView.
   - Both screens remain usable while Samsung/Android keyboard is open.

2. Refund dialog Flutter assertion
   - Refund TextEditingController is now owned by a dedicated StatefulWidget.
   - Controller is disposed only when the dialog route widget is actually disposed.
   - Prevents _dependents.isEmpty lifecycle assertion caused by disposing the
     controller immediately after showDialog returned while route teardown was
     still occurring.

3. Refund validation UX
   - Non-numeric: inline error.
   - <= 0: inline error.
   - > remaining refundable KRW: inline error.
   - Invalid input does NOT close the dialog and does NOT call the Core pipeline.
   - Core refund validation remains unchanged as the second safety boundary.

Re-test
A. Open Transaction Create, focus amount/memo, verify no yellow/black overflow.
B. Open Resource Create, focus resource name/initial TOKEN, verify no overflow.
C. Open refund dialog and refund a valid partial amount: no red error screen.
D. Enter amount greater than remaining: dialog stays open with inline error.
E. Enter 0: dialog stays open with inline error.
F. Full refund button works.
G. Then resume Patch 0015 refund/reclassification tests.
