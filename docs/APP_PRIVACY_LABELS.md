# App Store Privacy Labels

Use this as the paste-ready baseline for App Store Connect App Privacy. Review it
before every submission against the current binary, provider dashboards, and
public privacy policy.

## Tracking

Data used to track users across apps and websites owned by other companies:

```text
No
```

Childlock does not sell personal information, does not show ads, and does not
use child data for third-party advertising.

## Data Linked To The User

Select these categories because Childlock signs parents in and syncs account,
purchase, and app state to production services:

| Category | Examples in Childlock | Purpose |
| --- | --- | --- |
| Contact Info | Parent email, parent name when provided by Apple or Google | App functionality, account management |
| Identifiers | Supabase user ID, RevenueCat app user ID | App functionality, account management |
| Purchases | Subscription status and purchase history through Apple/RevenueCat | App functionality |
| Usage Data | Challenge summaries, report windows, app settings, subscription state | App functionality |

## Data Not Linked To The User

Select these only if App Store Connect asks for SDK-level disclosure in addition
to the linked app data above:

| Category | Source | Purpose |
| --- | --- | --- |
| Product Interaction | PostHog screen and lifecycle events, plus explicit flow events | Analytics |
| Other Usage Data | PostHog usage metadata | Analytics |
| Crash Data | Bundled PostHog crash reporter privacy manifest | App functionality |
| Other Diagnostic Data | Bundled PostHog crash reporter privacy manifest | App functionality |

PostHog is intentionally kept aggregate-only in app code. Do not call
`PostHogSDK.shared.identify` or attach the Supabase user ID to analytics events.
RevenueCat and Supabase may still use the authenticated user ID because purchase
state and account sync require it.

## Data Not Collected

Do not select these for the current v1 behavior:

- Precise or coarse location
- Contacts
- Browsing history
- Search history
- Health and fitness
- Financial information beyond Apple-managed purchase history
- User photos, videos, audio, gameplay content, or files
- Raw Screen Time app selection token payloads
- Child full names in backend sync

## Screen Time And Child Data Notes

Apple FamilyControls selections are opaque tokens. The app stores those tokens
locally on device or in the app group for Screen Time extensions. Do not sync raw
selection token payloads to Supabase, RevenueCat, PostHog, or support tooling.

Current backend sync sends parent-owned account state, settings, subscription
status, child profile metadata such as age band/avatar/interval, and summary
challenge activity. It does not send raw app selections or child full names.

## Final Submission Check

Before submission:

1. Confirm the public privacy policy is live at
   `https://kouboulabs.com/childlock/privacy`.
2. Confirm the built app and bundled SDK manifests still report no tracking.
3. Confirm analytics remains aggregate-only and does not call
   `PostHogSDK.shared.identify`.
4. Confirm any new analytics event avoids child names, selected app names,
   app-selection tokens, support messages, or free-form child content.
