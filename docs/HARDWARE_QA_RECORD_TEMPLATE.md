# Childlock Hardware QA Record

Use this record for each physical TestFlight device before public App Review.
Simulator screenshots are useful background evidence, but this record is the
launch gate for Family Controls, DeviceActivity thresholds, ManagedSettings
shielding, extension actions, purchases, and real hand-back behavior.

## Run Metadata

| Field | Value |
| --- | --- |
| Build number |  |
| Git commit |  |
| Tester |  |
| Date |  |
| Device model |  |
| iOS version |  |
| Scenario | Same phone / Child iPad / Child iPhone |
| Latest simulator QA summary |  |
| Latest simulator QA gallery |  |
| Latest simulator QA contact sheet |  |
| Google OAuth build settings | Configured / Missing or placeholder |
| Parent sign-in tested | Apple / Google / N/A |
| Notification state tested | Allowed / Denied |
| Monitored selection | App / Category / Website |
| Content app/activity tested |  |
| Brain-break interval |  |
| Content started at |  |
| Shield appeared at |  |
| RevenueCat paywall/offering behaved as expected | Pass / Fail / Not tested |
| RevenueCat offering loaded monthly and annual packages | Pass / Fail / Not tested |
| Purchase activates Childlock Premium entitlement | Pass / Fail / Not tested |
| Restore purchases reactivates Premium | Pass / Fail / Not tested |
| Premium status persists after app restart | Pass / Fail / Not tested |
| Notes/blockers |  |

## Required Shield Loop

| Gate | Result | Notes |
| --- | --- | --- |
| Fresh install or reset starts at onboarding | Pass / Fail |  |
| Parent sign-in completes | Pass / Fail |  |
| Screen Time authorization completes on the child-used device | Pass / Fail |  |
| App/category/website selection is non-empty before setup can continue | Pass / Fail |  |
| Child continuously consumes selected content during the interval | Pass / Fail |  |
| First interval starts without immediately shielding | Pass / Fail |  |
| Selected content shields only after the threshold | Pass / Fail |  |
| Shield copy says `Brain Break` | Pass / Fail |  |
| `Start` closes the selected app | Pass / Fail |  |
| Childlock opens the pending challenge from alert or Home | Pass / Fail |  |
| Denied-notification fallback opens the pending challenge from Home | Pass / Fail / N/A |  |
| Challenge completion clears the shield | Pass / Fail |  |
| Monitoring re-arms for another full interval | Pass / Fail |  |
| Second full interval shields again | Pass / Fail |  |
| Child sees `Back` guidance and returns to the now-unshielded content app/site | Pass / Fail |  |
| Parent dashboard stays PIN-gated after hand-back | Pass / Fail |  |
| `Parent` creates a parent-visible request only | Pass / Fail |  |
| `Allow <interval>` grants time and re-arms enforcement | Pass / Fail |  |
| `Keep blocked` clears the parent request and leaves the child blocked | Pass / Fail |  |
| Restarting enforcement clears stale child challenge/request state | Pass / Fail |  |

## Same Phone Scenario

Use this when the parent and child share the same iPhone.

| Step | Result | Notes |
| --- | --- | --- |
| Parent installs Childlock on the shared iPhone | Pass / Fail / N/A |  |
| Parent completes setup on that same iPhone | Pass / Fail / N/A |  |
| Parent selects apps/categories used by the child on that same iPhone | Pass / Fail / N/A |  |
| If multiple child profiles exist, parent taps `Make active` for the child before handoff | Pass / Fail / N/A |  |
| Parent sets the PIN, taps `Lock Parent Dashboard` or leaves Childlock to auto-lock, then hands the phone to the child | Pass / Fail / N/A |  |
| Child continuously uses selected content until threshold is reached | Pass / Fail / N/A |  |
| Child solves the challenge, sees `Back`, and returns to the unlocked app/site | Pass / Fail / N/A |  |
| Child cannot reach parent dashboard without the PIN | Pass / Fail / N/A |  |

## Child iPad Scenario

Use this when the parent owns an iPhone and the child uses an iPad.

| Step | Result | Notes |
| --- | --- | --- |
| Parent installs Childlock from TestFlight on the child iPad | Pass / Fail / N/A |  |
| Parent signs in with the same parent account on the child iPad | Pass / Fail / N/A |  |
| Parent completes Screen Time authorization on the iPad | Pass / Fail / N/A |  |
| Parent selects iPad apps/categories/websites on the iPad | Pass / Fail / N/A |  |
| Child continuously uses selected iPad content until threshold is reached | Pass / Fail / N/A |  |
| Child completes the shield -> Childlock -> challenge -> hand-back loop on the iPad | Pass / Fail / N/A |  |
| Parent-only iPhone install is not treated as remote iPad control | Pass / Fail / N/A |  |

## Launch Decision

| Decision Gate | Result | Notes |
| --- | --- | --- |
| Apple sign-in works in TestFlight | Pass / Fail |  |
| Google sign-in works in TestFlight if Google OAuth is configured | Pass / Fail / N/A |  |
| RevenueCat purchase and restore QA passes if subscriptions remain attached to this app version | Pass / Fail / N/A |  |
| Same-phone hardware QA passes | Pass / Fail / N/A |  |
| Child-iPad hardware QA passes if iPad support remains in launch copy | Pass / Fail / N/A |  |
| At least two full shield loops pass on real hardware | Pass / Fail |  |
| No unresolved launch blockers remain | Pass / Fail |  |
