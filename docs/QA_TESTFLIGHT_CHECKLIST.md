# Childlock TestFlight QA Checklist

Last checked: 2026-06-23

This checklist separates simulator confidence from real Screen Time proof. The
simulator can validate onboarding state, parent dashboard gating, challenge UI,
and hand-back behavior. A TestFlight build on physical hardware is still
required to prove Family Controls, DeviceActivity thresholds, ManagedSettings
shielding, and extension actions.

## Simulator Smoke Checks

Use Debug builds only. These launch arguments are not part of the Release
TestFlight build. For interactive PIN checks, use a normal signed simulator run;
compile-only builds may pass `CODE_SIGNING_ALLOWED=NO`, but unsigned simulator
runs can make Keychain-backed PIN seeds look broken.

| Launch argument | Expected screen | PIN |
| --- | --- | --- |
| `--childlock-qa-reset` | Fresh onboarding with Apple and Google sign-in | none |
| `--childlock-qa-seed-dashboard` | Unlocked parent dashboard for child `Mia` | `1234` if locked later |
| `--childlock-qa-seed-locked-dashboard` | Parent dashboard lock screen | `1234` |
| `--childlock-qa-seed-pending-challenge` | Child brain-break challenge | `1234` after hand-back |
| `--childlock-qa-seed-pending-math-challenge` | Child math brain-break challenge | `1234` after hand-back |
| `--childlock-qa-seed-pending-memory-challenge` | Child memory brain-break challenge with deterministic card pairs | `1234` after hand-back |
| `--childlock-qa-seed-more-time-request` | Parent dashboard with `Ask Parent` request banner | `1234` if locked later |

Simulator pass criteria:

- Fresh onboarding shows `Sign in with Apple` and `Continue with Google`.
- Seeded dashboard shows a child, recent activity, app tabs, and settings entry.
- Locked dashboard hides parent content until the PIN is entered.
- Pending challenge exposes only the child challenge surface, not dashboard
  controls underneath.
- Math and memory challenge seeds both render child-appropriate challenge UI;
  memory pairs are deterministic in this Debug seed for repeatable simulator QA.
- Correct challenge answer records activity and moves to the hand-back screen.
- Hand-back screen tells the child to return to the app and exposes only
  `I'm a parent`.
- Parent PIN unlock remounts the dashboard.
- More-time seed shows the parent request banner with `Give one more block` and
  `Dismiss`.

## TestFlight Hardware Gates

Run these on a physical device with the TestFlight build. Do not treat Simulator
as sufficient for launch.

1. Fresh install opens onboarding.
2. Parent signs in with Apple.
3. Parent signs out or resets, then signs in with Google.
4. Parent grants Screen Time access on the child-used device.
5. Parent selects at least one real app, category, or website.
6. Parent chooses the shortest brain-break interval.
7. Parent enables notifications when prompted. Also test a denied-notification
   pass: after tapping `Start Brain Break`, press Home and open Childlock.
8. First interval starts without immediately shielding.
9. Selected app shields only after the threshold is reached.
10. Shield copy says `Brain Break`.
11. Primary shield action says `Start Brain Break`, closes the blocked app, and
    leaves a notification/home-screen path back to Childlock.
12. Opening Childlock presents the pending challenge.
13. Completing the challenge clears shields.
14. Monitoring re-arms for another full interval.
15. Child sees hand-back screen and cannot enter the dashboard without the
    parent PIN.
16. `Ask Parent` creates a parent-visible more-time request and does not open
    a pending child challenge before the parent responds.
17. `Give one more block` grants another block and then re-arms enforcement.
18. Restarting enforcement clears stale child challenge and Ask Parent state.
19. If multiple child profiles exist, the pending challenge uses the monitored
    child's age/profile.
20. Support, Privacy, and Terms links open correctly from App Store metadata.

## Same Phone Scenario

Use this when the parent and child share the same iPhone.

1. Install Childlock on the shared iPhone.
2. Parent signs in and completes setup on that iPhone.
3. Parent selects apps/categories used by the child on that same iPhone.
4. Parent sets the PIN and hands the phone to the child.
5. Child uses selected content until the threshold is reached.
6. Child solves the challenge and returns to the now-unlocked app.
7. Child taps `I'm a parent` or tries to enter the dashboard.
8. Expected: dashboard remains gated by the parent PIN.

Pass means Childlock can be marketed as supporting same-phone parent/child use.

## Parent Phone To Child iPad Scenario

Use this when the parent owns an iPhone and the child uses an iPad.

1. Install Childlock from TestFlight on the child iPad.
2. Sign in with the same parent account on the child iPad.
3. Complete Screen Time authorization, app selection, interval setup, and PIN
   setup on the iPad.
4. Use the selected iPad app until the threshold is reached.
5. Complete the shield -> Childlock -> challenge -> hand-back loop on the iPad.
6. Optional: install Childlock on the parent iPhone only for account/login smoke
   testing, not as a remote controller.

Pass means Childlock can be marketed as supporting child iPad use when the app
is installed and configured on the iPad. Do not claim that a parent-only iPhone
install remotely controls a separate child iPad in v1.

## Launch Decision

Submit to public App Review only after:

- Apple sign-in works in TestFlight.
- Google sign-in works in TestFlight.
- Same-phone hardware QA passes.
- Child iPad hardware QA passes, if iPad support remains a launch promise.
- At least one full shield loop passes twice on real hardware.
- App Review notes match the actual device model in `docs/APP_REVIEW_NOTES.md`.
