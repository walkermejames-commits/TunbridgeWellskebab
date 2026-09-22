# Schema decisions

The supplied migrations and RLS policies are retained unchanged. The only implementation hardening made outside the schema is in `create-order`: modifier options are now checked against the selected menu item's mapped modifier groups, and a concurrent idempotency-key collision returns the original order rather than creating or charging a duplicate.

All money remains integer pence. Historic order fee and item snapshots remain immutable.
