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
9. Tap "Start Brain Break", then tap the Childlock notification or open
   Childlock from Home and solve the pending challenge.
10. Completing the challenge removes the shield and re-arms monitoring for the
    next interval.
11. After the celebration, the child sees the hand-back screen with `Swipe up`
    guidance. A parent PIN is required before entering the parent
    dashboard. To resume the original app, the child uses Home or the app
    switcher to return to the now-unshielded app/content.

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
- In this build, the shield action closes the blocked app and Childlock also
  posts a local notification to guide the child back to the challenge when
  notifications are enabled. If notifications are denied or missed, pressing
  Home and opening Childlock presents the same pending challenge. Once Childlock
  is foregrounded, it automatically opens the pending brain break.
- Childlock does not automatically return the child to another app after the
  challenge. iOS does not provide a public Screen Time API to reopen arbitrary
  apps or restore media state, so the hand-back screen says `Swipe up` and
  guides the child through Home or the app switcher.
- App selections are handled through Apple's FamilyControls picker. Opaque app
  selection tokens remain local/on-device.
- Support: https://kouboulabs.com/childlock/support
- Privacy Policy: https://kouboulabs.com/childlock/privacy
- Terms: https://kouboulabs.com/childlock/terms
