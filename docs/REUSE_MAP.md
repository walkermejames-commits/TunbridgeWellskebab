# Reuse map from Door in Four and Doorin5

| Existing asset | Useful pattern to carry forward | Tunbridge Wells Kebab adaptation |
| --- | --- | --- |
| `door-in` shared operations platform | Next.js TypeScript, Supabase authentication, administrator controller, driver onboarding, server-only Stripe concept | Separate deployment and schema; one takeaway order lifecycle replaces collection/concierge workflows |
| `door-in` live-readiness gates | Never take a real payment until database/RLS, webhook, proof and operations are checked | Live toggle is blocked by a server-side readiness function and records the owner action |
| `door-in` Cloudflare/OpenNext configuration | PWA/operations deployment pattern and environment separation | Can host `apps/web`; mobile driver app remains Expo-native |
| `Doorin5` local pilot language | Start with a small area and controlled tests rather than nationwide promises | One restaurant, small Tunbridge Wells delivery band and 10–25 test deliveries |
| `Doorin5` money checks | Server truth, itemised charges, payment/refund discipline and smoke tests | Menu subtotal + delivery + fixed £1.00 platform + £0.29 transaction charge; no shopping markup/float model |
| Both repositories | Customer → operator → driver status events and evidence/proof thinking | Kitchen → owner dispatch → driver → customer tracking, with private GPS and proof of delivery |

