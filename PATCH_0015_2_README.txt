TOKEN Patch 0015.2 — Refunded UNCLASSIFIED Pending Fix

Problem
A fully refunded UNCLASSIFIED Transaction retained current Classification ==
UNCLASSIFIED, so it remained in Pending Queue even though its effective
consumption was zero. Attempting classification then correctly failed in Core
with "Fully refunded transaction cannot be classified."

Fix
Pending Queue remains a derived View, not an Entity.

Actionable Pending condition:
1. Current Classification == UNCLASSIFIED
2. Effective UNCLASSIFIED TOKEN consumption > 0

Full refund:
UNCLASSIFIED -50
UNCLASSIFIED +50
Effective = 0
=> Excluded from Pending Queue.

Partial refund:
UNCLASSIFIED -50
UNCLASSIFIED +20
Effective = -30
=> Remains Pending, displaying 30 TOKEN as classification target.

Historical Classification is NOT mutated.
Historical Ledger is NOT mutated.
Fully refunded transactions remain visible in Transaction History.

Files
- lib/features/pending/pending_queue_page.dart
- lib/features/home/home_page.dart
- test/pending_refund_test.dart
