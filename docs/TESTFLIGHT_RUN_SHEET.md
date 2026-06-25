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
10. Start real content in the selected app/site and write down the start time.
11. Confirm nothing shields immediately.
12. Wait for the threshold, then write down the shield time.
13. On the shield, tap `Start`.
14. Open Childlock from the alert or Home.
15. Complete the challenge.
16. Confirm shields clear and the child sees `Done` plus the back-arrow cue.
17. Return to the now-unshielded content app/site using Home or app switcher.
18. Confirm the parent dashboard still needs the PIN.
19. Run one second full interval and confirm it shields again.
20. Run one denied-notification pass: after `Start`, press Home and open
    Childlock manually.

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
10. Complete the shield -> Childlock -> challenge -> `Done` hand-back loop.
11. Confirm monitoring re-arms for a second full interval.
12. If Childlock is also installed on the parent iPhone, use it only for
    login/account smoke testing. Do not mark it as remote iPad control.

Pass means Childlock can be marketed as supporting child iPad use when the app
is installed and configured on the iPad.

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
