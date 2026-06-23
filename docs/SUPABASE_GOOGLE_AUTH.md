# Supabase Google Auth Setup

Current production project:

```text
jkncpveupvozsmbbkvgq
https://jkncpveupvozsmbbkvgq.supabase.co
```

The iOS app uses Supabase OAuth for Google sign-in. Google sends users back to
Supabase, then Supabase redirects into the app with:

```text
childlock://login-callback
```

No Google client secret belongs in the iOS app.

Current app wiring:

- Button: `Continue with Google`
- Redirect URL scheme: `childlock://login-callback`
- Provider: Supabase `google` OAuth
- Secret location: Supabase dashboard only, never `Config/AppSecrets.xcconfig`

## Google Cloud

1. Open Google Cloud Console.
2. Create or select the Childlock project.
3. Configure the OAuth consent screen as External.
4. Go to `APIs & Services` -> `Credentials`.
5. Create an OAuth client ID with application type `Web application`.
6. Add this authorized redirect URI:

   ```text
   https://jkncpveupvozsmbbkvgq.supabase.co/auth/v1/callback
   ```

7. Copy the client ID and client secret.

## Supabase

1. Open `Authentication` -> `Sign In / Providers`.
2. Open `Google`.
3. Enable Google.
4. Paste the Google Web client ID.
5. Paste the Google Web client secret.
6. Save.
7. Open `Authentication` -> `URL Configuration`.
8. Add this redirect URL:

   ```text
   childlock://login-callback
   ```

After this, the app's `Continue with Google` button should complete signup and
advance into the Family Controls setup flow.

## Troubleshooting

If TestFlight or Simulator opens the Supabase web-auth sheet and shows this
response, the app wiring is working but the Supabase Google provider is not
fully configured:

```text
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```

Fix it in Supabase, not Xcode:

1. Go back to `Authentication` -> `Sign In / Providers` -> `Google`.
2. Paste the Google Web client secret again.
3. Save the provider.
4. Re-run `Continue with Google`.

## TestFlight Proof

Before App Review, install the TestFlight build and confirm:

1. `Continue with Google` opens the Google OAuth flow.
2. Google returns to Childlock through `childlock://login-callback`.
3. Onboarding advances to Screen Time authorization.
4. The parent account persists after force-quitting and reopening the app.
