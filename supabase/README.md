# Childlock Supabase Backend

This directory contains the production Supabase backend for the iOS app:

- `migrations/20260612100816_initial_childlock_backend.sql` creates the database schema, indexes, triggers, grants, and Row Level Security policies.
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
3. Fill `Config/production.env` from `Config/production.env.example`.

4. Run the production deploy script from the repo root:

   ```sh
   scripts/deploy-production-backend.sh
   ```

   The script uses the Supabase CLI to link the production project, run
   `supabase db push`, deploy `revenuecat-webhook`, and set Childlock's custom
   `REVENUECAT_WEBHOOK_SECRET`. Hosted Supabase Edge Functions provide
   `SUPABASE_URL` and `SUPABASE_SECRET_KEYS`.

5. For a function-only redeploy after migrations are already applied:

   ```sh
   scripts/deploy-production-backend.sh --skip-db-push
   ```

   Do not put `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ACCESS_TOKEN`, or
   `REVENUECAT_WEBHOOK_SECRET` in iOS build settings.

6. In RevenueCat, add a webhook pointing to:

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
