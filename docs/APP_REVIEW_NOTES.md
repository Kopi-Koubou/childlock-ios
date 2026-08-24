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
9. Complete the two short, two-choice math questions directly on the Brain Break
   shield. A miss is replaced by a fresh question instead of revealing the other
   answer.
10. After the second correct answer, the shield redraws as `Great job!` for about one second,
    then clears the shield with no further child action and reveals the same
    content underneath.
11. Monitoring re-arms for the next full interval. A parent PIN is still
    required before entering the Childlock dashboard.

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
- In this build, the two-question brain break is part of the system Screen Time
  shield. The protected app or website remains onscreen underneath; Childlock
  does not need to launch and notification permission is not required.
- On success, Childlock briefly reconfigures the shield with a checkmark and
  `Great job!`, then removes the shield. This reveals the already-open content;
  it does not relaunch another app or claim to restore media state.
- App selections are handled through Apple's FamilyControls picker. Opaque app
  selection tokens remain local/on-device.
- Support: https://kouboulabs.com/childlock/support
- Privacy Policy: https://kouboulabs.com/childlock/privacy
- Terms: https://kouboulabs.com/childlock/terms
