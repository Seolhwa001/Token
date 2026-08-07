TOKEN Patch 0014 — Transaction History + Display Formatter

Implemented:
- Transaction History (newest first)
- Transaction Detail
- Merchant / DateTime / Won / TOKEN / Resource / Classification / Refund state
- Classification History
- Ledger Timeline
- Refund History derived from Ledger
- Home entry point for Transaction History
- Shared DisplayFormatter
- Thousands separators for Won and TOKEN
- Existing TOKEN trailing-zero display rule preserved
- Resource Card number formatting
- Pending Queue number formatting
- Date/DateTime formatting unified

Examples:
13500 -> 13,500원
1234567 -> 1,234,567원
12345.00 TOKEN -> 12,345 TOKEN
12345.50 TOKEN -> 12,345.5 TOKEN
12345.67 TOKEN -> 12,345.67 TOKEN

Storage values are unchanged. Display only.

No Transaction, Classification, Ledger, or historical exchange-rate mutation.
Sprint 1 and prior Sprint 2 regression tests remain active.
