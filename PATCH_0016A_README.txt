TOKEN Patch 0016A — Resource Detail Query Repair

Replaces the entire resource_detail_query.dart.

Fixes:
- malformed braces introduced during manual patching
- all one-line if/continue/return lint violations
- preserves Patch 0016 Resource Detail calculation behavior

Replace:
lib/features/resource/resource_detail_query.dart

with the file in this patch.
