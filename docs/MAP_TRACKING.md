# Real map tracking

## What counts as “live”

The customer sees `Live driver location` only after all four conditions are true:

1. the order is assigned to a driver;
2. that driver has pressed **Start delivery** after collecting the food;
3. the last GPS update is less than 90 seconds old;
4. the customer is viewing their own active order.

Anything else has an honest label: `Driver assigned`, `Driver has not started sharing`, `Last updated 4 minutes ago`, or `Tracking unavailable — your order is still being updated`.

## Data path

1. The driver app requests foreground location permission with clear explanation.
2. Only while `delivery_tracking_active=true`, it asks the device for a coordinate every 10 seconds or after 25 metres, whichever comes first; it batches/debounces safely while offline.
3. It calls the authenticated `record-driver-location` Edge Function with order ID, latitude, longitude, accuracy, heading and capture time.
4. The function verifies the JWT, confirms the user is the active assigned driver, confirms an active delivery state, rejects old/future/impossible updates and upserts the one current location row.
5. `driver_live_locations` is added to the Supabase Realtime publication. RLS exposes the row only to the relevant customer, driver and owner.
6. The customer tracking screen subscribes to that order’s location row, updates its marker, and obtains routing/ETA from the configured directions provider.
7. The driver presses **Delivered** or the kitchen/owner cancels. The server removes/disables live sharing and clients unsubscribe.

## Required privacy safeguards

- Customer sees only the active delivery point, never the driver’s full history or home/idle position.
- Kitchen sees status, not a map of every driver by default. Owners may see active jobs only.
- Exact coordinates never appear in analytics logs, URLs, error reports, push messages or audit-log metadata.
- If history is enabled for support disputes, retain it for the owner-configured minimum period (default 7 days), then purge by a protected scheduled job.
- No background location in the initial pilot. Add it only after real Android/iOS permission strings, a privacy review and a driver-controlled off switch are tested on actual phones.

## Map provider

Use MapLibre for rendering with a restricted public MapTiler token for tiles. Use a server-only directions-provider token for routes/ETA. A Live-mode readiness test checks both. If maps fail, the order status flow still works and customer UI says tracking map is temporarily unavailable instead of inventing an ETA.

## Test cases

- Customer A cannot subscribe to Customer B’s delivery location.
- A driver cannot write a location for an unassigned/completed order.
- A driver’s stale location becomes `last updated` rather than live at 91 seconds.
- Browser/device location permission denial does not stop the driver from manually updating status.
- Delivery completion removes the customer’s realtime location access.
- A real phone test shows marker movement on the customer screen within 15 seconds on ordinary mobile data.

