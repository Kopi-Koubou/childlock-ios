# Supabase Apple Auth Setup

Current production project:

```text
jkncpveupvozsmbbkvgq
https://jkncpveupvozsmbbkvgq.supabase.co
```

Current status checked on 2026-06-23:

- Supabase user signups: enabled
- Supabase anonymous sign-ins: disabled
- Supabase Apple provider: enabled for native iOS sign-in
- Apple app bundle ID exists: `com.kopikoubou.childlock`
- Apple Services ID: not needed for the current native iOS flow

## Native iOS Sign In With Apple

For the current iOS app flow, use native Sign in with Apple through
AuthenticationServices, then exchange the Apple identity token with Supabase.

Supabase should stay configured as:

1. Open `Authentication` -> `Sign In / Providers`.
2. Open `Apple`.
3. `Enable Sign in with Apple` is on.
4. Set `Client IDs` to:

   ```text
   com.kopikoubou.childlock
   ```

5. `Secret Key (for OAuth)` is blank for the native iOS flow.
6. Save after any change.

The app now fails closed in production if Supabase auth is configured but Apple
token exchange fails. That prevents a local-only "signed in" state from being
mistaken for a real production signup.

## Google Sign In

Google uses the native Google Sign-In SDK plus Supabase ID-token exchange.
Google setup is tracked separately in `docs/SUPABASE_GOOGLE_AUTH.md`.


## OAuth/Web Fallback

Only do this if you later need a web OAuth flow. It is not required for the
current TestFlight build because the app uses native Sign in with Apple.

Apple Developer Services ID:

```text
com.kopikoubou.childlock.web
```

Website domain:

```text
jkncpveupvozsmbbkvgq.supabase.co
```

Return URL:

```text
https://jkncpveupvozsmbbkvgq.supabase.co/auth/v1/callback
```

If OAuth is enabled, Apple requires a client secret generated from a `.p8`
signing key and that secret must be rotated every 6 months. Store the `.p8`
outside the repo.
