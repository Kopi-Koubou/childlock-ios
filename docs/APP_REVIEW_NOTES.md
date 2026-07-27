# App Review Notes

Childlock is a parent/guardian-controlled Screen Time app for families. It is
intended to be installed and configured by a parent or guardian on the child's
device.

Reviewer flow:

1. Launch Childlock on an iPhone or iPad running iOS 17 or later.
2. Sign in with Apple as the parent/guardian. If the submitted build has Google
   OAuth configured, Google sign-in is also available.
3. Complete onboarding as the parent/guardian.
4. Grant Screen Time access when prompted.
5. Select one or more apps/categories to monitor.
6. Set a short brain-break interval for testing.
7. Open selected app/category/site content and use it continuously until the
   interval threshold is reached.
8. The selected content is shielded with Childlock's "Brain Break" shield.
9. Tap "Start", then tap the Childlock notification and solve the pending
   challenge. The original app stays in place behind its shield.
10. Completing the challenge removes the shield and re-arms monitoring for the
    next interval.
11. After the brief celebration, the child sees `Great job!`, `Swipe back`,
    and a right-arrow gesture cue. On devices with a Home indicator, swiping
    right along the bottom edge returns directly to the now-unshielded previous
    app. A parent PIN is required before entering the parent dashboard.

Notes:

- Screen Time enforcement is available without purchase.
- Sign-in uses Apple's native Sign in with Apple flow and, when configured for
  the submitted build, native Google Sign-In backed by Supabase Auth. Google is
  hidden in builds without valid OAuth IDs rather than exposing a non-working
  button. There is no separate username/password account for App Review to use.
- Childlock locks apps on the device where setup is completed. For a child iPad,
  install and configure Childlock on the iPad. Same-phone parent/child use is
  supported because the parent dashboard remains PIN-protected. Childlock is
  not presented as a parent-phone remote controller for a separate child iPad in
  this launch build.
- In this build, the shield action keeps the blocked app in place and Childlock
  posts a local notification to open the challenge when notifications are
  enabled. This preserves the original activity as the previous app. If
  notifications are denied or missed, pressing Home and opening Childlock
  presents the same pending challenge. Once Childlock is foregrounded, it
  automatically opens the pending brain break.
- Childlock does not automatically return the child to another app after the
  challenge. iOS does not provide a public Screen Time API to reopen arbitrary
  apps or restore media state, so the hand-back screen stays very brief and
  teaches the system gesture: `Great job!`, `Swipe back`, and a right-arrow cue.
  Swiping right along the bottom edge returns to the preserved previous app on
  devices with a Home indicator.
- App selections are handled through Apple's FamilyControls picker. Opaque app
  selection tokens remain local/on-device.
- Support: https://kouboulabs.com/childlock/support
- Privacy Policy: https://kouboulabs.com/childlock/privacy
- Terms: https://kouboulabs.com/childlock/terms
