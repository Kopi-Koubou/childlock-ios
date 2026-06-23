# Childlock Credential Paste Points

Paste app-facing keys into `Config/AppSecrets.local.xcconfig`:

- `SUPABASE_URL` = `https://jkncpveupvozsmbbkvgq.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY`
- `GOOGLE_IOS_CLIENT_ID`
- `GOOGLE_WEB_CLIENT_ID`
- `GOOGLE_REVERSED_CLIENT_ID`
- `REVENUECAT_API_KEY`
- `POSTHOG_API_KEY`
- `POSTHOG_HOST`

The checked-in `Config/AppSecrets.xcconfig` provides safe defaults and includes
`Config/AppSecrets.local.xcconfig` when it exists. For URL values in either
xcconfig file, keep the `https:/$()/...` format. Xcode expands that to
`https://...` during the build.

Paste local deployment/server secrets into `Config/production.env`:

- `SUPABASE_PROJECT_REF` = `jkncpveupvozsmbbkvgq`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_SERVICE_ROLE_KEY`
- `REVENUECAT_WEBHOOK_SECRET`

RevenueCat/App Store product IDs expected by the app:

- `childlock_premium_monthly`
- `childlock_premium_annual`
- entitlement: `Childlock Pro`

Fallback OAuth redirect URL still registered by the app:

- `childlock://login-callback`

Do not paste Apple Developer signing credentials here. Configure those in Xcode.

Do not paste service-role keys, Supabase access tokens, RevenueCat webhook
secrets, or App Store Connect private keys into any app xcconfig.

Google iOS client ID, Google Web client ID, and reversed client ID are public
app-facing values and belong in `Config/AppSecrets.local.xcconfig`.

The reversed client ID is derived from the iOS client ID. For example,
`123.apps.googleusercontent.com` becomes `com.googleusercontent.apps.123`.

Do not paste Google OAuth client secrets into any app xcconfig. The Google Web
client secret belongs only in the Supabase Google auth provider settings.
