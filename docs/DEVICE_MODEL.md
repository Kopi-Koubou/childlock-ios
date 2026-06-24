# Childlock Device Model

Last checked: 2026-06-24

Childlock's launch build is a local-first Screen Time app. It locks apps on the
device where the parent completes onboarding, grants Screen Time access, chooses
apps or categories, and starts monitoring.

## Supported For Launch

- Same phone shared by parent and child: supported. The parent configures
  Childlock on that phone, then the child can use monitored apps. Parent
  settings and the dashboard remain behind the parent PIN.
- Child iPad or child-owned iPhone: supported when Childlock is installed and
  configured on that child device. Run onboarding on the iPad/iPhone that needs
  app shielding.
- Multiple child devices: repeat setup on each device the child uses. The same
  parent account can sign in on each device, but launch QA should treat each
  configured device as its own enforcement point.

## Not A V1 Launch Claim

- Do not claim that a parent phone can remotely lock a separate child iPad from
  a parent-only install.
- Do not claim complete cross-device reporting until the app has production
  pull-sync, device identity, and explicit remote dashboard UX.
- Do not store or sync raw Screen Time selection token payloads. App/category
  selection tokens should remain on-device.

## Why

Apple's Screen Time frameworks are device-centered:

- FamilyControls requests authorization for Screen Time access.
- FamilyActivityPicker returns opaque app/category/web-domain selections.
- DeviceActivity monitors activity on the configured device.
- ManagedSettings applies shielding on the configured device.

Backend sync can mirror account, settings, subscription, and challenge history,
but it does not make a parent phone into a remote Screen Time controller by
itself.

Apple references:

- https://developer.apple.com/documentation/familycontrols
- https://developer.apple.com/documentation/screentimeapidocumentation
- https://developer.apple.com/documentation/familycontrols/authorizationcenter
- https://developer.apple.com/documentation/managedsettings/connectionwithframeworks

## TestFlight Device QA

Use a real iPhone or iPad that represents the child's device. The simulator can
verify onboarding UI, but it cannot prove the real shield loop.
Use `docs/QA_TESTFLIGHT_CHECKLIST.md` for the full same-phone and child-iPad
launch matrix.

1. Install the TestFlight build on the child-used device.
2. Sign in with Apple or Google.
3. Grant Screen Time access.
4. Select at least one real app, category, or website.
5. Set the shortest brain-break interval.
6. Open selected app/category/site content and use it continuously until the
   threshold is reached.
7. Confirm the Childlock shield appears after the configured interval.
8. Tap the shield action and return to Childlock.
9. Solve the pending challenge.
10. Confirm shielding clears and monitoring re-arms.
11. Confirm the hand-back screen blocks the dashboard until the parent PIN is
    entered.
12. Repeat on a child iPad if iPad support is part of the first launch promise.
