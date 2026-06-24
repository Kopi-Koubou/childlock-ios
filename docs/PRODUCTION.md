# Childlock Production Runbook

This runbook is the production path for the iOS app, Screen Time extensions,
Supabase backend, RevenueCat integration, and public support/legal pages.

## Secret Storage

Use three storage locations:

- App-facing build settings: paste public client keys into `Config/AppSecrets.local.xcconfig`. The checked-in `Config/AppSecrets.xcconfig` is wired into the app target and optionally includes the ignored local override.
- Local deployment secrets: paste backend/deployment secrets into `Config/production.env`. This file is gitignored and should only be sourced locally when deploying.
- Long-lived secrets: store the real values in 1Password/iCloud Keychain and in the provider dashboard that owns them.

Never put these in the app or repository:

- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_ACCESS_TOKEN`
- `REVENUECAT_WEBHOOK_SECRET`
- App Store Connect `.p8` private keys

## Required Credentials

| Credential | Where to get it | Where to store it |
| --- | --- | --- |
| Apple Team ID | Apple Developer account | Configure in Xcode signing settings |
| Supabase project ref | Supabase project URL | `Config/production.env` |
| Supabase URL | Supabase API settings | `Config/AppSecrets.local.xcconfig` |
| Supabase publishable key | Supabase API settings | `Config/AppSecrets.local.xcconfig` |
| Supabase service role key | Supabase API settings | Password manager and Supabase CLI/server only |
| Supabase access token | Supabase account tokens | Password manager, local shell, or GitHub Actions secret |
| Google iOS client ID | Google Cloud OAuth iOS client | `Config/AppSecrets.local.xcconfig` |
| Google Web client ID | Google Cloud OAuth Web client | `Config/AppSecrets.local.xcconfig` and Supabase Google provider |
| Google reversed client ID | Google Cloud OAuth iOS client / `GoogleService-Info.plist` | `Config/AppSecrets.local.xcconfig` |
| Google Web client secret | Google Cloud OAuth Web client | Supabase Google provider only |
| RevenueCat iOS SDK key | RevenueCat project API keys | `Config/AppSecrets.local.xcconfig` |
| RevenueCat webhook secret | Generate a long random value | Supabase secret and RevenueCat webhook auth header |
| RevenueCat/App Store IAP key | App Store Connect | RevenueCat dashboard and password manager |
| PostHog project API key | PostHog project settings | `Config/AppSecrets.local.xcconfig` |
| KouBou Labs site deploy access | `Kopi-Koubou/koubou-labs-site` repo and hosting provider | GitHub/Cloudflare credentials, outside this app repo |
| Support/privacy email | Your support inbox provider | `koubou-labs-site` public pages and App Store Connect |

Current production Supabase project:

- Project ref: `jkncpveupvozsmbbkvgq`
- Project URL: `https://jkncpveupvozsmbbkvgq.supabase.co`

Required RevenueCat/App Store product identifiers:

- Monthly subscription: `childlock_premium_monthly`
- Annual subscription: `childlock_premium_annual`
- RevenueCat entitlement identifier: `Childlock Pro`

## App Review Position

For v1, Screen Time enforcement is not quota-gated. Brain breaks, app shielding,
and re-arming monitoring are available to every family. Any future subscription
should unlock non-enforcement value such as reports, insights, coaching content,
or additional cloud features.

Parents must sign in before setup. Reviewers can use native Sign in with Apple,
or native Google Sign-In backed by Supabase Auth when the submitted build has
Google OAuth configured. Builds without valid Google OAuth IDs hide the Google
button rather than exposing a non-working option. There is no separate
username/password account for App Review to use.

Launch device support is intentionally local-first. Childlock locks apps on the
device where setup is completed. For a child iPad, install and configure
Childlock on the iPad. Same-phone parent/child use is supported because the
parent dashboard remains PIN-protected. A separate parent-phone remote dashboard
is not part of the launch build. See `docs/DEVICE_MODEL.md`.

## Backend Deployment

From the repo root:

```sh
source Config/production.env
supabase login
supabase link --project-ref "$SUPABASE_PROJECT_REF"
supabase db push
supabase functions deploy revenuecat-webhook
supabase secrets set REVENUECAT_WEBHOOK_SECRET="$REVENUECAT_WEBHOOK_SECRET"
```

Supabase Edge Functions automatically expose `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY` at runtime. Do not compile either service-role
value into the iOS app.

Apple auth setup is tracked in `docs/SUPABASE_APPLE_AUTH.md`. Google auth setup
is tracked in `docs/SUPABASE_GOOGLE_AUTH.md`. Do not submit a production build
until the Supabase Apple provider is enabled and saved. If the submitted build
shows Google sign-in, the Supabase Google provider must also be enabled and the
app build must have `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`, and
`GOOGLE_REVERSED_CLIENT_ID`; otherwise, Google should stay hidden and be marked
N/A in hardware QA.

For Xcode Cloud, create `Config/AppSecrets.local.xcconfig` in a pre-build script
from Xcode Cloud environment variables, or pass equivalent build settings on the
archive command line. A clean checkout still builds because the checked-in base
config exists, but sign-in and purchases require real values.

In RevenueCat, configure a webhook:

```text
https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
```

Set the webhook Authorization header to the same value as
`REVENUECAT_WEBHOOK_SECRET`.

## RevenueCat Product Gate

Before TestFlight purchase QA, confirm RevenueCat can fetch the App Store
products from the current offering. The iOS app expects:

- Current offering has monthly and annual packages.
- Monthly package product identifier is `childlock_premium_monthly`.
- Annual package product identifier is `childlock_premium_annual`.
- Both packages unlock entitlement `Childlock Pro`.

If RevenueCat returns empty offerings, the paywall intentionally disables
purchase with `Premium unavailable` while keeping Screen Time enforcement
available. Fix App Store Connect product status, RevenueCat package mapping, or
the app's `REVENUECAT_API_KEY` before treating subscription QA as passed.

## Public Site Deployment

The App Store support, privacy, and terms links live in the separate
`Kopi-Koubou/koubou-labs-site` repo:

- `https://kouboulabs.com/childlock/support`
- `https://kouboulabs.com/childlock/privacy`
- `https://kouboulabs.com/childlock/terms`

Deploy that repo after changing the static pages under `public/childlock/`.

## Xcode Release

1. Install full Xcode and select it:

   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. In Xcode, set the development team on every target:
   - Childlock
   - DeviceActivityMonitorExtension
   - ShieldActionExtension
   - ShieldConfigurationExtension

   Bundle identifiers:
   - `com.kopikoubou.childlock`
   - `com.kopikoubou.childlock.device-activity-monitor`
   - `com.kopikoubou.childlock.shield-action`
   - `com.kopikoubou.childlock.shield-configuration`

3. Ensure the app and extensions all include:
   - Family Controls entitlement
   - App Group `group.com.childlock.shared`

4. Fill app-facing production values in `Config/AppSecrets.local.xcconfig`.
   The checked-in `Config/AppSecrets.xcconfig` should stay as the safe base
   config and include the ignored local override.

5. Run the local release preflight below.

6. Product -> Archive -> Distribute App -> App Store Connect.

## Local Release Preflight

These checks catch compile, icon, privacy-manifest, and extension-shape
regressions before a real archive upload. They do not replace TestFlight
hardware QA.

Before public App Review, generate and complete hardware QA records with
`scripts/new-hardware-qa-record.sh`. The records are written under
`.build/hardware-qa-records/` and should cover the same-phone flow plus any
child-iPad flow promised in App Store copy. Do not treat a simulator pass or a
successful archive upload as proof that Family Controls shielding works on real
devices.

Use the checked-in validation script for the full local gate:

```sh
./build-validation.sh
```

For a quick no-secret snapshot of what is still missing before building or
submitting, run:

```sh
scripts/launch-readiness-status.sh
```

This reports app-facing settings, server/deploy secrets, Google OAuth build
status, and the latest simulator/hardware QA evidence paths without printing
credential values. Simulator evidence includes the summary, gallery, and
`contact-sheet.png` overview from `scripts/qa-simulator-seeds.sh`. It also
flags simulator summaries and hardware records that were generated for a stale
commit, so regenerate QA evidence after changing the build you plan to submit.
Hardware records with `pending-testflight-build`, unfilled device metadata, or
unresolved `Pass / Fail` choices are still reported as pending/incomplete and
are not launch proof.
If Google OAuth is `hidden (missing or placeholder)`, the submitted build should
hide `Continue with Google`; after you create the Google iOS/Web OAuth clients
and paste the public IDs into `Config/AppSecrets.local.xcconfig`, rerun this
command before TestFlight QA.

The script checks required app-facing values in
`Config/AppSecrets.local.xcconfig`, required server/deploy values in
`Config/production.env`, and confirms server-only secrets were not pasted into
the app config. Google OAuth values may all be blank for an Apple-first build;
in that case `Continue with Google` should stay hidden and Google should be
marked N/A in hardware QA. Partial or mismatched Google values fail validation
because they can produce a visible but broken Google flow. To require Google
sign-in for a Google-enabled release, run `REQUIRE_GOOGLE_OAUTH=1
./build-validation.sh`. The script reports only present/missing status, not
secret values. Full Xcode output is written under `.build/validation-logs/`; on
failure, the script prints the last 120 log lines plus the full log path.

For compile-only CI jobs where real secrets are intentionally unavailable:

```sh
SKIP_SECRET_CHECK=1 ./build-validation.sh
```

For repeated TestFlight setup passes on the same device, use Settings ->
`Reset Childlock on this device` -> `Confirm Reset`. Sign Out pauses local
enforcement and preserves local parent settings for the same signed-in parent
account. Signing in with a different account starts fresh setup so child
profiles do not sync to the wrong parent. Reset stops local enforcement, clears
child profiles, app selections, reports, and the parent PIN on that device.

```sh
swift test
git diff --check -- ':!.build'
xcodebuild -project Childlock.xcodeproj \
  -scheme Childlock \
  -configuration Release \
  -destination 'platform=iOS Simulator,id=<simulator-udid>' \
  CODE_SIGNING_ALLOWED=NO \
  build
xcodebuild -project Childlock.xcodeproj \
  -scheme Childlock \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Verify the app icon sizes that App Store Connect requires:

```sh
sips -g pixelWidth -g pixelHeight \
  Sources/Childlock/Assets.xcassets/AppIcon.appiconset/Icon-60@2x.png \
  Sources/Childlock/Assets.xcassets/AppIcon.appiconset/Icon-76@2x.png \
  Sources/Childlock/Assets.xcassets/AppIcon.appiconset/Icon-1024.png
```

Expected dimensions:

- `Icon-60@2x.png`: `120x120`
- `Icon-76@2x.png`: `152x152`
- `Icon-1024.png`: `1024x1024`

Verify extension point identifiers:

```sh
for f in Extensions/*/Info.plist; do
  echo "$f"
  /usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionPointIdentifier' "$f"
done
```

Expected identifiers:

- `com.apple.deviceactivity.monitor-extension`
- `com.apple.family-controls.shield-action-extension`
- `com.apple.family-controls.shield-configuration-extension`

Verify the app and each extension bundle includes the privacy manifest:

```sh
BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -path '*Release-iphonesimulator/Childlock.app' -type d | tail -1)
find "$BUILT_APP" -name PrivacyInfo.xcprivacy -print
```

Expected first-party manifest locations:

- `Childlock.app/PrivacyInfo.xcprivacy`
- `Childlock.app/PlugIns/ChildlockMonitor.appex/PrivacyInfo.xcprivacy`
- `Childlock.app/PlugIns/ChildlockShieldAction.appex/PrivacyInfo.xcprivacy`
- `Childlock.app/PlugIns/ChildlockShieldConfiguration.appex/PrivacyInfo.xcprivacy`

App Store Connect privacy labels must still match actual production behavior:
Supabase account/profile data, RevenueCat purchase state, PostHog analytics,
and any diagnostic data reported by bundled SDK manifests.
Use `docs/APP_PRIVACY_LABELS.md` as the paste-ready baseline.

For a command-line archive after signing is configured:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Childlock.xcodeproj \
  -scheme Childlock \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Childlock.xcarchive \
  archive
```

## Required Real-Device QA

Use a physical child device. The simulator cannot validate the production loop.
The full TestFlight checklist lives in `docs/QA_TESTFLIGHT_CHECKLIST.md`.

- Fresh install opens onboarding.
- Parent signs in with Apple, or Google if the submitted build has Google OAuth
  configured.
- Parent grants Screen Time access on the child-used device.
- Parent selects monitored apps/categories/websites.
- Child starts real selected content and records the start time in the hardware
  QA record.
- First interval does not shield immediately.
- Threshold shields selected content; record the shield timestamp and compare it
  with the configured interval.
- "Start Brain Break" shield path reaches a pending challenge after the child
  taps the Childlock alert or opens Childlock from Home.
- If notifications are denied or missed, Home -> Childlock still reaches the
  pending challenge.
- Challenge completion removes shields.
- The hand-back screen says `Back to your app`, and the child manually reopens
  the now-unshielded app/content. iOS does not let Childlock automatically
  return to another app or restore media state.
- Monitoring re-arms for another full interval.
- Parent PIN is required to leave the child hand-back screen for dashboard.
- Ask Parent creates a parent-visible request, does not open a child challenge
  before the parent responds, can grant one more block, and can explicitly keep
  the child blocked.
- Same shared phone flow keeps dashboard/settings PIN-protected after child use:
  the parent taps `Lock Parent Dashboard` before handoff or leaves Childlock so
  the dashboard auto-locks in the background.
- Child iPad flow is tested by installing and configuring Childlock on the iPad.
- If subscriptions are attached to the submitted App Store version, RevenueCat
  loads monthly and annual packages, sandbox purchase activates `Childlock Pro`,
  restore purchases reactivates Premium, and Premium remains active after app
  restart.
- Support, Privacy, and Terms links open successfully.
