TOKEN Patch 0016 — Resource Detail

Adds:
- Ledger-derived Resource Detail query
- Resource balance / granted TOKEN / effective consumption
- Transaction-level Resource consumption list
- Full refund = REFUNDED / 0 TOKEN
- Partial refund = PARTIALLY_REFUNDED / remaining TOKEN
- Current classification determines Resource membership
- Shared existing TransactionDetailPage for Refund/Reclassification
- ResourceCard navigation support

IMPORTANT:
HOME_PAGE_PATCH.txt contains three small edits for the current HomePage.
This is intentionally an edit instruction rather than a full replacement so
the latest 0015.2b Home code is not overwritten by a stale copy.
