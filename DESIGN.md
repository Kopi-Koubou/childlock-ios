---
name: Childlock
category: Mobile & Family
surface: ios
version: 2.0
status: current
updated: 2026-07-28
colors:
  background: "#F2F1EC"
  surface: "#FFFFFF"
  foreground: "#1F2421"
  muted: "#8A8F88"
  border: "#E8E6DF"
  accent: "#3F6B58"
  accent-secondary: "#C97E5C"
---

# Childlock Design System

> Current brand and product contract for the native Childlock iOS app.
>
> Use this file before `design-spec.md`. When prose, generated artifacts, or
> older screenshots disagree with this file, the current SwiftUI implementation
> and `Sources/Childlock/Views/Shared/DesignTokens.swift` win.

## Product Intent

Childlock turns interruptions to a child's screen time into short, calm brain
breaks. It should feel like a trusted family tool rather than surveillance,
punishment, school software, or a gamified attention trap.

The product has two deliberately different modes:

- **Parent mode:** calm, competent, compact, and trustworthy. Parents configure
  children, Screen Time selection, intervals, reports, notifications, and the
  parent lock.
- **Child mode:** simple, generous, encouraging, and impossible to confuse with
  parent controls. It presents one two-answer brain break directly on the system
  shield, celebrates completion briefly, and reveals the preserved content
  automatically without another child action.

## Source of Truth

Read these sources in order:

1. `DESIGN.md` — brand roles, behavior, and generation constraints.
2. `Sources/Childlock/Views/Shared/DesignTokens.swift` — exact production
   colors, type, spacing, radii, shadows, cards, and button styles.
3. Current SwiftUI views under `Sources/Childlock/Views/`.
4. `.build/qa-simulator-seeds/20260728-174314/contact-sheet.png` — current
   iPhone 17 visual baseline, including the touch-free celebration state.
5. `.build/qa-simulator-seeds/20260727-153219/contact-sheet.png` — current iPad
   (A16) layout baseline at commit `a798032`.
6. `design-spec.md` — deeper product and interaction rationale; its historical
   orange visual direction is superseded.

Do not infer the current product from archived mockups or generated web brand
artifacts.

## Visual Theme

The current direction is **Soft Sage**: warm, quiet, and grounded.

- Warm bone canvases keep the app softer than clinical white.
- White cards organize information without turning every row into a dashboard
  widget.
- Forest sage carries trust, active state, confirmation, and primary action.
- Terracotta is a restrained human accent for attention and secondary emphasis.
- Honey and lavender are semantic accents, not competing brand colors.
- The interface is mostly flat. Soft shadows provide separation only where
  touch or hierarchy benefits.

Avoid generic blue SaaS styling, glossy gradients, glassmorphism, neon colors,
heavy shadows, excessive badges, and reward-system clutter.

## Color Roles

### Core

| Role | Token | Hex | Usage |
| --- | --- | --- | --- |
| Background | Bone | `#F2F1EC` | Main app and challenge canvas |
| Surface | White | `#FFFFFF` | Cards, sheets, inputs, keypad groups |
| Surface muted | Warm stone | `#E8E6DF` | Dividers, quiet controls, disabled surfaces |
| Foreground | Ink | `#1F2421` | Primary copy and headings |
| Secondary text | Ink soft | `#4F574F` | Explanations and body copy |
| Muted text | Ink mute | `#8A8F88` | Captions, timestamps, inactive navigation |
| Faint text/border | Ink faint | `#C5C8C2` | Disabled states and subtle outlines |
| Primary | Forest sage | `#3F6B58` | Main actions, active navigation, success |
| Primary deep | Forest deep | `#2A4D3F` | Strong labels and high-contrast sage text |
| Primary soft | Sage wash | `#D9E5DD` | Informational cards, chips, selected backgrounds |
| Accent | Terracotta | `#C97E5C` | Requests, attention, secondary emphasis |
| Accent soft | Clay wash | `#F1DFD2` | Request and alert backgrounds |

### Semantic

| Role | Hex | Usage |
| --- | --- | --- |
| Success | `#3F6B58` | Completion and positive status |
| Warning/reward | `#B89B4F` | Hints, caution, earned emphasis |
| Warning soft | `#EAE0C5` | Non-alarming hint and notice backgrounds |
| Memory | `#A89BC7` | Memory challenge tiles |
| Shield background | `#1B2420` | System Screen Time shield |
| Shield foreground | `#F2F1EC` | Shield title, subtitle, and action copy |

### Avatar accents

Use only for child identity and small friendly accents:
`#F4A07A`, `#E8A1B5`, `#C9A57E`, `#8FB39E`, `#A89BC7`, `#E0B85A`.

Color is never the only state signal. Pair status color with copy, shape, icon,
selection treatment, or placement.

## Typography

Use native Apple system fonts. Do not introduce Inter or a downloadable web
font into the iOS app.

### Parent-facing hierarchy

| Role | Size | Weight | Design |
| --- | --- | --- | --- |
| Display | 32pt | Bold | Default |
| Display large | 36pt | Bold | Default |
| Title | 28pt | Bold | Default |
| Subtitle | 22pt | Semibold | Default |
| Body | 15pt | Regular | Default |
| Body emphasis | 15pt | Semibold | Default |
| Caption | 13pt | Regular | Default |
| Label | 11pt | Semibold | Default |
| Stat | 22pt | Bold | Default |
| Stat large | 34pt | Bold | Default |

### Child-facing hierarchy

| Role | Size | Weight | Design |
| --- | --- | --- | --- |
| Challenge display | 64pt | Semibold | Rounded |
| Challenge title | 26pt | Semibold | Rounded |
| Challenge body | 24pt | Medium | Rounded |
| Challenge number | 44pt | Semibold | Rounded |

Support Dynamic Type where layouts permit it, preserve meaningful hierarchy at
larger sizes, and never shrink child answers below comfortable reading size.

## Spacing, Shape, and Depth

### Spacing

Use the production scale: `4, 8, 12, 16, 24, 32, 48pt`.

- Parent screens: 24pt page margins on phone when space permits.
- Child challenge screens: at least 24pt outer padding with intentionally sparse
  vertical composition.
- Group related controls tightly; use 24–48pt to separate product sections.
- Preserve iOS safe areas and readable maximum widths on iPad.

### Radius

Use `8, 14, 20, 28pt`, plus full pills.

- Inputs and compact controls: 14pt.
- Cards and major grouped surfaces: 20pt.
- Large panels and friendly onboarding artwork: 28pt.
- Primary and secondary action buttons: pill.

### Shadows

- Small: black at 6%, radius 3, y 1.
- Medium: black at 6%, radius 12, y 4.
- Large: black at 8%, radius 32, y 12.

Prefer the small shadow for cards and controls. Medium and large shadows are for
temporary elevation, sheets, or a genuinely dominant object.

## Core Components

### Primary action

- 54pt high, full-width where it advances a flow.
- Forest sage fill, white semibold 16pt label, pill geometry.
- Pressed state scales to 0.98 and reduces fill opacity.
- Disabled state stays legible and visibly inactive.

### Secondary action

- 54pt high, transparent fill, 1.5pt faint outline, ink label, pill geometry.
- Use for safe alternatives and system-selection actions.
- Do not let a secondary action visually compete with the next required step.

### Cards

- White surface, 20pt radius, approximately 22pt internal padding.
- Small shadow and no ornamental border by default.
- Use one card per meaningful group; avoid card-inside-card nesting.

### Navigation

- Native-feeling four-tab parent navigation: Home, Children, Apps, Settings.
- Active state uses forest sage and a clear label.
- Child challenge and success surfaces never show parent navigation.

### Parent lock

- The parent dashboard remains behind the four-digit PIN after handoff.
- PIN entry must be comfortable, unambiguous, and separate from child actions.
- “More time” requests are parent decisions and use restrained terracotta
  attention styling.

### Brain break

- Enforced brain breaks use the system Screen Time shield so the protected
  content remains directly underneath.
- Show a short two-question checkpoint. Each prompt has exactly two answer
  choices and progress is stated plainly as `1 of 2` / `2 of 2`.
- Ages 3–5 rotate through visual counting, comparison, addition, subtraction,
  missing-number, and simple sequence prompts, calibrated by the child's exact
  age rather than using one repeated addition template.
- Use the dark shield palette, concise copy, and the largest controls the system
  shield provides.
- Wrong answers are gentle and actionable. Never shame, punish, count down, or
  create time pressure.
- Rich full-screen math, pattern, memory, and puzzle views remain practice
  experiences inside Childlock; they are not part of the enforced return path.

### Automatic return

- After both checkpoint questions are answered correctly, redraw the shield as
  a button-free “Great job!” success state with a checkmark.
- Keep the success state to about one second, then clear the shield and reveal
  the content that is already open underneath.
- Request that brief delay with an extension-safe expiring activity. If iOS
  cannot grant or later expires it, skip the remaining visual delay and clear
  the shield immediately; never strand the child on a button-free success
  state.
- There is no return gesture, continue button, arrow cue, parent button, or
  other post-answer touchpoint.
- Do not claim that Childlock relaunches or restores another app. It removes its
  shield from the app or website already onscreen.

### Screen Time shield

- The system shield is the complete enforced brain-break surface.
- Its primary and secondary buttons are the two answer choices.
- An incorrect answer never leaves the solved-by-elimination question onscreen.
  It resets checkpoint progress, generates a different question type, and
  redraws with `Almost! Try this one`.
- The first correct answer generates a different final question and redraws
  with `Nice! One more`; it does not clear the shield.
- The second correct answer briefly redraws a button-free success state, clears
  all selected-content shields, and re-arms monitoring for a full new interval.
- The enforced flow must not require a notification or open Childlock.
- On iPad, put the question in the system title slot, keep progress/supporting
  copy in the subtitle, and request the larger 72pt brain/checkmark symbol.
  `ManagedSettingsUI` owns the final label fonts, panel bounds, button sizes,
  and touch targets; those dimensions must be accepted on physical iPad
  hardware rather than inferred from source or simulator builds.

## Voice and Content

### Parent voice

Clear, calm, direct, and operational.

- Use: “Set up on your child's device”, “Lock Parent Dashboard”, “Choose apps,
  categories, or websites”, “Screen Time enforcement”.
- Explain limits before the user encounters them.
- Prefer a useful sentence over marketing language.
- Avoid: surveillance language, guilt, fear, “take control”, “addiction”, and
  claims of remote control that the launch build does not support.

### Child voice

Short, warm, and age-neutral.

- Use: “Brain Break”, “Nice! One more”, “Great job!”, “Almost! Try this one”.
- Celebrate effort and successful completion.
- Avoid: “wrong”, “failed”, streaks, rankings, penalties, countdowns, and
  patronizing baby talk.

## Accessibility and Interaction Invariants

- Parent touch targets are at least 44pt; custom child-facing targets are at
  least 60pt. System Screen Time shield targets are platform-managed and require
  physical-device accessibility QA.
- Respect Reduce Motion. Movement must never be required to understand state.
- Voice prompts support younger children but do not replace visual information.
- Pair color with text or iconography.
- Preserve VoiceOver labels and predictable focus order.
- Do not block interaction with celebration for more than two seconds.
- Keep the parent safety boundary intact through onboarding, challenge,
  automatic return, and dashboard navigation.

## Current Delivery Context

Snapshot verified 2026-07-28 at git commit `a798032`.

- Native SwiftUI app, marketing version 1.0, build 6.
- Deployment target iOS 17.0; device families iPhone and iPad.
- Four targets: app, Device Activity Monitor, Shield Action, and Shield
  Configuration extensions.
- Launch device model is local-first: Childlock enforces Screen Time on the
  device where setup is completed. A remote parent-phone dashboard is not part
  of the launch build.
- Sign in with Apple is the visible launch path. Google sign-in remains hidden
  while its OAuth identifiers are not configured.
- Production Supabase, RevenueCat SDK, and RevenueCat webhook configuration are
  present. Do not expose keys or invent provider UI.
- Screen Time enforcement and brain breaks remain available without a
  subscription. Premium is for deeper reports and extended history.
- Simulator QA evidence is current for iPhone 17 and iPad (A16).
- Remaining launch proof: physical-device same-phone shield loop and child-iPad
  shield loop.

## Generation and Implementation Rules

- Open Design artifacts are exploratory mobile prototypes, not production
  SwiftUI.
- Use a device frame only for presentation; do not draw iOS status/navigation
  chrome inside the app screen.
- Prototype both phone and tablet behavior for layout-affecting changes.
- Preserve current product capabilities and security boundaries. Never add
  remote monitoring, background child surveillance, a challenge skip, or a
  bypass around the parent PIN.
- Generated files should stay outside `Sources/Childlock/` until Xavier selects
  a direction.
- Accepted work is translated into SwiftUI, then verified with simulator
  screenshots and physical-device Screen Time QA.

## Design Priorities Before Launch

1. Onboarding clarity and confidence around same-device setup.
2. Parent dashboard hierarchy and the lock-before-handoff moment.
3. Brain-break legibility, answer ergonomics, celebration, and touch-free return.
4. Apps and Screen Time selection language.
5. Premium/reporting presentation without weakening free enforcement.
