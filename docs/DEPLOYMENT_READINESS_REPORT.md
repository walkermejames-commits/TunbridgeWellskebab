# Deployment & Play Store readiness report

**Checked:** 22 September 2026  
**Overall decision:** **Not ready for Google Play production submission.** It is ready for local web demonstration and for the next controlled Android development-build step.

## Evidence collected on this machine

| Check | Result | Evidence |
| --- | --- | --- |
| Workspace installation | Pass | `pnpm install` completed successfully |
| Shared, web and mobile TypeScript | Pass | `pnpm typecheck` completed successfully |
| Pricing tests | Pass | `pnpm test`: 3/3 integer-pence pricing tests passed |
| Production web build | Pass | `pnpm --filter @twk/web build` completed successfully |
| Browser demonstration | Pass | Local menu, basket, itemised £1.00/£0.29 fees, fake payment and simulated tracking all rendered; no error overlay or browser console errors |
| Android toolchain | Partial | `adb`, Java and Android SDK are installed |
| Connected Android device/emulator | Blocked | `adb devices -l` reported no device; no emulator binary found |
| Expo configuration | Pass | Expo resolves package `com.tunbridgewellskebab.driver`, foreground location permission and SDK 53 configuration |
| Real driver location test | Not run | Requires an actual approved Android/iOS device and Supabase configuration |

## What can run now

```bash
pnpm install
pnpm dev:web
pnpm dev:mobile
```

The browser product opens at `http://localhost:3000`. It is a clearly labelled Demo: fake payment never contacts Stripe and the map label says `Simulated driver location`.

## Android / Play Store blockers

1. **No device verification.** Attach an Android phone with USB debugging enabled or create an Android emulator. Build and install an Expo development build, then test the location consent, decline/stop-sharing paths, offline recovery and full delivery flow on mobile data.
2. **No production backend.** Create an isolated Supabase project, apply migrations, configure Edge Function secrets, create separately authenticated customer/kitchen/owner/driver accounts, and prove RLS/Realtime isolation.
3. **Live operational gate is intentionally blocked.** Stripe, restricted maps/directions configuration, legal URLs, support contact, real merchant pickup address, approved driver and GPS test are not configured.
4. **Play listing material is incomplete.** Add an app icon, adaptive icon, feature graphic, screenshots, short/full descriptions, support email/website and a public privacy-policy URL that describes address, phone and active-delivery location processing.
5. **Data Safety declaration is incomplete.** The driver app handles precise location; the Play Console Data Safety form and privacy policy must accurately describe collection, sharing, purpose, retention, encryption and deletion. Do not submit until the real implementation has been reviewed.
6. **Release build and signing are absent.** Set up the owner-controlled Google Play developer account, EAS/local Android signing, an Android App Bundle (`.aab`), internal testing track and release versioning. Keep credentials outside Git.
7. **Policy/API compatibility must be checked at release time.** Current Google Play requirements say new apps and updates must target Android 16 / API 36 or higher. Confirm Expo/React Native output meets the requirement immediately before upload.
8. **Business and safety approvals remain owner actions.** Merchant menu/allergen confirmation, privacy/terms, driver insurance/work/tax position, customer support and on-road pilot approval are not code-complete tasks.

## Recommended release sequence

1. Configure Supabase and run the four-role demo script in `docs/TEST_SCRIPT.md`.
2. Connect one Android device; build a development client and complete the real foreground-GPS pilot.
3. Create map/Stripe test configurations and prove that Live mode still fails closed until every readiness item passes.
4. Add the Play listing/privacy material and complete the Data Safety form from the verified implementation.
5. Produce a signed `.aab`, run internal testing, fix all reported device/policy issues, then submit to closed testing before any production rollout.

## Sources to revisit before submission

- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
- [Android Developers: Play target-SDK guide](https://developer.android.com/google/play/requirements/target-sdk)
- [Android Developers: Data Safety metadata](https://developer.android.com/about/versions/14/features/app-metadata)
