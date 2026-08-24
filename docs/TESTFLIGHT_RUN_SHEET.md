# Childlock TestFlight Run Sheet

Use this when the TestFlight build is ready and you are holding the test
device. The full checklist is `docs/QA_TESTFLIGHT_CHECKLIST.md`; this is the
short field guide.

## Before You Start

1. Generate records for the exact TestFlight build:

   ```sh
   scripts/prepare-testflight-qa.sh <testflight-build-number>
   ```

2. Open the generated files under `.build/hardware-qa-records/`.
3. Keep the same-phone record open while testing the shared iPhone.
4. Keep the child-iPad record open while testing the child iPad.
5. If Google is hidden, write `N/A` for Google sign-in. Do not chase Google
   during this build unless `Continue with Google` is visible.
6. For the normal feedback candidate, confirm Settings does not show
   `10-second brain breaks`. Stop if it does; that is the wrong build.

## Pass 1: Same Phone

This proves a parent and child can share one iPhone.

1. Install the TestFlight build on the shared iPhone.
2. Sign in with Apple.
3. Complete setup on that same iPhone.
4. Grant Screen Time access.
5. Choose a real app, category, or website in Apple's Screen Time picker.
6. Pick the shortest brain-break interval.
7. Start enforcement.
8. Lock the parent dashboard or leave Childlock to auto-lock.
9. Hand the iPhone to the child.
10. Loop 1: start real content in the selected app/site and write down the start
    time.
11. Confirm Loop 1 does not shield immediately.
12. Wait for the full production threshold, then write down the shield time.
13. For the anti-guessing pass, choose one wrong answer and confirm a different
    question replaces it with
    `Almost! Try this one` and the content stays shielded.
14. Answer the fresh question correctly; confirm `Nice! One more` appears with
    a different final question and the content remains shielded.
15. Answer the final question correctly.
16. Confirm `Great job!` appears briefly with no buttons.
17. Without touching the screen again, confirm the shield clears and the same
    already-open content is still visible in place.
18. Confirm the parent dashboard still needs the PIN.
19. Deny Childlock notification permission before Loop 2, then lock the parent
    dashboard again.
20. Loop 2: return to the same selected content, record a new content start
    time, and confirm it does not shield immediately.
21. Wait for another full production threshold and record the second shield
    time. This is the monitoring re-arm proof.
22. With notifications still denied, answer the first question correctly,
    confirm a different final question with `Nice! One more`, then answer the
    final question correctly.
23. Confirm `Great job!` briefly appears with no buttons and the shield clears
    without opening Childlock or requiring another touch.
24. Confirm the same already-open content is visible in place after Loop 2.
25. Confirm the parent dashboard still needs the PIN and record both completed
    loops as `Pass`. A second shield appearance without completing steps 22–24
    is not a two-loop pass.

Pass means the shared iPhone can be marketed as a same-phone parent/child use
case.

## Pass 2: Child iPad

This proves Childlock works on a child iPad when the iPad is the configured
child-used device.

1. Install the TestFlight build on the child iPad.
2. Sign in with the same parent account on the iPad.
3. Complete setup on the iPad.
4. Grant Screen Time access on the iPad.
5. Choose real iPad apps/categories/websites in Apple's Screen Time picker.
6. Pick the shortest brain-break interval.
7. Start enforcement on the iPad.
8. Start real content on the iPad and write down the start time.
9. Confirm the shield appears only after the threshold.
10. Confirm the iPad question is the dominant title, progress/supporting text is
    readable, both answer labels are legible, and both system buttons are easy
    to tap in portrait and landscape with default and larger Dynamic Type.
11. Complete both shield questions and confirm automatic return to the
    same iPad content with no post-answer action.
12. Confirm monitoring re-arms for a second full interval.
13. If Childlock is also installed on the parent iPhone, use it only for
    login/account smoke testing. Do not mark it as remote iPad control.

Pass means Childlock can be marketed as supporting child iPad use when the app
is installed and configured on the iPad.

## Optional Internal 10-Second Pass

Run this only when the dedicated internal build shows `10-second brain breaks`
in Settings. The control is deliberately absent from normal archives.

1. Start Screen Time enforcement and wait until its status says `Timing app use`.
2. Turn on `10-second brain breaks`; this must restart the active monitor.
3. Use selected content continuously and record the shield time. Treat roughly
   10 seconds as a test target, not a real-time guarantee from Screen Time.
4. Complete both questions and return to the same content.
5. Continue using the content and confirm a second shield arrives on the same
   short test interval; this proves the extension re-arm retained test mode.

## Purchase Pass

Run this if subscriptions are attached to the App Store version.

1. Open the paywall.
2. Confirm RevenueCat loads monthly and annual products.
3. Complete one sandbox purchase.
4. Confirm Settings changes from `Upgrade` to `Active`.
5. Delete/reinstall or reset as needed.
6. Tap `Restore purchases`.
7. Confirm Premium becomes active again.
8. Force quit and relaunch Childlock.
9. Confirm Premium remains active.

## Stop Conditions

Stop and mark the record blocked if any of these happen:

- Setup cannot continue after selecting real Screen Time items.
- The shield appears immediately instead of after the interval.
- `Start` does not leave a path back to Childlock.
- The child can reach the parent dashboard without the PIN.
- The child-iPad pass appears to require a parent-only iPhone install to
  remotely control a separate iPad. That is not a supported v1 launch claim.
- RevenueCat cannot load products while subscriptions are attached to the
  submitted App Store version.

## Before Public App Review

Run:

```sh
scripts/launch-readiness-status.sh --strict
```

Submit only when strict mode passes and both required hardware records are
filled with passing results.
