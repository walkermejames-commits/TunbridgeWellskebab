# Supabase Edge Functions

| Function | Caller | What it protects |
| --- | --- | --- |
| `create-order` | authenticated customer | server-side menu price, delivery fee, £1.00/£0.29 fee snapshot, Stripe PaymentIntent |
| `assign-driver` | owner or kitchen | available-driver check, legal state transition and audit event |
| `update-order-status` | kitchen, driver or owner | role-specific state changes, proof requirement and stopping GPS on finish |
| `record-driver-location` | assigned driver only | device coordinate validation, anti-jump check and active-order-only realtime location |
| `stripe-webhook` | Stripe only | signed payment confirmation; deploy with `--no-verify-jwt` |
| `set-runtime-mode` | owner only | audited, fail-closed Demo/Live gate; checks server configuration and minimum operational records |

Before deploying, set `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `TWK_APP_ORIGIN` and, in Live mode, Stripe secrets. Do not place any of them in client code.

