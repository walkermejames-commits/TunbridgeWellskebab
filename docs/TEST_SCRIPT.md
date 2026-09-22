# Ten-minute demo test script

Use four separately authenticated demo users: customer, kitchen, driver and owner. All test people, addresses and GPS points must be fake.

1. As the customer, add **Chicken Twister meal (£11.00)** and choose Delivery. Confirm checkout displays Food subtotal, Delivery or Collection (£2.50), platform fee (£1.00), transaction fee (£0.29) and the exact total.
2. Confirm the clearly labelled fake payment. Verify the receipt is marked Demo and has no live payment claim.
3. As kitchen, accept, prepare and set the order ready for pickup. Try skipping a state; the database guard must reject it.
4. As owner, assign the approved demo driver. Confirm the audit log contains the assignment without an address or coordinates.
5. As driver, accept, collect and start delivery. Read the foreground-location consent text. Refuse permission once and verify manual statuses still work.
6. Send a simulated location. As the customer, verify it says **Simulated driver location**, never Live driver location.
7. Complete a handed-to-customer demo proof and mark delivered. Verify location sharing stops and the `driver_live_locations` row disappears.
8. With Customer B, attempt to query Customer A's order and location through the Data API and Realtime. Both must fail under RLS.
9. Edit a menu item or future fee policy as owner. Confirm the existing order's snapshots and receipt do not change.
10. Repeat checkout with the same idempotency key. Confirm the existing order is returned, not a second order or charge.

For the real-phone pilot, create an Expo development build, sign in as the approved driver, use ordinary mobile data, and confirm foreground location reaches the customer view within 15 seconds. Background tracking is intentionally off.
