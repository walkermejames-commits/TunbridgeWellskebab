# Tunbridge Wells Kebab — two-prompt build brief

Give Prompt 1 to Codex from the root of this new repository. Once it has produced and tested the complete demo, give it Prompt 2 in the same conversation. The two prompts deliberately prevent a pretty but hollow mock-up: the database, pricing, roles and live driver map are part of the first build.

## Prompt 1 — build the complete working prototype around the supplied backend

```text
You are the lead engineer for Tunbridge Wells Kebab. Work in this repository. This is a proper one-restaurant ordering, kitchen, dispatch and driver-tracking product, not a marketing landing page.

START WITH THE EXISTING MATERIAL
1. Read README.md, docs/ARCHITECTURE.md, docs/MAP_TRACKING.md, docs/REUSE_MAP.md and every file under supabase/ before changing code.
2. Inspect these source repositories read-only and record a brief factual reuse map in docs/IMPLEMENTATION_REUSE_MAP.md:
   - https://github.com/walkermejames-commits/door-in (use its role-controlled operations, server-side payment, deployment and live-readiness lessons)
   - https://github.com/walkermejames-commits/Doorin5 (use its local-pilot, workflow, smoke-test and money-safety lessons)
3. Do not copy their brand, buyer/seller collection model, concierge-shopping markup or fulfilment-float logic. This is a separate kebab takeaway product with its own public identity and database.
4. Do not delete, rename, weaken or bypass the supplied Supabase migrations and RLS policies. If you find a concrete defect, fix it minimally, explain it in docs/SCHEMA_DECISIONS.md and keep the security intent intact.

PRODUCT RULES THAT CANNOT CHANGE
- Customer-facing name: Tunbridge Wells Kebab.
- Default runtime mode: Demo. Every demo screen/data point has an obvious Demo badge. Demo never calls Stripe, notifies a real person or labels a simulated GPS point as live.
- Live operations are server-authoritative and locked off unless the readiness gate passes. Do not add a client-only switch.
- Checkout and receipt show these exact itemised lines: Food subtotal; Delivery or Collection; Tunbridge Wells Kebab platform fee (£1.00 by default); Transaction fee (£0.29 by default); Total. No hidden fee.
- All money is integer pence in code/database. Do not use floating-point pound calculations.
- Use the menu and prices in supabase/seed.sql. It was checked against the supplied photograph, including £25.00 Super Best, £5.50 Chicken Burger, £11.00 Chicken Twister meal and medium/large kebab options. All menu data must be owner-editable, but do not silently alter the seeded prices.
- The customer’s address, phone and driver GPS are private data. Do not put them in public URLs, logs, analytics payloads or generic map listings.

BUILD THIS MONOREPO
Create a pnpm workspace without changing the root package identity:

- apps/web: Next.js App Router + TypeScript + PWA. This is customer ordering, kitchen dashboard, owner dispatch and customer tracking. Use the existing Door in Four Next.js pattern where genuinely useful.
- apps/mobile: Expo Router + TypeScript driver app. It must work on Android and iOS through an Expo development build. Do not make the driver app a web-view shell.
- packages/shared: shared TypeScript types, Zod request schemas, formatMoney, order-state labels, pricing-display helpers, Supabase generated types and API client contracts.
- supabase: retain supplied migrations/seed/functions. Add config.toml, function configuration and only the migrations/functions actually required by the finished app.

Pin dependency versions and commit lockfiles. Before changing Supabase behaviour, read current Supabase documentation/changelog. Before adding a library, prefer one which works in the actual target environment rather than a flashy browser-only package.

AUTHENTICATION AND ROLES
- Use Supabase Auth email/password or magic link for the prototype. A new account receives customer role through the supplied auth trigger.
- Create a demo-only sign-in chooser with clearly marked test accounts. Do not embed a live password in source. Use local/demo seed instructions or Supabase Auth admin setup to create the demo accounts.
- Owner can grant kitchen/driver roles through a server-side owner control, with audit event. Never use user_metadata as authority. Roles come from public.user_roles / server verification.
- Customer sees only their own order records. Kitchen sees restaurant operations. A driver sees only their offered/assigned work. Owners see operations. Enforce this in RLS and server handlers, not merely nav visibility.

CUSTOMER WEB/PWA FLOW
1. `/` opens directly onto the menu, delivery/collection toggle and persistent basket. It is not a giant hero page.
2. Browse categories: Starters, Kebabs, Combination Kebabs, Burgers, Chicken, Fish and Meals. Display medium/large variants and the optional sauce/salad preference wherever mapped in the seed.
3. Basket supports quantity changes, variant/modifier choice, optional note, removal, availability errors and an itemised estimate. The client may estimate, but `create-order` is the source of truth.
4. Checkout requires authenticated account, customer name/phone snapshot, delivery address and delivery zone for delivery, then displays the exact server quote lines. In Demo, complete with a conspicuous fake-payment confirmation. In Live, create a Stripe PaymentIntent only through the Edge Function and use Stripe’s supported payment sheet/element.
5. Receipt / track page shows public reference, food-line snapshots, exact fee snapshot, customer-visible event timeline and a tracking panel. Never expose another customer’s lookup through a guessed reference.
6. Include plain allergy wording: “Please contact the takeaway before ordering if you have an allergy. Ingredients and cross-contamination information must be confirmed by the merchant.” Do not make false allergen claims.

KITCHEN AND OWNER WEB FLOW
- Kitchen dashboard opens to paid/confirmed/preparing orders. Actions: accept/reject with reason, set preparation estimate, move confirmed → preparing → ready for pickup, pause/restore availability, and mark a menu item unavailable.
- Owner dashboard opens to ready/unassigned jobs, active deliveries, driver availability and honest location freshness. Actions: assign/reassign, switch a driver’s approval/availability, cancel/refund through server-safe paths, edit menu, delivery zones, hours and future fee policies, and read a filterable audit log.
- A controlled Demo / Live control centre shows mode, the exact blockers and a server-read readiness checklist. Toggling Live requires owner re-authentication/confirmation, a reason, an audit entry and a passing server response. If a secret, merchant, driver, zone, legal link or test fails, it stays in Demo.
- Do not allow the last owner to remove/demote themselves. Fee changes have effective time, reason and old/new audit snapshot. Historic orders must remain unchanged.

DRIVER MOBILE FLOW
- Driver home: Available / Offline toggle, active job card, job offers and simple earnings placeholder only if it does not claim real payouts.
- Job offer shows pickup instructions, delivery notes, safe map route and large Accept / Decline controls. Driver cannot see a customer address until assigned/accepted.
- Statuses must follow the database guard: driver_assigned → driver_en_route_to_pickup → collected → driver_en_route → nearby → delivered. Kitchen controls kitchen statuses; driver controls driver statuses; owner has controlled override with audit reason.
- Before the first location update, show consent wording explaining what will be shared, who can see it, when it stops and a visible Stop sharing / end delivery option. Refusing GPS must not trap the driver; manual status updates still work.
- Proof of delivery: implement one demo-safe route first (handed-to-customer / OTP placeholder) and a private signed-upload path for a photo. No proof photo is public. Require proof before a driver can complete a delivery unless an owner performs a reasoned override.

REAL MAP TRACKING — THIS MUST ACTUALLY WORK
Follow docs/MAP_TRACKING.md exactly. Implement:

- Web map: MapLibre GL with a restricted MapTiler tile token. Show restaurant, customer destination after checkout, driver marker only while eligible and an honest state panel.
- Mobile map: native map adapter appropriate for Expo Android/iOS. Use Expo Location foreground `watchPositionAsync` for the initial pilot. Do not claim background location works until it has been built/tested with a development build and exact platform permission copy.
- Send GPS only to `record-driver-location`, approximately every 10 seconds or 25 metres while an active delivery is in one of the permitted driver statuses. Queue/retry short outages safely; never replay a point more than five minutes old.
- Customer tracking subscribes to Supabase Realtime for their own `driver_live_locations` row. A point is “Live” only when it is younger than 90 seconds. Otherwise say last updated / tracking unavailable, retaining normal order status.
- Driver map may request a directions route from a server-side directions adapter. Customer never gets a driver’s full history. Finish/cancel immediately removes the current live-location row and subscription access.
- Add tests: unauthorised driver update rejected; Customer A cannot read Customer B; location disappears on delivery; 91-second-old point is stale; a simulated Demo point is visibly called simulated.

DATABASE AND EDGE FUNCTIONS
- Apply the supplied schema to local Supabase first. Generate TypeScript database types from it and use those types rather than hand-writing drifting database interfaces.
- Retain and test the provided functions: create-order, assign-driver, update-order-status, record-driver-location and stripe-webhook. Add only what the real app needs, for example an owner-only `set-runtime-mode` function and a signed proof-upload URL function.
- All pricing comes from the server: fetch current available menu item/variant/modifiers, validate ownership/mapping, calculate lines in pence, apply current published policy and zone fee, store snapshots and idempotency key. The browser’s total is never charged on trust.
- Stripe webhook is the live payment authority. Client-side payment success alone must not mark an order paid. Verify Stripe webhook signatures, make webhook handling idempotent and store only Stripe IDs—not card information.
- Every state change makes an order_status_event. Sensitive audit metadata must never include full address, payment secret or exact GPS.
- Enable RLS for all public schema tables and verify Data API grants. Never use service role in web/mobile client code. Use private helper functions only with tight execute grants and no untrusted input shortcuts.

VISUAL AND ACCESSIBILITY DIRECTION
- A proper bright-but-gritty local takeaway identity: charcoal/navy background, chilli red, warm grilled gold, clean white pricing panels. Not a generic food-app clone and not restaurant imagery made from CSS shapes.
- Use supplied menu photo only as the content source; do not publish it as an assumed licensed brand asset. Use simple generated/placeholder food imagery only if it is safe and not misleading.
- Main interactive text at least 16px. Tap targets suit hands. Mobile has no horizontal scroll. Every important status has text as well as colour. Inputs/steps work via keyboard on web.

DEMO DATA AND TESTING
- Demo records use clearly fake values and `is_demo=true`. A button called `Advance simulated delivery` may move the demo through legal statuses. Its moving marker says `Simulated driver location` everywhere.
- Add unit tests for money: collection, delivery, exact 100-pence platform fee, exact 29-pence transaction fee, modifiers, quantity, bad/duplicate idempotency key and rejected hidden pricing change.
- Add integration tests for order transition/role logic and RLS where local Supabase supports it. Add a ten-minute manual test script from customer basket through receipt, kitchen, dispatch, driver, tracking and delivery.
- Run formatting, typecheck, tests, web build and any mobile checks available. Do not say a test passed when it did not run.

DELIVERABLES
1. A runnable web PWA and Expo driver app in the described workspace.
2. Updated README with exact setup commands, Supabase setup, demo accounts and no false live claims.
3. `.env.example`, `docs/LIVE_LAUNCH_CHECKLIST.md`, `docs/MAP_TRACKING.md`, `docs/IMPLEMENTATION_REUSE_MAP.md`, `docs/TEST_SCRIPT.md` and a concise API function table.
4. A final report listing files changed, commands/results, what is truly working, what is simulated, and the very first thing the owner must configure to test a real phone.
```

## Prompt 2 — test, harden, and prepare a controlled real pilot

```text
Continue from the Tunbridge Wells Kebab prototype already built in this repository. Do not start a new app or replace working architecture. Run the existing checks and manual test flow first, repair all reproducible failures, then do this hardening pass.

FIRST: PROVE THE FULL DEMO
- Use four separate demo roles: customer, kitchen, driver and owner. Customer orders an actual seeded menu item; checkout shows £1.00 and £0.29 on separate lines; kitchen moves it to ready; owner assigns driver; driver accepts/collects/starts; customer sees a clearly simulated marker; driver provides proof; order finishes; owner sees the audit trail.
- Verify route/status update permissions. Reject every invalid state transition and direct/browser-authority bypass. Verify default customer cannot access operations, assignment details or another order.
- Verify server price snapshot does not change after an owner edits a menu price or fee policy. Verify duplicate idempotency key returns the original order rather than charging/creating twice.
- Fix menu transcription, totals, database migrations, RLS, TypeScript, build or responsive defects you actually find. Preserve the £1.00 platform and £0.29 transaction defaults.

SECOND: MAKE LIVE MODE SAFE TO ENABLE, NOT EASY TO ACCIDENTALLY ENABLE
- Implement owner-only `set-runtime-mode` Edge Function. It checks: actual Supabase env/configuration; Stripe secret/webhook; maps/directions configuration; privacy and terms URLs; support contact; one owner, kitchen and approved driver; one restaurant with real pickup address; published menu, hours, zone and fee policy; successful driver-GPS test record; latest security test result. It fails closed and returns a human-readable missing-item list.
- Require an owner confirmation/re-authentication step immediately before Live switch. Save actor, time, reason, old mode/new mode and readiness result to audit_logs. Demo records remain separate and never appear as live analytics.
- Configure Stripe test first. Use a signed webhook and idempotency. Then document exactly how a real Stripe account owner changes to live keys in the server environment; never put secret keys in a client or repository.
- Make refund/cancellation operations server-only, reasoned and audited. If live refund support is not fully verified, label it owner-review required rather than creating a pretend button.

THIRD: MAKE THE MAP AND GPS READY FOR A REAL PHONE TEST
- Run an actual Expo development build on one Android/iOS device, not only a simulator/web browser. Verify foreground permission and update cadence on ordinary mobile data.
- Verify tracking begins only after driver accepts and starts the permitted status, and ends instantly on delivered/cancelled. Check the database has one current location per active job, no passive driver-location tracking and no public table/query leakage.
- Add connection-health UI: GPS permission denied; GPS unavailable; no recent update; last update age; map tile failure; directions failure; offline queue/retry. None of these may claim live movement when they cannot prove it.
- Validate RLS with separate logged-in accounts, especially the realtime subscription. Customer A must be unable to obtain Customer B’s `driver_live_locations` row via table query, realtime channel, URL change or app cache.
- Implement exact mobile permission strings and privacy text. Keep background tracking off unless it has a separately approved, tested implementation and a driver-controlled stop control.

FOURTH: OPERATIONS AND COMMERCIAL QUALITY
- Finish owner controls: menu availability/edit/draft publish; restaurant opening and hours; zone/radius + delivery fee; platform/transaction fee policy versioning; driver role/availability; open jobs; cancellation/refund reasons; demo reset; feature flags; audit filters/export.
- Add a simple dashboard that answers useful questions: active orders, unassigned ready orders, drivers available, average prep/delivery estimate and revenue only for paid non-demo orders. Do not fabricate a payout or profit number.
- Add ordering safeguards: restaurant closed, item unavailable, zone out of range, minimum order, duplicate payment/order, stale driver location and expired payment intent.
- Ensure the app is usable at 320px through tablet/desktop. Test safe-area, keyboard, font scaling and no horizontal overflow.

FIFTH: DEPLOYMENT AND HANDOFF
- Add CI checks for typecheck, tests and web build. Treat Supabase migrations as reviewable source, not manual dashboard scraps.
- Give exact deployment instructions for web PWA and Expo Android/iOS development builds, but do not claim App Store or Play Store approval. Add docs/MOBILE_RELEASE_CHECKLIST.md.
- Document monitoring/error-reporting setup with address/GPS redaction by default.
- Update README and the launch checklist. End with a blunt Pilot Readiness table: feature; Demo status; Live status; owner action still needed. Mark anything involving legal terms, privacy, food-allergen responsibility, driver insurance/tax, Stripe account, map provider account or on-the-road testing as an owner action, not “done”.
```

