# App Store Connect Metadata

Use this as the paste-ready baseline for the first TestFlight/App Review pass.
Keep the App Store Connect product IDs exactly aligned with
`SubscriptionService`.

## Product Page

App name:

```text
Childlock
```

Subtitle:

```text
Brain breaks for screen time
```

Promotional text:

```text
Help children pause, solve a quick brain break, and return to screen time with calmer transitions.
```

Description:

```text
Childlock helps parents turn selected screen time into short learning breaks.

Set up Childlock on the device your child uses, choose the apps, categories, or websites you want to monitor with Apple's Screen Time picker, and pick a brain-break interval. When the interval is reached, Childlock pauses selected content and guides your child back to a quick age-aware challenge.

Parents keep settings protected with a PIN. Children can solve challenges and hand the device back, but they cannot change monitoring settings.

Childlock is designed for family use:

- Works with Apple's Screen Time and Family Controls APIs
- Lets parents choose monitored apps or categories
- Shows quick math and memory challenges
- Tracks basic challenge progress
- Keeps Screen Time selection tokens on-device

Screen Time enforcement is included. Childlock Premium unlocks deeper reporting windows and extended activity history.
```

Keywords:

```text
screen time,parental control,kids,focus,learning,puzzles,family,child safety,parenting
```

Support URL:

```text
https://kouboulabs.com/childlock/support
```

Privacy Policy URL:

```text
https://kouboulabs.com/childlock/privacy
```

App Privacy answers:

```text
Use docs/APP_PRIVACY_LABELS.md as the paste-ready baseline. Childlock does not
track users across apps and websites owned by other companies.
```

Terms URL:

```text
https://kouboulabs.com/childlock/terms
```

## App Review Notes

```text
Childlock is intended to be installed and configured by a parent or guardian on the child's device.

Reviewer flow:
1. Launch Childlock on an iPhone or iPad running iOS 17 or later.
2. Sign in with Apple, or Google if the submitted build has Google OAuth
   configured.
3. Grant Screen Time access when prompted.
4. Select one or more apps/categories to monitor.
5. Set a short brain-break interval.
6. Open selected app/category/site content until the interval threshold is reached.
7. The selected content is shielded with Childlock's Brain Break shield.
8. Tap Start, then tap the Childlock notification or open Childlock
   from Home and solve the pending challenge.
9. Completing the challenge removes the shield and re-arms monitoring.
10. The child hand-back screen says `Great job!` and `Swipe back` with a
    right-arrow gesture cue. Swiping right along the bottom edge returns to the
    preserved previous app. The parent PIN is still required before entering
    the parent dashboard.

Sign-in uses Apple's native Sign in with Apple flow and, when configured for the
submitted build, native Google Sign-In backed by Supabase Auth. Builds without
valid Google OAuth IDs hide the Google button rather than exposing a non-working
option. There is no separate username/password account for App Review.

Screen Time enforcement is available without purchase. Childlock Premium unlocks deeper reporting windows and extended activity history.

Childlock locks apps on the device where setup is completed. For a child iPad,
install and configure Childlock on the iPad. Same-phone parent/child use is
supported because the parent dashboard remains PIN-protected. Childlock is not
presented as a parent-phone remote controller for a separate child iPad in this
launch build.
```

## Subscriptions

Subscription group reference name:

```text
Childlock Premium
```

RevenueCat entitlement:

```text
Childlock Pro
```

Products:

```text
childlock_premium_monthly
childlock_premium_annual
```

RevenueCat offering checklist:

- Current offering contains monthly and annual packages.
- Monthly package maps to `childlock_premium_monthly`.
- Annual package maps to `childlock_premium_annual`.
- Both products unlock the `Childlock Pro` entitlement.
- Restore purchases turns the Settings row from `Upgrade` to `Active`.
- Premium users can switch Children reports between Day, Week, and All Time.

Subscription review notes:

```text
Childlock Premium unlocks deeper reporting windows and extended activity history in the parent dashboard. Screen Time enforcement, app shielding, and brain breaks remain available without purchase.
```
