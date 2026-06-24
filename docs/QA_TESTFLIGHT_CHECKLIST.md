# Childlock TestFlight QA Checklist

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

For repeatable visual QA, run:

```sh
scripts/qa-simulator-seeds.sh
```

The script builds a Debug simulator app, launches each seeded state on iPhone 17
and iPad (A16), and writes screenshots, `summary.md`, `gallery.html`, and
`contact-sheet.png` under `.build/qa-simulator-seeds/`. Open `gallery.html` for visual review of the full phone/iPad parent and child UI set, or use the
contact sheet for a quick all-states scan.

| Launch argument | Expected screen | PIN |
| --- | --- | --- |
| `--childlock-qa-reset` | Fresh onboarding with Sign in with Apple; Google appears only when OAuth IDs are configured | none |
| `--childlock-qa-seed-onboarding-devices` | Signed-in onboarding on the local-first device setup step | none |
| `--childlock-qa-seed-onboarding-setup` | Signed-in setup with Screen Time authorized and no picker selection returned yet | none |
| `--childlock-qa-seed-dashboard` | Unlocked parent dashboard for child `Mia` | `1234` if locked later |
| `--childlock-qa-seed-locked-dashboard` | Parent dashboard lock screen | `1234` |
| `--childlock-qa-seed-pending-challenge` | Child brain-break challenge | `1234` after hand-back |
| `--childlock-qa-seed-pending-math-challenge` | Child math brain-break challenge | `1234` after hand-back |
| `--childlock-qa-seed-pending-memory-challenge` | Child memory brain-break challenge with deterministic card pairs | `1234` after hand-back |
| `--childlock-qa-seed-handback` | Completed child hand-back screen after a solved challenge | `1234` |
| `--childlock-qa-seed-more-time-request` | Parent dashboard with `Ask Parent` request banner | `1234` if locked later |
| `--childlock-qa-seed-children-tab` | Parent Children tab with profile card and reports controls | `1234` if locked later |
| `--childlock-qa-seed-add-child-sheet` | Parent add-child sheet with a save-ready draft profile | `1234` if locked later |
| `--childlock-qa-seed-apps-tab` | Parent Apps tab with Screen Time selection and planning labels | `1234` if locked later |
| `--childlock-qa-seed-settings-tab` | Parent Settings tab with Premium, notifications, account, reset, and enforcement rows | `1234` if locked later |
| `--childlock-qa-seed-paywall` | Premium paywall fallback with reports-only upgrade positioning | `1234` if locked later |

Simulator pass criteria:

- Fresh onboarding shows `Sign in with Apple`. `Continue with Google` is shown
  only when the build has real Supabase and Google OAuth IDs; placeholder builds
  hide it rather than exposing a dead-end button.
- Device setup seed explains same-phone use, child iPad setup, and that a
  parent-only iPhone install does not remotely lock a separate iPad at launch.
- Setup seed explains that `Continue` stays disabled until Apple's picker
  returns at least one real app, category, or website selection, with the
  disabled action, reason, and `Choose Screen Time items` recovery action
  pinned at the bottom of the setup screen.
- Seeded dashboard shows a child, recent activity, app tabs, settings entry,
  and a same-phone handoff card that can lock the parent dashboard.
- Children tab seed shows the child profile, reports controls, and add-child
  entry without overlap on iPhone and iPad.
- Children tab makes the active child visible; if multiple children are added
  on one shared device, `Make active` switches which child's settings and
  monitoring are used before handoff.
- Add-child sheet seed shows the child name, age, avatar, copied-settings
  footer, and enabled save action without overlap on iPhone and iPad.
- Apps tab seed shows Screen Time selection copy plus fallback planning labels
  without overlap on iPhone and iPad.
- Settings tab seed shows Premium/restore, notifications, account, reset,
  enforcement controls, and same-phone/child-iPad TestFlight handoff guidance
  without overlap on iPhone and iPad. With planning labels only, `Start Screen
  Time Enforcement` must be disabled until a real Screen Time picker selection
  exists.
- Paywall seed keeps the upgrade framed around deeper reports, shows that
  Screen Time enforcement remains included, and renders product-unavailable
  fallback copy without overlap on iPhone and iPad.
- Locked dashboard hides parent content until the PIN is entered.
- Pending challenge exposes only the child challenge surface, not dashboard
  controls underneath.
- Math and memory challenge seeds both render child-appropriate challenge UI;
  memory pairs are deterministic in this Debug seed for repeatable simulator QA.
- Correct challenge answer records activity and moves to the hand-back screen.
- Hand-back seed tells the child to return to the unlocked app and exposes only
  `I'm a parent`.
- Parent PIN unlock remounts the dashboard.
- More-time seed shows the parent request banner with `Give one more block` and
  `Keep blocked`.

Simulator evidence handoff:

- Treat `.build/qa-simulator-seeds/<run-id>/summary.md` and
  `.build/qa-simulator-seeds/<run-id>/gallery.html`, plus
  `.build/qa-simulator-seeds/<run-id>/contact-sheet.png`, as generated
  evidence, not checked-in release metadata. Do not edit this checklist only to
  chase a new run ID.
- `scripts/new-hardware-qa-record.sh <scenario> <build-number>` pre-fills the
  newest generated simulator summary, gallery, and contact-sheet paths into the
  physical QA record, so the record used during TestFlight points at the
  correct visual background evidence.
- The latest generated simulator sweep should capture every seeded state across
  iPhone 17 and iPad (A16), covering onboarding, device-model copy,
  setup-disabled state, parent dashboard, locked dashboard, child math/memory
  challenges, hand-back, more-time request, Children, Apps, Settings,
  add-child, and paywall fallback surfaces. Run
  `scripts/launch-readiness-status.sh` to confirm the newest simulator summary,
  gallery, and contact sheet were generated for the current git commit.
- When regenerating evidence, explicitly spot-check the setup seed: it must show
  `Tell us about your child`, the Screen Time picker explanation, and the pinned
  disabled Continue reason plus `Choose Screen Time items` action. A setup seed
  that falls back to the welcome screen is not a valid pass.

This simulator pass does not prove the real Screen Time shield loop. Keep the
TestFlight hardware gates below as the launch blocker until they pass on
physical devices.

## Hardware QA Record

Fill this out for each physical TestFlight device before public App Review. A
Simulator pass is useful background evidence, but this record is the launch
gate for the real Screen Time loop.

To create a timestamped fillable record under ignored `.build` output, run:

```sh
scripts/new-hardware-qa-record.sh same-phone <build-number>
scripts/new-hardware-qa-record.sh child-ipad <build-number>
```

The generated record is based on `docs/HARDWARE_QA_RECORD_TEMPLATE.md`.
It pre-fills the build number, date, scenario, git commit, tester name when
available, the latest simulator QA summary path, and the latest simulator QA
gallery and contact-sheet paths.

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
| Shield appeared only after threshold | Pass / Fail |
| `Start Brain Break` closed selected app | Pass / Fail |
| Childlock opened pending challenge from alert or Home | Pass / Fail |
| Challenge completion cleared shield | Pass / Fail |
| Monitoring re-armed for a new interval | Pass / Fail |
| Child saw `Ready to go back` guidance and manually reopened the now-unshielded content app/site | Pass / Fail |
| Parent dashboard stayed PIN-gated after hand-back | Pass / Fail |
| RevenueCat paywall/offering behaved as expected | Pass / Fail / Not tested |
| RevenueCat offering loaded monthly and annual packages | Pass / Fail / Not tested |
| Purchase activates Childlock Premium entitlement | Pass / Fail / Not tested |
| Restore purchases reactivates Premium | Pass / Fail / Not tested |
| Premium status persists after app restart | Pass / Fail / Not tested |
| Notes/blockers |  |

Minimum evidence before launch:

- One completed same-phone record with Apple sign-in.
- If the build has Google OAuth configured and `Continue with Google` is
  visible, one completed same-phone or child-device record with Google sign-in.
- If the build does not have Google OAuth configured, record Google as N/A,
  confirm the button is hidden, and keep App Review notes Apple-first.
- One completed child-iPad record if iPad support remains in App Store copy.
- One denied-notification pass proving Home -> Childlock still opens the
  pending challenge.
- One second full shield loop on the same device proving monitoring re-arms.
- If subscriptions remain attached to the App Store version, one purchase and
  restore pass proving RevenueCat returns monthly/annual packages, activates
  `Childlock Pro`, restores Premium, and keeps Premium active after app restart.

Before starting hardware QA, run `scripts/launch-readiness-status.sh` from the
repo root. It prints the current Google OAuth build status and latest
`.build/qa-simulator-seeds` / `.build/hardware-qa-records` paths without
printing secrets. If it marks simulator or hardware evidence as stale, generate
fresh evidence for the current commit before treating it as launch proof.
If a hardware record is marked `pending TestFlight build` or `incomplete
checklist`, finish the real-device run and regenerate or fill the record before
submitting to public App Review.

## TestFlight Hardware Gates

Run these on a physical device with the TestFlight build. Do not treat Simulator
as sufficient for launch.

1. Fresh install opens onboarding.
2. Parent signs in with Apple.
3. Complete setup once with Apple.
4. From Settings, use `Reset Childlock on this device` -> `Confirm Reset`.
5. Confirm the app returns to fresh onboarding with no parent dashboard access.
6. If Google OAuth is configured and `Continue with Google` is visible, sign in
   with Google and complete setup again. If the Google button is not visible,
   record Google as N/A for this build and keep App Review notes Apple-first.
7. Parent grants Screen Time access on the child-used device.
8. Parent selects at least one real app, category, or website.
   - In the Childlock setup screen, tap `Choose apps, categories, or websites`,
     select at least one item in Apple's Screen Time picker, then tap `Done`.
     The setup `Continue` button stays disabled until the picker returns a real
     selection summary.
9. Parent chooses the shortest brain-break interval.
10. Parent enables notifications when prompted. Also test a denied-notification
   pass: after tapping `Start Brain Break`, press Home and open Childlock.
11. Open the selected app/category/site and start real child-like content,
    such as a video, game session, social feed, or website. Record the content
    app/activity and start time in the hardware QA record.
12. First interval starts without immediately shielding while the content is
    being consumed.
13. Selected content shields only after the threshold is reached. Record the
    shield timestamp and compare it with the configured interval.
14. Shield copy says `Brain Break`.
15. Primary shield action says `Start Brain Break`, closes the blocked app, and
    leaves a Childlock alert/Home path back to the pending challenge.
16. Opening Childlock presents the pending challenge.
17. Completing the challenge clears shields.
18. Monitoring re-arms for another full interval.
19. Child sees the `Ready to go back` hand-back guidance, taps the cue, swipes
    up or presses Home to reopen the now-unshielded content app/site, and
    cannot enter the dashboard without the parent PIN.
20. `Ask Parent` creates a parent-visible more-time request and does not open
    a pending child challenge before the parent responds.
21. `Give one more block` grants another block and then re-arms enforcement.
22. `Keep blocked` clears the parent request while keeping the child blocked
    until they start and complete the brain break.
23. Restarting enforcement clears stale child challenge and Ask Parent state.
24. If multiple child profiles exist, the pending challenge uses the monitored
    child's age/profile.
25. Support, Privacy, and Terms links open correctly from App Store metadata.
26. If subscriptions are attached to this App Store version, open the paywall
    and confirm RevenueCat loads monthly and annual products.
27. Complete a sandbox purchase and confirm the Settings row changes from
    `Upgrade` to `Active`.
28. Delete/reinstall or reset as needed, tap `Restore purchases`, and confirm
    Premium becomes active again.
29. Force quit and relaunch Childlock, then confirm Premium is still active and
    weekly/all-time Children reports remain available.

## Fresh Setup Reset

Use Settings -> `Reset Childlock on this device` when you need a real fresh
setup pass on the same TestFlight install. This is different from Sign Out:
Sign Out pauses local enforcement and preserves local parent settings for the
same signed-in parent account. Signing in with a different account starts fresh
setup so child profiles do not sync to the wrong parent. Reset stops local
enforcement, clears child profiles, app selections, reports, and the parent PIN
on that device.

## Same Phone Scenario

Use this when the parent and child share the same iPhone.

1. Install Childlock on the shared iPhone.
2. Parent signs in and completes setup on that iPhone.
3. Parent selects apps/categories used by the child on that same iPhone.
4. If multiple child profiles exist, parent opens Children and taps
   `Make active` on the child who is about to use the shared phone.
   Only one active child monitor runs on a configured device at a time.
   Switching the active child replaces the previous local monitor.
5. Parent sets the PIN, taps `Lock Parent Dashboard` or leaves Childlock to
   let it auto-lock, and hands the phone to the child.
6. Child continuously uses selected content until the threshold is reached.
7. Child solves the challenge, sees `Ready to go back`, taps the cue, swipes
   up or presses Home, and manually reopens the now-unshielded app/site.
8. Child taps `I'm a parent` or tries to enter the dashboard.
9. Expected: dashboard remains gated by the parent PIN.

Pass means Childlock can be marketed as supporting same-phone parent/child use.

## Parent Phone To Child iPad Scenario

Use this when the parent owns an iPhone and the child uses an iPad.

1. Install Childlock from TestFlight on the child iPad.
2. Sign in with the same parent account on the child iPad.
3. Complete Screen Time authorization, app selection, interval setup, and PIN
   setup on the iPad.
4. Use the selected iPad app or website continuously until the threshold is
   reached.
5. Complete the shield -> Childlock -> challenge -> hand-back loop on the iPad.
6. Optional: install Childlock on the parent iPhone only for account/login smoke
   testing, not as a remote controller.

Pass means Childlock can be marketed as supporting child iPad use when the app
is installed and configured on the iPad. Do not claim that a parent-only iPhone
install remotely controls a separate child iPad at launch.

## Launch Decision

Submit to public App Review only after:

- Hardware QA records above are filled in with no unresolved launch blockers.
- Apple sign-in works in TestFlight.
- Google sign-in works in TestFlight if Google OAuth is configured.
- RevenueCat purchase and restore QA passes if subscriptions remain attached to
  this app version.
- Same-phone hardware QA passes.
- Child iPad hardware QA passes, if iPad support remains a launch promise.
- At least one full shield loop passes twice on real hardware.
- App Review notes match the actual device model in `docs/APP_REVIEW_NOTES.md`.
