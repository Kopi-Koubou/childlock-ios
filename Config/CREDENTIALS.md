# Childlock Credential Paste Points

Paste app-facing keys into `Config/AppSecrets.local.xcconfig`:

- `SUPABASE_URL` = `https://jkncpveupvozsmbbkvgq.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY`
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

OAuth redirect URL expected by the app:

- `childlock://login-callback`

Do not paste Apple Developer signing credentials here. Configure those in Xcode.

Do not paste service-role keys, Supabase access tokens, RevenueCat webhook
secrets, or App Store Connect private keys into any app xcconfig.

Do not paste Google OAuth client secrets into any app xcconfig.
Google OAuth client ID and client secret belong only in the Supabase Google auth
provider settings.
