# Tunbridge Wells Kebab

Tunbridge Wells Kebab is a single-takeaway ordering, dispatch and driver-tracking platform. It starts as one tightly controlled local pilot: customers order the photographed menu, the kitchen accepts the order, an owner assigns a driver, and the customer follows that delivery on a real map.

It is deliberately a separate product from Door in Four and Doorin5. It reuses their useful engineering lessons—role-controlled dispatch, server-side payments, Supabase RLS, a live-readiness gate and driver workflow—but it has its own brand, menu, pricing and database.

## What this repository contains now

- A complete two-prompt build brief for a coding agent: [`docs/TWO_PROMPT_BUILD.md`](docs/TWO_PROMPT_BUILD.md).
- An implementation architecture that can produce a web PWA plus Android/iOS driver app: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
- A real Supabase schema, row-level-security design, pricing rules and menu seed: [`supabase/`](supabase/).
- Edge Function contracts for server-authoritative ordering, driver assignment, Stripe webhooks and GPS updates.
- A map-tracking contract with privacy, consent, realtime and loss-of-signal rules: [`docs/MAP_TRACKING.md`](docs/MAP_TRACKING.md).

The repository is intentionally **not live-money ready** until the planned Supabase project, Stripe account, maps token, terms/privacy pages, merchant agreement, driver agreement/insurance confirmation and controlled real-world tests are completed.

## Fixed customer pricing policy

Every order must display an itemised total in pounds sterling:

| Line | Default |
| --- | ---: |
| Food subtotal | Menu items and selected modifiers |
| Delivery fee | £2.50 in the demo local zone / owner-configured in Live mode |
| Tunbridge Wells Kebab platform fee | **£1.00** |
| Transaction fee | **£0.29** |
| Collection | £0.00 delivery fee |

The two fixed fees become versioned owner policies in the database. Owners may amend a future policy with a reason, but historic receipts retain the original snapshot.

## The map is meant to be real

In Live mode an accepted driver app uses device GPS with explicit consent and sends a signed update to `record-driver-location`. The Edge Function verifies the driver is assigned to an active order, stores only the current point, and Supabase Realtime sends it only to the relevant customer, assigned driver and owners. The customer map never claims a guessed or stale location is live.

See [`docs/MAP_TRACKING.md`](docs/MAP_TRACKING.md) before building the tracking screen. It gives the exact update cadence, permission language, access controls, data retention and fallback behaviour.

## Start here

1. Read [`docs/TWO_PROMPT_BUILD.md`](docs/TWO_PROMPT_BUILD.md).
2. Give Prompt 1 to Codex in this repository. It creates the runnable web/mobile surfaces around the database contracts already present.
3. Review the demo flow and then give it Prompt 2.
4. Create and link an isolated Supabase project; apply migrations locally first, then in the isolated project.
5. Do not enable Live mode until every item in [`docs/LIVE_LAUNCH_CHECKLIST.md`](docs/LIVE_LAUNCH_CHECKLIST.md) has a real-world answer.

## What is now implemented

- `apps/web`: responsive Next.js customer menu/basket/transparent-demo-checkout, receipt/tracking, kitchen queue and owner control-centre prototype.
- `apps/mobile`: native Expo Router driver surface with availability, job progression, foreground GPS consent, stop-sharing and demo proof flow.
- `packages/shared`: integer-pence money formatter/quote, order labels and Zod API payload contracts.
- `supabase/functions/set-runtime-mode`: owner-only, audited Demo/Live gate that fails closed when required server configuration or operational records are absent.

The screens start in Demo and visibly say so. Demo neither calls Stripe nor claims that its driver marker is live.

The local web demo now renders the complete menu transcribed in `supabase/seed.sql`: 50 items across Starters, Kebabs, Combination Kebabs, Burgers, Chicken, Fish and Meals, including every seeded price, the 24 medium/large variant choices and the five sauce/salad preferences. It supports item configuration, quantity controls, delivery or collection, required customer details, transparent integer-pence totals, fake payment confirmation, simulated status progression, kitchen actions and owner menu/opening/mode controls. No menu data was invented outside the seed.

## Local setup

```bash
pnpm install
cp .env.example .env.local
pnpm typecheck
pnpm test
pnpm dev:web
```

Open `http://localhost:3000`. In a second terminal, start the driver development surface with `pnpm dev:mobile`.

To bind the web server for Codespaces port forwarding, use:

```bash
HOSTNAME=0.0.0.0 pnpm dev:web
```

For the real database contract, install the Supabase CLI, create an isolated project, run `supabase start` then `supabase db reset`, create the first authenticated owner, and run `supabase/BOOTSTRAP_FIRST_OWNER.sql` privately with that user ID. Do not put service-role, Stripe or directions secrets in either app.

## Function table

| Function | Authority | Status |
| --- | --- | --- |
| `create-order` | Server prices basket, snapshots fees, creates demo order or Stripe intent | Implemented; requires Supabase runtime |
| `assign-driver` | Kitchen/owner assignment of ready job | Implemented |
| `update-order-status` | Role-specific state changes and proof requirement | Implemented |
| `record-driver-location` | Assigned-driver-only active-location update | Implemented |
| `stripe-webhook` | Signed Stripe payment authority | Implemented; requires Stripe configuration |
| `set-runtime-mode` | Owner-only audited fail-closed Live gate | Implemented |

## Pilot readiness

| Feature | Demo status | Live status | Owner action still needed |
| --- | --- | --- | --- |
| Menu, basket and itemised fees | Usable prototype | Not enabled | Confirm merchant menu/allergens and connect Supabase |
| Kitchen and dispatch flow | Simulated | Not enabled | Create staff accounts and test roles/RLS |
| Driver workflow | Simulated | Not enabled | Build on Android/iOS and run a real foreground-GPS test |
| Payments | Fake confirmation only | Locked | Configure Stripe account, test signed webhook, then live keys server-side |
| Map tracking | Simulated marker only | Locked | Configure restricted map/directions providers and validate privacy/RLS |
| Legal / operations | Checklists included | Blocker | Supply terms, privacy, support, merchant agreement, driver insurance/tax review |

## Reuse boundary

| Source | Reuse | Do not reuse |
| --- | --- | --- |
| Door in Four | RLS role separation, driver approval/workspace, operations controls, server-side payment pattern, deployment hardening | Its buyer-led collection/seller logic or branding |
| Doorin5 | Local pilot discipline, money/readiness checks, status flows, receipt/proof thinking and smoke-test habit | Its concierge-shopping markup, fulfilment float and brand |
| Tunbridge Wells Kebab | Restaurant menu, order/restaurant lifecycle, £1.00 + £0.29 policy, kitchen flow, location privacy model | — |

## Important limitations

This code does not create a Supabase project, Stripe account, maps account, merchant contract or driver insurance. It provides the code and configuration contracts. Real payments and real tracking remain locked off by default.
