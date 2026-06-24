# Supabase Google Auth Setup

Current production project:

```text
jkncpveupvozsmbbkvgq
https://jkncpveupvozsmbbkvgq.supabase.co
```

The iOS app uses the native Google Sign-In SDK, then exchanges Google's ID
token with Supabase Auth. No Google client secret belongs in the iOS app.

Current app wiring:

- Button: `Continue with Google`
- iOS URL scheme: `GOOGLE_REVERSED_CLIENT_ID`
- Google SDK config: `GIDClientID` + `GIDServerClientID`
- Supabase token exchange: `signInWithIdToken(provider: .google)`
- Public iOS client ID location: `Config/AppSecrets.local.xcconfig`
- Public Web/server client ID location: `Config/AppSecrets.local.xcconfig`
- Secret location: Supabase dashboard only, never `Config/AppSecrets.xcconfig`

## Google Cloud

1. Open Google Cloud Console.
2. Create or select the Childlock project.
3. Configure the OAuth consent screen as External.
4. Go to `APIs & Services` -> `Credentials`.
5. Create an OAuth client ID with application type `iOS`.
6. Use bundle ID:

   ```text
   com.kopikoubou.childlock
   ```

7. Copy the iOS client ID and the reversed client ID from the downloaded
   `GoogleService-Info.plist`.
8. Create an OAuth client ID with application type `Web application`.
9. Copy the Web client ID for the app and the Web client secret for Supabase.

## App build settings

Paste these public iOS values into `Config/AppSecrets.local.xcconfig` locally
and into the equivalent Xcode Cloud pre-build environment:

```text
GOOGLE_IOS_CLIENT_ID = <iOS client id>.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID = <web client id>.apps.googleusercontent.com
GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.<iOS client id prefix>
```

The reversed client ID must match the iOS client ID prefix exactly. The release
validation script checks this so the Google flow cannot ship with a callback
scheme that opens Google but fails to return to Childlock.

The Web client ID is public. It is compiled into `GIDServerClientID` so Google's
ID token has the backend audience Supabase expects. The matching Web client
secret stays in Supabase only.

## Supabase

1. Open `Authentication` -> `Sign In / Providers`.
2. Open `Google`.
3. Enable Google.
4. Paste the Google Web client ID and iOS client ID in the provider's client ID
   field, separated by a comma, with the Web client ID first.
5. Paste the Google Web client secret.
6. Leave `Skip nonce check` off. Childlock uses GoogleSignIn-iOS 9.x custom
   nonce support: the app sends a SHA-256 nonce to Google and passes the raw
   nonce to Supabase during `signInWithIdToken`.
7. Save.

After this, the app's `Continue with Google` button should complete signup and
advance into the Family Controls setup flow.

## Troubleshooting

If TestFlight shows this error, the app can reach Supabase but the Google
provider is not fully configured:

```text
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: missing OAuth secret"}
```

Fix it in Supabase, not Xcode:

1. Go back to `Authentication` -> `Sign In / Providers` -> `Google`.
2. Confirm the Web client ID, iOS client ID, Web client secret, and `Skip nonce
   check` setting. `Skip nonce check` should stay off for this app. Turn it on
   only for a temporary debug build that does not send a nonce.
3. Save the provider.
4. Re-run `Continue with Google`.

If Google opens and then returns to Childlock without completing signup, check
`GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`, and
`GOOGLE_REVERSED_CLIENT_ID` in the app build settings.

## TestFlight Proof

Before App Review, install the TestFlight build and confirm:

1. `Continue with Google` opens the Google OAuth flow.
2. Google returns to Childlock through the reversed iOS client ID URL scheme.
3. Onboarding advances to Screen Time authorization.
4. The parent account persists after force-quitting and reopening the app.
