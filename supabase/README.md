# Childlock Supabase Backend

This directory contains the production Supabase backend for the iOS app:

- `migrations/20260521000000_initial_childlock_backend.sql` creates the database schema, indexes, triggers, grants, and Row Level Security policies.
- `functions/revenuecat-webhook` mirrors RevenueCat subscription events into `subscription_status`.

## Project Setup

Production project:

```text
jkncpveupvozsmbbkvgq
https://jkncpveupvozsmbbkvgq.supabase.co
```

1. Create or pick the Supabase project for Childlock.
2. In Supabase Auth, enable Apple and Google as external providers. Add the
   Supabase callback URL to Google Cloud and add `childlock://login-callback` to
   Supabase URL Configuration for the native app redirect.
3. Run the SQL migration in the Supabase SQL editor, or with the Supabase CLI once installed:

   ```sh
   supabase link --project-ref <project-ref>
   supabase db push
   ```

4. Deploy the RevenueCat webhook:

   ```sh
   supabase functions deploy revenuecat-webhook
   supabase secrets set REVENUECAT_WEBHOOK_SECRET=<long-random-secret>
   ```

   Supabase provides `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to Edge
   Functions at runtime. Do not put the service-role key in iOS build settings.

5. In RevenueCat, add a webhook pointing to:

   ```text
   https://jkncpveupvozsmbbkvgq.supabase.co/functions/v1/revenuecat-webhook
   ```

   Use the same `REVENUECAT_WEBHOOK_SECRET` as the bearer token.

## iOS Config

Set these generated Info.plist build settings on the `Childlock` target:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`
- `REVENUECAT_API_KEY`
- `POSTHOG_API_KEY`
- `POSTHOG_HOST` optional, defaults to `https://us.i.posthog.com`

The app intentionally sends only parent-owned, low-PII data to Supabase. Child names and Screen Time selection token payloads remain local.
