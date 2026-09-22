# Mobile development-build checklist

- Create an Expo development build for Android and/or iOS; the Expo Go web preview is not evidence of a real-phone GPS pilot.
- Set the real Supabase URL and publishable key using Expo build secrets. Never add a service-role, Stripe or directions secret to the app.
- Verify the shown foreground location permission copy on the actual platform.
- Test accepted → pickup → collected → delivery → proof → delivered on ordinary mobile data, including denied permission and Stop sharing.
- Confirm no background tracking is enabled or claimed.
- Before store submission, obtain review of privacy text, location purpose, data retention, driver insurance/work status, support route and merchant allergen content.
