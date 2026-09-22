# Implementation reuse map

The source projects were inspected read-only on 22 September 2026.

| Source | Reused engineering lesson | Deliberately excluded |
| --- | --- | --- |
| `door-in` | Separate customer, operations and driver workspaces; server-verified roles; protected payment/webhook configuration; readiness gates | Door in Four branding, collection marketplace domain model and shared cross-business tables |
| `Doorin5` | Small-pilot discipline, fake-payment clarity, readiness reporting, status-event trail and smoke-test mindset | Concierge basket markup, fulfilment float, age-check and Doorin5 public identity |
| This product | Restaurant order snapshots, transparent £1.00 / £0.29 policy, kitchen-led preparation and private active-only driver location | Any public address/GPS route or client-authoritative money/status update |

No source implementation was copied. The patterns above are adapted to the supplied Supabase schema and this product's own identity.
