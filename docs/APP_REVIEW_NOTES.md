# App Review Notes

Childlock is a parent/guardian-controlled Screen Time app for families. It is
intended to be installed and configured by a parent or guardian on the child's
device.

Reviewer flow:

1. Launch Childlock on an iPhone or iPad running iOS 17 or later.
2. Sign in with Apple or Google as the parent/guardian.
3. Complete onboarding as the parent/guardian.
4. Grant Screen Time access when prompted.
5. Select one or more apps/categories to monitor.
6. Set a short brain-break interval for testing.
7. Open selected app/category/site content and use it continuously until the
   interval threshold is reached.
8. The selected content is shielded with Childlock's "Brain Break" shield.
9. Tap "Start Brain Break", open Childlock from Home or the notification, and
   solve the pending challenge.
10. Completing the challenge removes the shield and re-arms monitoring for the
   next interval.
11. After the celebration, the child sees the hand-back screen. A parent PIN is
    required before entering the parent dashboard.

Notes:

- Screen Time enforcement is available without purchase.
- Sign-in uses Apple's native Sign in with Apple flow or native Google Sign-In
  backed by Supabase Auth. There is no separate username/password account for
  App Review to use.
- Childlock locks apps on the device where setup is completed. For a child iPad,
  install and configure Childlock on the iPad. Same-phone parent/child use is
  supported because the parent dashboard remains PIN-protected. Childlock is
  not presented as a parent-phone remote controller for a separate child iPad in
  this launch build.
- Childlock does not attempt to launch itself from the shield extension because
  iOS does not allow that. The shield closes the blocked app and Childlock also
  posts a local notification to guide the child back to the challenge when
  notifications are enabled. If notifications are denied or missed, pressing
  Home and opening Childlock presents the same pending challenge.
- App selections are handled through Apple's FamilyControls picker. Opaque app
  selection tokens remain local/on-device.
- Support: https://kouboulabs.com/childlock/support
- Privacy Policy: https://kouboulabs.com/childlock/privacy
- Terms: https://kouboulabs.com/childlock/terms
