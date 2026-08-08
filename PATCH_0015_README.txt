TOKEN Patch 0015 — Refund + Reclassification UI

Implemented
- Full refund
- Partial refund
- Multiple partial refunds
- Refund validation: > 0 and <= remaining amount
- Refund uses historical appliedExchangeRate
- RefundRepository append
- Reclassification UI from Transaction Detail
- Reclassification uses reverse Ledger + new RESOURCE Ledger
- Partial-refund reclassification moves only remaining effective TOKEN
- Fully refunded transaction cannot be reclassified
- Original Transaction / Ledger / Classification records are never modified

UI
Transaction Detail now shows:
- Refundable remaining KRW
- Reclassify button
- Refund button
- Full refund shortcut
- Partial refund amount input

Navigation note
After Refund/Reclassification, History closes back to Home so the authoritative
Home state is immediately refreshed. Reopen History to inspect the new Ledger
and Classification timeline.

Known planning item
Rule matching false-positive / MatchMode work is NOT included in this patch.
It remains pending Planning/Center review.
