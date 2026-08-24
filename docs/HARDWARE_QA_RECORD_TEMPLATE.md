# Childlock Hardware QA Record

Use this record for each physical TestFlight device before public App Review.
Simulator screenshots are useful background evidence, but this record is the
launch gate for Family Controls, DeviceActivity thresholds, ManagedSettings
shielding, extension actions, purchases, and touch-free content return behavior.

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
| Child-used device configured | Same iPhone / Child iPad / Child iPhone |
| Parent iPhone role | Same device / Login smoke only / N/A |
| Latest simulator QA summary |  |
| Latest simulator QA gallery |  |
| Latest simulator QA contact sheet |  |
| Google OAuth build settings | Configured / Missing or placeholder |
| Parent sign-in tested | Apple / Google / N/A |
| Notification state tested | Loop 1: Allowed / Denied; Loop 2: Denied |
| Monitored selection | App / Category / Website |
| Content app/activity tested |  |
| Brain-break interval |  |
| Content started at |  |
| Shield appeared at |  |
| Second-loop content started at |  |
| Second-loop shield appeared at |  |
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
| Setup is completed on the physical device the child will use | Pass / Fail |  |
| Screen Time authorization completes on the child-used device | Pass / Fail |  |
| App/category/website selection is non-empty before setup can continue | Pass / Fail |  |
| Child continuously consumes selected content during the interval | Pass / Fail |  |
| First interval starts without immediately shielding | Pass / Fail |  |
| Selected content shields only after the threshold | Pass / Fail |  |
| Shield says `Brain Break · 1 of 2` and shows two answer choices | Pass / Fail |  |
| Wrong answer is replaced by a different question and keeps content shielded | Pass / Fail |  |
| First correct answer shows a different final question with `Nice! One more` | Pass / Fail |  |
| Second correct answer briefly shows `Great job!` without answer buttons | Pass / Fail |  |
| Shield brain break still works when notifications are denied | Pass / Fail / N/A |  |
| Second correct answer clears the shield without another child action | Pass / Fail |  |
| Monitoring re-arms for another full interval | Pass / Fail |  |
| Loop 1 same content is visible in place after automatic shield removal | Pass / Fail |  |
| Second full interval starts without immediately shielding | Pass / Fail |  |
| Second full interval shields again after the production threshold | Pass / Fail |  |
| Loop 2 completes both fresh questions and briefly shows button-free `Great job!` | Pass / Fail |  |
| Loop 2 clears without another touch or opening Childlock | Pass / Fail |  |
| Loop 2 same content is visible in place after automatic shield removal | Pass / Fail |  |
| Parent dashboard stays PIN-gated after child use | Pass / Fail |  |
| Restarting enforcement clears stale shield-challenge state | Pass / Fail |  |

## Same Phone Scenario

Use this when the parent and child share the same iPhone.

| Step | Result | Notes |
| --- | --- | --- |
| Parent installs Childlock on the shared iPhone | Pass / Fail / N/A |  |
| Parent completes setup on that same iPhone | Pass / Fail / N/A |  |
| Shared iPhone is recorded as the child-used configured device | Pass / Fail / N/A |  |
| Parent selects apps/categories used by the child on that same iPhone | Pass / Fail / N/A |  |
| If multiple child profiles exist, parent taps `Make active` for the child before handoff | Pass / Fail / N/A |  |
| Parent sets the PIN, taps `Lock Parent Dashboard` or leaves Childlock to auto-lock, then hands the phone to the child | Pass / Fail / N/A |  |
| Child continuously uses selected content until threshold is reached | Pass / Fail / N/A |  |
| Child completes both shield questions, sees `Great job!`, then returns automatically to the same content with no post-answer action | Pass / Fail / N/A |  |
| Child cannot reach parent dashboard without the PIN | Pass / Fail / N/A |  |

## Child iPad Scenario

Use this when the parent owns an iPhone and the child uses an iPad.

| Step | Result | Notes |
| --- | --- | --- |
| Parent installs Childlock from TestFlight on the child iPad | Pass / Fail / N/A |  |
| Parent signs in with the same parent account on the child iPad | Pass / Fail / N/A |  |
| Child iPad is recorded as the child-used configured device | Pass / Fail / N/A |  |
| Parent completes Screen Time authorization on the iPad | Pass / Fail / N/A |  |
| Parent selects iPad apps/categories/websites on the iPad | Pass / Fail / N/A |  |
| Child continuously uses selected iPad content until threshold is reached | Pass / Fail / N/A |  |
| iPad question, supporting text, answer labels, and system button targets are usable in portrait/landscape at default and larger Dynamic Type | Pass / Fail / N/A |  |
| Child completes the shield-native challenge and returns automatically to the same iPad content | Pass / Fail / N/A |  |
| Parent iPhone, if installed, is used for login/account smoke only | Pass / Fail / N/A |  |
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
