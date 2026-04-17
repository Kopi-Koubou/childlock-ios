# Childlock — Design Specification

**Version:** 1.0
**Date:** 2026-03-13
**Author:** Kato (AI Chief of Staff)
**Status:** Draft — pending Xavier review
**PRD Reference:** `prd.md` v1.0

---

## 1. Design Philosophy

### Core Principles

| # | Principle | Application |
|---|-----------|-------------|
| 1 | **Warm, not clinical** | Rounded corners, soft shadows, warm color palette. Never sterile or corporate. (PRD Appendix A.1) |
| 2 | **Two audiences, one app** | Parent mode is competent and data-rich. Child mode is playful and encouraging. They never bleed into each other. |
| 3 | **Celebrate effort** | Wrong answers get encouragement. Success gets fireworks. No negative language anywhere. (PRD Appendix A.2) |
| 4 | **Invisible until needed** | On child's device, Childlock has zero persistent UI. It only appears when a challenge triggers. (PRD Appendix A.4) |
| 5 | **Fast and forgiving** | Challenge load <500ms. Touch targets ≥60pt for kids. No precision taps. No timing pressure. (PRD Appendix A.5) |
| 6 | **Accessible by default** | VoiceOver, Dynamic Type, color-blind safe palette, dyslexia-friendly type. Not an afterthought. |

### Design References

- **Tone:** Apple Fitness+ (encouraging without being patronizing), Headspace (warm, rounded, trustworthy)
- **Child UI:** Duolingo (celebration animations), Pok Pok (tactile, hand-drawn feel)
- **Parent UI:** Apple Health (clean data presentation), Day One (warm neutrals, readable)
- **Anti-references:** Generic blue SaaS dashboards, gamified chaos (too many badges/coins/popups)

---

## 2. Visual Design Language

### 2.1 Color Palette

```
PRIMARY PALETTE (Warm Core)
┌──────────────────────────────────────────────────────┐
│  Sunrise Orange   #F2994A  ██████  Primary action    │
│  Coral Warm       #EB5757  ██████  Alerts, emphasis  │
│  Honey Gold       #F2C94C  ██████  Stars, rewards    │
│  Leaf Green       #6FCF97  ██████  Success, correct  │
│  Sky Calm         #56CCF2  ██████  Info, links       │
│  Lavender Soft    #BB6BD9  ██████  Memory challenges │
└──────────────────────────────────────────────────────┘

NEUTRAL PALETTE
┌──────────────────────────────────────────────────────┐
│  Cream             #FFF8F0  ██████  Background       │
│  Warm White        #FEFCF9  ██████  Cards            │
│  Sand              #E8DDD3  ██████  Dividers         │
│  Warm Gray         #828282  ██████  Secondary text   │
│  Charcoal          #333333  ██████  Primary text     │
│  Deep Brown        #1A1A1A  ██████  Headings (dark)  │
└──────────────────────────────────────────────────────┘

CHALLENGE TYPE COLORS
┌──────────────────────────────────────────────────────┐
│  Math     →  Sunrise Orange  #F2994A                 │
│  Pattern  →  Sky Calm        #56CCF2                 │
│  Memory   →  Lavender Soft   #BB6BD9                 │
│  Puzzle   →  Leaf Green      #6FCF97                 │
└──────────────────────────────────────────────────────┘
```

**Color-blind safety:** All challenge-type colors pass WCAG AA contrast on cream background. Each type also uses a distinct icon shape (circle for math, triangle for pattern, square for memory, star for puzzle) so color is never the only differentiator.

**Dark mode:** Supported for parent dashboard only. Child challenge UI always uses light/cream background for maximum readability.

### 2.2 Typography

| Role | Font | Size | Weight | Notes |
|------|------|------|--------|-------|
| **Child: Challenge instructions** | SF Rounded | 28pt | Bold | Dyslexia-friendly; large, clear letterforms |
| **Child: Numbers/math** | SF Rounded | 48pt | Heavy | Must be legible from arm's length |
| **Child: Feedback text** | SF Rounded | 24pt | Medium | "Great job!" / "Try again!" |
| **Parent: Section headers** | SF Pro Rounded | 22pt | Semibold | Warm but professional |
| **Parent: Body text** | SF Pro Text | 17pt | Regular | Standard iOS readability |
| **Parent: Stats/numbers** | SF Pro Rounded | 34pt | Bold | Dashboard hero numbers |
| **Parent: Captions** | SF Pro Text | 13pt | Regular | Secondary info, timestamps |

**Dynamic Type:** Full support. Child challenge UI scales between 24pt–56pt base. Parent dashboard scales per iOS standard.

**Why SF Rounded:** Built into iOS (no bundle size cost), excellent readability at large sizes, rounded terminals feel friendly and warm without sacrificing legibility. Performs well for dyslexic readers due to distinct letterforms (b/d, p/q differentiation is strong).

### 2.3 Iconography & Illustration

- **Style:** Rounded line icons, 3pt stroke weight, warm tones. Similar to SF Symbols "rounded" variant but with custom personality.
- **Child-facing illustrations:** Soft, hand-drawn-style characters. Not cartoon-babyish. Think Pok Pok or Headspace — stylized, warm, ageless enough for 3–12 range.
- **Avatars:** 12 pre-designed avatar options (animals in warm style — fox, owl, bear, bunny, cat, dog, turtle, penguin, koala, lion, elephant, panda). Each has 3 color variants. No human-face avatars (avoids skin tone complexity for MVP).
- **Challenge illustrations:** Minimal. Math uses clean numerals. Patterns use geometric shapes. Memory uses simple, recognizable icons (apple, star, sun, moon, etc.). Puzzles use abstract shapes.

### 2.4 Motion & Animation

| Trigger | Animation | Duration | Style |
|---------|-----------|----------|-------|
| Challenge appears | Slide up from bottom + gentle scale | 400ms | Spring (damping 0.8) |
| Correct answer | Confetti burst + star pulse | 1200ms | Particle system + scale bounce |
| Wrong answer | Gentle shake + color pulse | 300ms | Horizontal shake (±8pt) |
| Challenge complete | Celebration sequence (stars, character dance) | 2000ms | Lottie or SpriteKit |
| Screen unlock | Fade to transparent, dissolve away | 500ms | Opacity + blur reduction |
| Button tap | Scale down 0.95 → bounce back | 200ms | Spring (damping 0.7) |
| Timer progress | Smooth fill of progress arc | Continuous | Linear interpolation |

**Animation principles:**
- Success animations are loud and celebratory — kids should feel accomplished
- Failure animations are gentle and brief — no shame, just "try again"
- No animation should block interaction for more than 2 seconds
- All animations respect iOS "Reduce Motion" accessibility setting (cross-dissolve fallbacks)

### 2.5 Spacing & Layout Grid

- **Child UI:** 24pt margins, 16pt gutter. Everything generously spaced for small fingers.
- **Parent UI:** 20pt margins, 12pt gutter. Standard iOS density.
- **Touch targets:** Minimum 60pt × 60pt for child UI (Apple recommends 44pt — we exceed for kids). Minimum 44pt × 44pt for parent UI.
- **Safe areas:** Respect all iOS safe areas. Challenge UI never renders under notch or home indicator.

---

## 3. User Flows

### 3.1 Parent Setup Flow

```
┌─────────────┐    ┌──────────────┐    ┌──────────────┐
│  App Store   │───▶│   Welcome    │───▶│  Sign Up /   │
│  Download    │    │   Screen     │    │  Sign In     │
└─────────────┘    └──────────────┘    └──────────────┘
                                              │
                   ┌──────────────────────────┘
                   ▼
         ┌──────────────────┐    ┌──────────────────┐
         │  Family Sharing  │───▶│  Create Child     │
         │  Authorization   │    │  Profile          │
         │  (Apple prompt)  │    │  (name, age,      │
         └──────────────────┘    │   avatar)          │
                                 └──────────────────┘
                                        │
                   ┌────────────────────┘
                   ▼
         ┌──────────────────┐    ┌──────────────────┐
         │  Select Apps     │───▶│  Set Interval     │
         │  to Monitor      │    │  & Difficulty     │
         │  (FamilyActivity │    │                    │
         │   Picker)        │    │  [5|10|15|20|30]  │
         └──────────────────┘    │   minutes          │
                                 └──────────────────┘
                                        │
                   ┌────────────────────┘
                   ▼
         ┌──────────────────┐    ┌──────────────────┐
         │  Set Parent PIN  │───▶│  Setup Complete   │
         │  (4-digit)       │    │  "Childlock is    │
         └──────────────────┘    │   now active!"    │
                                 └──────────────────┘
                                        │
                                        ▼
                                 ┌──────────────────┐
                                 │  Parent Dashboard │
                                 │  (Home)           │
                                 └──────────────────┘
```

**Flow details:**
- **Welcome screen:** Single screen with illustration + value prop. No carousel — parents are busy.
- **Sign up:** "Continue with Apple" as primary. Email/password as secondary. Apple Sign In preferred because Family Sharing is already Apple-native.
- **Family Sharing auth:** System prompt from `AuthorizationCenter.requestAuthorization(for: .child)`. We show a pre-prompt explaining why: "Childlock uses Family Sharing to manage screen time on your child's device."
- **Child profile:** Name (text field), age (scrolling picker 3–12), avatar (horizontal scroll of 12 animals). One profile in onboarding; add more later.
- **App selection:** Uses Apple's `FamilyActivityPicker` — a system-provided UI. We frame it: "Choose apps where challenges should appear."
- **Interval:** Large segmented control or pill selector. Default: 15 minutes. Helper text: "Your child will see a challenge every [X] minutes while using selected apps."
- **PIN:** Standard 4-digit PIN entry with confirmation. Used to lock parent settings.

**Time to complete:** Target <3 minutes (excluding Family Sharing system prompt wait time).

### 3.2 Child Challenge Flow

```
┌─────────────────┐
│  Child using     │
│  monitored app   │◀──────────────────────────┐
│  (YouTube, etc.) │                            │
└────────┬────────┘                            │
         │ Timer expires                        │
         ▼                                      │
┌─────────────────┐                            │
│  Screen shields  │                            │
│  (app blocked)   │                            │
│                  │                            │
│  ┌─────────────┐ │                            │
│  │  Challenge   │ │                            │
│  │  appears     │ │                            │
│  │  (full       │ │                            │
│  │   screen)    │ │                            │
│  └──────┬──────┘ │                            │
│         │        │                            │
│         ▼        │                            │
│  ┌─────────────┐ │    ┌───────────┐          │
│  │  Kid solves  │─┼───▶│ Celebrate!│──────────┘
│  │  challenge   │ │    │ ⭐🎉      │  Timer resets
│  └──────┬──────┘ │    └───────────┘
│         │        │
│    Wrong answer   │
│         │        │
│         ▼        │
│  ┌─────────────┐ │
│  │ "Almost!    │ │
│  │  Try again!"│ │
│  │             │ │
│  │ (Hint after │ │
│  │  2 attempts)│ │
│  └─────────────┘ │
└─────────────────┘
```

**Challenge presentation sequence:**
1. Monitored app shields (blurs/blocks via `ManagedSettings`)
2. 400ms pause (let shield settle)
3. Challenge slides up from bottom of shield view
4. Voice prompt plays for ages 3–5 ("Count the stars!")
5. Kid interacts with challenge
6. On correct: celebration animation (2s) → shield removes → app resumes
7. On incorrect: gentle shake + "Almost! Try again!" (attempt counter increments)
8. After 2 failed attempts: hint appears (e.g., highlighting the correct answer area, showing a partial solution)
9. After hint: kid must still solve correctly (no free pass)
10. No skip button. No dismiss. No way out except solving.

**Edge case — kid backgrounds the app during challenge:**
Shield persists. Challenge state is preserved. When kid returns, challenge is still there.

**Edge case — kid force-quits the monitored app:**
Shield reactivates on next app launch. Challenge is re-presented (same challenge, not a new one).

### 3.3 Parent Dashboard Flow

```
┌──────────────────────────────────────────────────┐
│                 Parent Dashboard                  │
│                                                  │
│  ┌──────┐  ┌──────────┐  ┌──────┐  ┌─────────┐ │
│  │ Home │  │ Children │  │ Apps │  │Settings │ │
│  │  ●   │  │          │  │      │  │         │ │
│  └──────┘  └──────────┘  └──────┘  └─────────┘ │
│                                                  │
│  Tab: Home                                       │
│  ├── Today's Summary (all children)              │
│  ├── Quick Stats (challenges, accuracy)          │
│  └── Recent Activity feed                        │
│                                                  │
│  Tab: Children                                   │
│  ├── Child selector (horizontal scroll)          │
│  ├── Per-child stats (daily/weekly toggle)       │
│  ├── Challenge history list                      │
│  └── [+ Add Child] button                        │
│                                                  │
│  Tab: Apps                                       │
│  ├── Monitored apps list                         │
│  ├── Per-app interval override                   │
│  └── [+ Add Apps] → FamilyActivityPicker         │
│                                                  │
│  Tab: Settings                                   │
│  ├── Account & Subscription                      │
│  ├── Difficulty (Auto / Manual per child)        │
│  ├── Change PIN                                  │
│  ├── Notifications preferences                   │
│  └── Help & Support                              │
└──────────────────────────────────────────────────┘
```

---

## 4. Screen Designs

### 4.1 Parent: Welcome / Onboarding

```
┌─────────────────────────────────┐
│                                 │
│         (status bar)            │
│                                 │
│                                 │
│        🧠                       │
│     [Warm illustration:         │
│      Parent + child with        │
│      device, brain sparkles]    │
│                                 │
│                                 │
│    Turn screen time into        │
│       brain time.               │
│                                 │
│    Childlock adds quick brain   │
│    challenges during your       │
│    child's screen time.         │
│    No tantrums. Real learning.  │
│                                 │
│                                 │
│  ┌─────────────────────────┐    │
│  │   Continue with Apple   │    │
│  └─────────────────────────┘    │
│                                 │
│       Sign in with email →      │
│                                 │
│  By continuing, you agree to    │
│  our Terms and Privacy Policy.  │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Cream background (#FFF8F0)
- Illustration is warm, hand-drawn style — parent sitting with child on couch, child holding iPad, small sparkle/brain icons floating up
- "Continue with Apple" button: Sunrise Orange (#F2994A), rounded corners (14pt radius), full width minus margins
- Email sign-in is a text link, not a button (Apple Sign In is the happy path)

### 4.2 Parent: Child Profile Creation

```
┌─────────────────────────────────┐
│  ← Back           Step 2 of 5  │
│─────────────────────────────────│
│                                 │
│    Who's using the device?      │
│                                 │
│  Child's name                   │
│  ┌─────────────────────────┐    │
│  │  Mia                    │    │
│  └─────────────────────────┘    │
│                                 │
│  Age                            │
│  ┌─────────────────────────┐    │
│  │  ◀  ██ 6 years old ██  ▶  │  │
│  └─────────────────────────┘    │
│  Determines challenge difficulty│
│                                 │
│  Choose an avatar               │
│  ┌─────────────────────────┐    │
│  │ 🦊  🦉  🐻  🐰  🐱     │    │
│  │ 🐶  🐢  🐧  🐨  🦁     │    │
│  │ 🐘  🐼                  │    │
│  └─────────────────────────┘    │
│  (selected avatar has orange    │
│   ring highlight)               │
│                                 │
│  ┌─────────────────────────┐    │
│  │        Continue         │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Avatars are 72pt × 72pt circular illustrations (not emoji — custom warm illustrations)
- Selected avatar gets a 4pt Sunrise Orange border + subtle scale-up (1.1×)
- Age picker is a horizontal stepper with large tap zones (not a tiny number picker)
- Name stored locally only, never sent to server (COPPA, PRD Appendix B)

### 4.3 Parent: Home Dashboard

```
┌─────────────────────────────────┐
│  Childlock              ⚙️ PIN  │
│─────────────────────────────────│
│                                 │
│  Good afternoon, Xavier         │
│                                 │
│  ┌─────────────────────────┐    │
│  │  TODAY                  │    │
│  │                         │    │
│  │   12        8       75% │    │
│  │  challenges  solved  accuracy│
│  │  presented                   │
│  │                         │    │
│  │  ■■■■■■■■░░  1h 48m     │    │
│  │  total screen time      │    │
│  └─────────────────────────┘    │
│                                 │
│  Children                       │
│  ┌───────────┐ ┌───────────┐   │
│  │ 🦊 Mia    │ │ 🐻 Leo    │   │
│  │ Age 6     │ │ Age 9     │   │
│  │           │ │           │   │
│  │ 7 ✅ / 8  │ │ 5 ✅ / 4  │   │
│  │ challenges│ │ challenges│   │
│  │           │ │           │   │
│  │ 🟢 Active │ │ ⚪ Idle   │   │
│  └───────────┘ └───────────┘   │
│                                 │
│  Recent Activity                │
│  ┌─────────────────────────┐    │
│  │  🦊 Mia solved a math  │    │
│  │  challenge (2:34 PM)    │    │
│  │  3 + 7 = ? → ✅ 12s     │    │
│  ├─────────────────────────┤    │
│  │  🐻 Leo solved a       │    │
│  │  pattern challenge      │    │
│  │  (2:21 PM) → ✅ 28s     │    │
│  ├─────────────────────────┤    │
│  │  🦊 Mia needed a hint  │    │
│  │  on memory (2:15 PM)   │    │
│  │  → ✅ after 3 attempts  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌──────┐┌──────────┐┌──────┐┌─────────┐
│  │ Home ││ Children ││ Apps ││Settings │
│  │  ●   ││          ││      ││         │
│  └──────┘└──────────┘└──────┘└─────────┘
└─────────────────────────────────┘
```

**Design notes:**
- Top card: Cream card on warm white background, numbers in SF Pro Rounded 34pt Bold
- Screen time bar: Gradient fill (orange to gold), rounded ends
- Child cards: Rounded rectangles with subtle shadow (4pt blur, 10% opacity). Tap → navigates to per-child detail view.
- Active/Idle badge: Green dot = child is currently using a monitored app. Gray = not active.
- Activity feed: Chronological, most recent first. Each entry shows avatar, challenge type, time, result, solve duration.
- Settings gear icon requires PIN entry before navigating (PRD §4.3)

### 4.4 Parent: Per-Child Detail View

```
┌─────────────────────────────────┐
│  ← Children       🦊 Mia (6)   │
│─────────────────────────────────│
│                                 │
│  ┌──────────┬──────────┐        │
│  │  Today   │  This Week│       │
│  └──────────┴──────────┘        │
│                                 │
│  Screen Time     Challenges     │
│    1h 12m           7/8         │
│    ▼ 15m vs avg     88% acc     │
│                                 │
│  ┌─────────────────────────┐    │
│  │  Challenge Breakdown    │    │
│  │                         │    │
│  │  Math      ████████ 4   │    │
│  │  Pattern   ████     2   │    │
│  │  Memory    ██       1   │    │
│  │  Puzzle    ██       1   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  Avg Solve Time         │    │
│  │                         │    │
│  │  Math:    12s  ●        │    │
│  │  Pattern: 24s    ●      │    │
│  │  Memory:  31s      ●    │    │
│  │  Puzzle:  18s   ●       │    │
│  └─────────────────────────┘    │
│                                 │
│  Challenge History              │
│  ┌─────────────────────────┐    │
│  │  2:34 PM  Math          │    │
│  │  3 + 7 = 10  ✅ 12s     │    │
│  ├─────────────────────────┤    │
│  │  2:15 PM  Memory        │    │
│  │  Match 6 pairs          │    │
│  │  ✅ 3 attempts, 45s     │    │
│  │  (hint used)            │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │    Edit Profile         │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Day/Week toggle: Segmented control, Sunrise Orange for selected state
- Horizontal bar chart for challenge breakdown uses challenge-type colors
- Solve time uses a dot plot for quick scanning
- History entries show the actual challenge content so parents can see what their kids are solving
- "Edit Profile" opens name/age/avatar editor + interval/difficulty overrides for this child

### 4.5 Parent: App Management

```
┌─────────────────────────────────┐
│  Apps                           │
│─────────────────────────────────│
│                                 │
│  Monitored Apps                 │
│  Challenges appear during these │
│                                 │
│  ┌─────────────────────────┐    │
│  │  📺 Video Streaming     │    │
│  │  Every 15 min     ✏️    │    │
│  ├─────────────────────────┤    │
│  │  🎮 Games              │    │
│  │  Every 10 min     ✏️    │    │
│  ├─────────────────────────┤    │
│  │  📱 Social Media       │    │
│  │  Every 10 min     ✏️    │    │
│  └─────────────────────────┘    │
│                                 │
│  Note: App names are shown as   │
│  categories (Apple privacy —    │
│  FamilyControls uses opaque     │
│  tokens, PRD §5.2)              │
│                                 │
│  ┌─────────────────────────┐    │
│  │   + Add Apps to Monitor │    │
│  └─────────────────────────┘    │
│  (opens FamilyActivityPicker)   │
│                                 │
│  ─────────────────────────────  │
│                                 │
│  Always Allowed                 │
│  These apps never trigger       │
│  challenges                     │
│                                 │
│  Educational apps, Phone,       │
│  Messages are never blocked.    │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Edit (pencil icon) opens interval picker for that specific app category
- "Add Apps" triggers Apple's native `FamilyActivityPicker` — we cannot customize its appearance but we can frame it with our own header text
- "Always Allowed" section is informational — these are system defaults that Childlock does not interfere with

### 4.6 Child: Challenge Screen — Math (Ages 6–8)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │                         │    │
│  │       24 + 13 = ?       │    │
│  │                         │    │
│  │  (SF Rounded, 48pt,     │    │
│  │   Charcoal on Cream)    │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │       │  │       │          │
│  │  35   │  │  37   │          │
│  │       │  │       │          │
│  └───────┘  └───────┘          │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │       │  │       │          │
│  │  47   │  │  36   │          │
│  │       │  │       │          │
│  └───────┘  └───────┘          │
│                                 │
│                                 │
│  ┌─────────────────────────┐    │
│  │  ○ ○ ○ ○ ○ ○ ○ ○ ● ○   │    │
│  │  (gentle progress dots  │    │
│  │   — not a countdown)    │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Full screen overlay — no way to dismiss, no close button, no swipe-to-dismiss
- "Brain Break!" header in Sunrise Orange on cream pill — friendly, not alarming
- Math expression in 48pt SF Rounded Heavy, centered, high contrast
- Answer buttons: 80pt × 80pt minimum, generous spacing (16pt gap), rounded corners (16pt radius)
- Buttons have soft shadow + warm white fill. On tap: scale down 0.95 + fill with challenge-type color
- Correct answer: button pulses green (#6FCF97), confetti burst from center
- Wrong answer: button shakes briefly, flashes Coral Warm, reverts. "Almost!" text appears below.
- Progress dots at bottom are informational (not stressful) — they show time passage gently, not a ticking countdown
- No visible timer counting down. Progress dots fill slowly as an ambient indicator only.

### 4.7 Child: Challenge Screen — Math (Ages 3–5)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│       Count the stars!          │
│     (voice prompt plays too)    │
│                                 │
│                                 │
│       ⭐  ⭐  ⭐               │
│          ⭐  ⭐                 │
│                                 │
│     (5 stars scattered in       │
│      a friendly cluster)        │
│                                 │
│                                 │
│  ┌─────────┐ ┌─────────┐       │
│  │         │ │         │       │
│  │    4    │ │    5    │       │
│  │         │ │         │       │
│  └─────────┘ └─────────┘       │
│                                 │
│         ┌─────────┐             │
│         │         │             │
│         │    6    │             │
│         │         │             │
│         └─────────┘             │
│                                 │
│  ○ ○ ○ ○ ○ ○ ● ○ ○ ○           │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Larger text (32pt instruction), fewer answer options (3 instead of 4)
- Objects to count are colorful, distinct, and large (40pt each)
- Voice prompt auto-plays: "Count the stars!" in a warm, encouraging voice
- Answer buttons are even larger for small hands: 96pt × 96pt, arranged in inverted triangle (2 top, 1 bottom) for easy reach
- Stars/objects gently bob or pulse with a subtle animation to draw attention

### 4.8 Child: Challenge Screen — Pattern (Ages 9–12)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│     What comes next?            │
│                                 │
│  ┌──────────────────────────┐   │
│  │                          │   │
│  │   2   6   12   20   ?   │   │
│  │                          │   │
│  └──────────────────────────┘   │
│                                 │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │  28   │  │  30   │          │
│  └───────┘  └───────┘          │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │  24   │  │  32   │          │
│  └───────┘  └───────┘          │
│                                 │
│                                 │
│  ○ ○ ○ ○ ○ ○ ○ ○ ● ○           │
│                                 │
└─────────────────────────────────┘
```

### 4.9 Child: Challenge Screen — Memory (Ages 6–8)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│     Find the matching pairs!    │
│                                 │
│     Pairs found: 2 / 6         │
│                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │      │ │  🌙  │ │      │   │
│  │  ❓  │ │      │ │  ❓  │   │
│  │      │ │(face │ │      │   │
│  └──────┘ │ up)  │ └──────┘   │
│            └──────┘            │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │      │ │      │ │  🌟  │   │
│  │  ❓  │ │  ❓  │ │      │   │
│  │      │ │      │ │(face │   │
│  └──────┘ └──────┘ │ up)  │   │
│                     └──────┘   │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │  🌙  │ │      │ │      │   │
│  │      │ │  ❓  │ │  ❓  │   │
│  │(matc │ │      │ │      │   │
│  │ hed) │ └──────┘ └──────┘   │
│  └──────┘                      │
│                                 │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │  🌟  │ │      │ │      │   │
│  │(matc │ │  ❓  │ │  ❓  │   │
│  │ hed) │ │      │ │      │   │
│  └──────┘ └──────┘ └──────┘   │
│                                 │
│  ○ ○ ○ ○ ○ ○ ● ○ ○ ○           │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- 4×3 grid for 6 pairs (ages 6–8). 2×3 grid for 3 pairs (ages 3–5). 4×4+ for 9+ pairs (ages 9–12).
- Cards: 72pt × 72pt each, rounded corners, warm white face-down with subtle "?" icon
- Flip animation: 3D rotation on Y-axis, 300ms, reveals icon underneath
- Matched pairs stay face-up with a soft glow border
- Mismatched pairs flip back after 1 second (enough time for kids to register)
- Icons are simple, recognizable: sun, moon, star, apple, tree, fish, heart, flower, bird, rainbow, cloud, house

### 4.10 Child: Challenge Screen — Puzzle / Drag (Ages 3–5)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│     Put the shape in            │
│     the right spot!             │
│     (voice prompt plays)        │
│                                 │
│  ┌─────────────────────────┐    │
│  │                         │    │
│  │   ╭───╮   ┌───┐   △    │    │
│  │   │   │   │   │   │\   │    │
│  │   ╰───╯   └───┘   ▽    │    │
│  │  (circle) (square)(tri) │    │
│  │                         │    │
│  │   [dashed outline of    │    │
│  │    circle = drop zone]  │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  ╭─────╮                        │
│  │     │   ← Draggable piece    │
│  │  ●  │     (circle, vibrant   │
│  │     │      orange fill)      │
│  ╰─────╯                        │
│                                 │
│  (drag the circle to its        │
│   matching outline above)       │
│                                 │
│  ○ ○ ○ ○ ○ ● ○ ○ ○ ○           │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Drag-and-drop: piece follows finger with slight offset (so finger doesn't cover it)
- Drop zone has a dashed outline that glows brighter as the piece gets close (magnetic snap feedback)
- Snap-to-fit at 20pt proximity — forgiving for small, imprecise hands
- Haptic feedback (light impact) on snap
- Shapes are filled with challenge-type colors, outlines are darker tint of same color

### 4.11 Child: Success / Celebration

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│           ✨  🎉  ✨            │
│                                 │
│        ⭐ Awesome! ⭐           │
│                                 │
│     (confetti particles         │
│      raining down, warm         │
│      colors: orange, gold,      │
│      coral, green)              │
│                                 │
│       [Avatar character         │
│        doing a little           │
│        celebration dance]       │
│                                 │
│                                 │
│      You solved it in 12s!      │
│                                 │
│                                 │
│      (auto-dismisses after      │
│       2 seconds, screen         │
│       unlocks, app resumes)     │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Full-screen celebration overlay, cream background
- Confetti particle system: 50-80 particles, warm palette colors, gravity-affected fall
- Avatar character (the one the kid selected) does a 2-frame bounce/dance
- Praise text rotates through: "Awesome!", "Great job!", "You did it!", "Super brain!", "Nailed it!"
- Solve time shown in small text (not emphasized — it's info, not pressure)
- Auto-dismisses after 2 seconds. No tap required. Smooth fade-out → app resumes.
- Sound effect: Short, cheerful chime (respects device silent mode)

### 4.12 Child: Hint State (After 2 Failed Attempts)

```
┌─────────────────────────────────┐
│                                 │
│  ┌─────────────────────────┐    │
│  │    🧠 Brain Break!      │    │
│  └─────────────────────────┘    │
│                                 │
│       24 + 13 = ?               │
│                                 │
│  ┌─────────────────────────┐    │
│  │  💡 Hint: Try counting  │    │
│  │  up from 24. What's     │    │
│  │  24 + 10? Then add 3.   │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │  35   │  │  37   │          │
│  │       │  │ ✨glow │          │
│  └───────┘  └───────┘          │
│                                 │
│  ┌───────┐  ┌───────┐          │
│  │  47   │  │  36   │          │
│  └───────┘  └───────┘          │
│                                 │
│                                 │
│  ○ ○ ○ ○ ○ ○ ○ ○ ● ○           │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Hint appears in a warm gold (#F2C94C) rounded box with lightbulb icon
- For math: step-by-step breakdown hint text
- For pattern: highlight the pattern rule ("Each number increases by 2 more")
- For memory: briefly flash all cards face-up for 1 second, then flip back
- For puzzle: correct drop zone pulses with a glow
- Correct answer button may get a subtle sparkle/glow (varies by challenge type — must still require kid to tap it)

### 4.13 Parent: Settings

```
┌─────────────────────────────────┐
│  ← Settings                    │
│─────────────────────────────────│
│                                 │
│  ACCOUNT                        │
│  ┌─────────────────────────┐    │
│  │  xavier@email.com       │    │
│  │  Premium Annual      ▶  │    │
│  └─────────────────────────┘    │
│                                 │
│  CHALLENGE SETTINGS             │
│  ┌─────────────────────────┐    │
│  │  Default Interval       │    │
│  │  Every 15 minutes    ▶  │    │
│  ├─────────────────────────┤    │
│  │  Difficulty Mode        │    │
│  │  Auto (age-based)    ▶  │    │
│  ├─────────────────────────┤    │
│  │  Voice Prompts (3-5)   │    │
│  │  On                  🔘│    │
│  └─────────────────────────┘    │
│                                 │
│  SECURITY                       │
│  ┌─────────────────────────┐    │
│  │  Change PIN          ▶  │    │
│  └─────────────────────────┘    │
│                                 │
│  NOTIFICATIONS                  │
│  ┌─────────────────────────┐    │
│  │  Daily Summary          │    │
│  │                      🔘│    │
│  ├─────────────────────────┤    │
│  │  Challenge Alerts       │    │
│  │  (hint used, struggles) │    │
│  │                      🔘│    │
│  └─────────────────────────┘    │
│                                 │
│  SUPPORT                        │
│  ┌─────────────────────────┐    │
│  │  Help & FAQ          ▶  │    │
│  │  Contact Support     ▶  │    │
│  │  Privacy Policy      ▶  │    │
│  └─────────────────────────┘    │
│                                 │
└─────────────────────────────────┘
```

### 4.14 Paywall Screen

```
┌─────────────────────────────────┐
│                          ╳      │
│                                 │
│    Unlock unlimited             │
│    brain breaks                 │
│                                 │
│  ┌─────────────────────────┐    │
│  │  FREE         PREMIUM   │    │
│  │  3/day        Unlimited │    │
│  │  1 child      5 children│    │
│  │  Basic stats  Full reports│   │
│  │  2 types      All types │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  Annual — Best Value    │    │
│  │  $39.99/year            │    │
│  │  ($3.33/mo — save 33%)  │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │  Monthly                │    │
│  │  $4.99/month            │    │
│  └─────────────────────────┘    │
│                                 │
│  Start 7-day free trial         │
│                                 │
│  Restore purchases              │
│  Terms · Privacy                │
│                                 │
└─────────────────────────────────┘
```

**Design notes:**
- Annual plan is visually emphasized: Sunrise Orange border, "Best Value" badge
- Monthly plan is a secondary style: outlined, no fill
- Both plans lead to the same 7-day free trial
- Close button (╳) in top right — paywall is never forced; user can always dismiss
- Managed by RevenueCat (PRD §5.1). A/B testing on placement and copy handled by RevenueCat's paywall system.
- Appears: (1) when free user hits 3-challenge daily limit, (2) when trying to add a 2nd child profile, (3) from "Upgrade" button in settings

---

## 5. Challenge UI Components — Detailed Specifications

### 5.1 Component Library

| Component | Min Size | Touch Target | Used In |
|-----------|----------|-------------|---------|
| Answer Button (3-5) | 96 × 96 pt | 96 × 96 pt | Math, Pattern (young) |
| Answer Button (6-12) | 80 × 80 pt | 80 × 80 pt | Math, Pattern (older) |
| Memory Card | 72 × 72 pt | 72 × 72 pt | Memory game |
| Draggable Piece | 64 × 64 pt | 80 × 80 pt (expanded hit area) | Puzzle/drag |
| Drop Zone | 80 × 80 pt | 100 × 100 pt (magnetic snap) | Puzzle/drag |
| Progress Dots | 8 pt diameter | N/A (non-interactive) | All challenges |
| Hint Box | Full width - 48pt | N/A (informational) | All challenges |
| Header Pill ("Brain Break!") | Auto-width + 24pt padding | N/A (non-interactive) | All challenges |

### 5.2 Math Challenge Display Rules

| Age Band | Number Range | Operations | Answer Count | Display |
|----------|-------------|------------|-------------|---------|
| 3–5 | 1–10 | Count objects | 3 options | Objects + number buttons |
| 6–8 | 1–100 | +, − | 4 options | Equation + number buttons |
| 9–12 | 1–1000 | +, −, ×, ÷, order of ops | 4 options | Equation + number buttons |

**Procedural generation rules:**
- Wrong answers are always plausible (within ±20% of correct answer, no negatives, no zero for multiplication)
- Answer positions randomized each time
- No duplicate answer values
- Equations never produce negative results for ages 3–8

### 5.3 Pattern Challenge Display Rules

| Age Band | Pattern Type | Length | Display |
|----------|-------------|--------|---------|
| 3–5 | Shape sequence (circle, square, triangle) | 4 items + blank | Visual shapes |
| 6–8 | Number patterns (+2, +3, ×2) | 5 items + blank | Numbers in boxes |
| 9–12 | Complex sequences (quadratic, alternating ops) | 5–6 items + blank | Numbers in boxes |

### 5.4 Memory Game Specifications

| Age Band | Grid | Pairs | Card Flip Time | Preview Time |
|----------|------|-------|----------------|-------------|
| 3–5 | 2×3 | 3 pairs | 1.5 seconds | 3 seconds |
| 6–8 | 3×4 | 6 pairs | 1.0 seconds | 2 seconds |
| 9–12 | 4×4 or 4×5 | 8–10 pairs | 0.8 seconds | 1.5 seconds |

- Preview: all cards briefly show face-up at start, then flip to face-down
- Matched pairs stay face-up with a soft green glow border
- Card icons: distinct, high-contrast, recognizable symbols

### 5.5 Puzzle Challenge Specifications

| Age Band | Type | Pieces | Interaction |
|----------|------|--------|-------------|
| 3–5 | Shape-in-hole | 1 piece, 3 holes | Drag to correct outline |
| 6–8 | Simple jigsaw / tangram | 4–9 pieces | Drag + snap |
| 9–12 | Sliding puzzle / logic grid | 9–16 tiles | Tap to slide |

---

## 6. Onboarding Flow — Detailed

### 6.1 Step-by-Step Screens

**Screen 1: Welcome**
- Hero illustration + single-sentence value prop
- "Continue with Apple" CTA
- Takes 5 seconds

**Screen 2: Family Sharing Pre-Prompt**
- "Childlock needs Family Sharing to manage screen time on your child's device."
- "This uses Apple's built-in parental controls — safe, private, and secure."
- Three-bullet explainer: what it does, what it doesn't do, what data is accessed
- "Set Up" button → triggers `AuthorizationCenter.requestAuthorization(for: .child)`
- If Family Sharing is not configured: link to Apple's Family Sharing setup guide, with in-app instruction screenshots

**Screen 3: Create Child Profile**
- Name, age, avatar (as wireframed in §4.2)
- "You can add more children later"
- Takes 30 seconds

**Screen 4: Select Apps**
- Brief explanation: "Choose the apps where brain breaks should appear"
- "Tip: Skip educational apps — those are already good for your child"
- "Select Apps" button → opens `FamilyActivityPicker`
- Takes 15 seconds

**Screen 5: Set Interval**
- Large pill selector: 5 / 10 / 15 / 20 / 30 minutes
- "Recommended: 15 minutes" label on the 15-min option
- Helper text: "A brain break will appear every [X] minutes during selected apps"
- Takes 5 seconds

**Screen 6: Set PIN**
- "Set a 4-digit PIN to protect your settings"
- Standard PIN entry + confirm
- Takes 10 seconds

**Screen 7: All Done!**
- Celebration animation (scaled down — not as big as child celebration)
- "Childlock is now active on [Child Name]'s device"
- "Your child will see their first brain break in [X] minutes"
- "Go to Dashboard" CTA
- Takes 5 seconds (reading)

**Total onboarding time: ~90 seconds** (excluding Family Sharing system prompt)

### 6.2 Demo Mode (No Family Sharing)

For parents who want to try before committing to Family Sharing setup:
- Skip Screen 2 (Family Sharing)
- Challenge preview: parent sees sample challenges on their own device
- "Try a challenge!" — runs through one math, one memory, one pattern challenge
- After demo: "Ready to set up for your child?" → returns to Family Sharing screen
- No actual monitoring or shielding in demo mode

### 6.3 Family Sharing Troubleshooting

If Family Sharing authorization fails:
- **Not set up:** "Family Sharing needs to be set up first" + step-by-step screenshots showing Settings → Apple ID → Family Sharing → Add Child
- **Child not in family group:** "Add [Child Name] to your Family Sharing group" + instructions
- **Authorization denied:** "You can authorize Childlock later in Settings → Screen Time" + deep link

---

## 7. Edge Cases & Error States

### 7.1 No Internet Connection

| Scenario | Behavior |
|----------|----------|
| Challenge engine | Works fully offline — all challenges are generated locally (PRD §5.4) |
| Timer & shielding | Works fully offline — uses on-device Screen Time APIs |
| Parent dashboard | Shows cached data with "Last updated: [timestamp]" banner |
| Subscription check | Cached validation with 7-day grace period (PRD Appendix C.4) |
| Data sync | Queues usage data locally, syncs when connection returns |

**Offline banner (parent dashboard):**
```
┌─────────────────────────────────┐
│  ⚠️ You're offline. Dashboard  │
│  data may not be current.       │
└─────────────────────────────────┘
```
Warm gold background, not red/alarming.

### 7.2 Challenge Failure / Struggle

| Scenario | Response |
|----------|----------|
| 1st wrong answer | Gentle shake animation + "Almost! Try again!" |
| 2nd wrong answer | Hint appears (type-specific, see §4.12) |
| 3rd+ wrong answer (with hint) | Hint stays visible, encourage: "You're close! Take your time." |
| Kid never solves | No timeout. Challenge stays until solved. Parent can resolve by opening the Childlock parent app and manually dismissing (requires PIN). |
| Kid solves after many attempts | Still gets celebration! "You did it! That was a tough one!" (never diminished praise) |

### 7.3 Child Rage-Quits / Avoidance

| Scenario | Behavior |
|----------|----------|
| Force-quits monitored app | Shield reactivates on next app launch. Same challenge re-presented. |
| Switches to non-monitored app | Allowed — challenge only blocks monitored apps. Timer pauses. |
| Restarts device | `ManagedSettings` store persists across reboots. Shield reactivates. |
| Tries to delete Childlock companion app | Shield is managed by extensions, not the app itself. Deleting the companion app does not remove shields. |
| Hands device to parent | Parent enters PIN in Childlock to temporarily pause monitoring. |

### 7.4 Multiple Children Edge Cases

| Scenario | Behavior |
|----------|----------|
| Shared iPad (2 kids, 1 device) | Each child profile maps to a Family Sharing child account. Device user determines active profile. |
| Different intervals per child | Stored per-profile. Applied when that child's account is active on device. |
| Age straddles band boundaries | Use the age entered. Parent can override difficulty manually. |

### 7.5 Subscription Edge Cases

| Scenario | Behavior |
|----------|----------|
| Free user hits 3 challenges/day | 4th challenge still appears but shows paywall after completion instead of unlocking. |
| Premium expires | Graceful downgrade: reverts to free tier behavior (3/day, 1 child). No data loss. |
| Free trial ends mid-day | Remaining challenges for the day still work. Free tier kicks in next day. |
| Subscription in grace period | Full premium access. No user-facing indication of billing issue. |

---

## 8. Accessibility

### 8.1 VoiceOver Support

| Screen | VoiceOver Behavior |
|--------|-------------------|
| Challenge header | "Brain Break. [Challenge type] challenge." |
| Math question | Reads equation aloud: "Twenty-four plus thirteen equals what?" |
| Answer buttons | "Option 1: thirty-five. Option 2: thirty-seven. Option 3: forty-seven. Option 4: thirty-six." |
| Memory cards | "Row 1, column 1: face down. Row 1, column 2: moon, face up." |
| Success | "Correct! Great job! Screen unlocking." |
| Failure | "Not quite. Try again. Attempt 2." |
| Hint | "Hint: [hint text]" |
| Parent dashboard | Standard iOS VoiceOver semantics for all controls |

**MVP scope:** Voice prompts for ages 3–5 (built-in audio). Full VoiceOver for all ages is v2 (PRD Appendix C.3) but basic VoiceOver labels should be added to all interactive elements in v1.

### 8.2 Color Blind Safety

- Challenge types use color + shape (circle/triangle/square/star) as redundant identifiers
- Correct (green) and incorrect (red) answers also use checkmark/X icons
- All text passes WCAG AA contrast ratio (4.5:1 minimum for normal text, 3:1 for large text)
- Tested against: protanopia, deuteranopia, tritanopia simulations

### 8.3 Motor Accessibility

- All touch targets ≥60pt for child UI (above Apple's 44pt minimum)
- Drag-and-drop has generous snap zones (20pt magnetic radius)
- No timed interactions — challenges wait forever for input
- No precision gestures required (no pinch, no long-press, no multi-finger)
- Switch Control compatible: all challenges can be navigated sequentially

### 8.4 Cognitive Accessibility

- One task per screen — no secondary actions or distractions
- Consistent layout across all challenge types (header, content, answers, progress)
- Clear visual hierarchy — question always centered, answers always below
- No reading required for ages 3–5 (voice + visual only)
- Consistent positive reinforcement regardless of attempt count

---

## 9. Parent Dashboard — Data Visualization

### 9.1 Daily Summary Card

```
┌─────────────────────────────────────────┐
│  TODAY                     Thu, Mar 13  │
│                                         │
│     12          8          75%          │
│  presented    solved    accuracy        │
│                                         │
│  ██████████████████░░░░░  1h 48m       │
│  screen time (of 3h limit)              │
│                                         │
│  ↑2 vs yesterday                        │
└─────────────────────────────────────────┘
```

- Hero numbers: 34pt SF Pro Rounded Bold, Charcoal
- Labels: 13pt SF Pro Text, Warm Gray
- Bar: rounded, gradient fill (Sunrise Orange → Honey Gold)
- Comparison text: small, green if improved, warm gray if neutral (never red — not punitive)

### 9.2 Weekly View

```
┌─────────────────────────────────────────┐
│  THIS WEEK                              │
│                                         │
│  Mon  Tue  Wed  Thu  Fri  Sat  Sun     │
│   ██   ██   ██   ██                     │
│   ██   ██   ██   ██                     │
│   ██   ██   ██   ██                     │
│   ██   ██   ██                          │
│   ██   ██                               │
│                                         │
│  Bar chart: challenges completed/day    │
│  Color: challenge-type breakdown        │
│  (stacked: orange=math, blue=pattern,   │
│   purple=memory, green=puzzle)          │
│                                         │
│  Weekly avg accuracy: 82%               │
│  Total challenges: 34                   │
│  Avg solve time: 18s                    │
└─────────────────────────────────────────┘
```

- Stacked bar chart using challenge-type colors
- Tap a day → expands to show that day's challenge breakdown
- Weekly summary stats below chart

---

## 10. Navigation Architecture

### 10.1 Information Architecture

```
Parent App
├── Onboarding (first launch only)
│   ├── Welcome
│   ├── Family Sharing Auth
│   ├── Create Child Profile
│   ├── Select Apps
│   ├── Set Interval
│   ├── Set PIN
│   └── Complete
│
├── Tab: Home
│   ├── Today Summary
│   ├── Children Overview Cards
│   └── Recent Activity Feed
│
├── Tab: Children
│   ├── Child Selector
│   ├── Per-Child Detail
│   │   ├── Daily / Weekly Toggle
│   │   ├── Stats Overview
│   │   ├── Challenge Breakdown Chart
│   │   ├── Solve Time Chart
│   │   └── Challenge History List
│   └── [+ Add Child]
│       └── Profile Creator
│
├── Tab: Apps
│   ├── Monitored Apps List
│   │   └── Per-App Interval Editor
│   ├── [+ Add Apps] → FamilyActivityPicker
│   └── Always Allowed Info
│
└── Tab: Settings (PIN-protected)
    ├── Account & Subscription
    │   └── Paywall (if free)
    ├── Challenge Settings
    │   ├── Default Interval
    │   ├── Difficulty Mode
    │   └── Voice Prompts Toggle
    ├── Change PIN
    ├── Notifications
    ├── Help & FAQ
    ├── Contact Support
    └── Privacy Policy

Child Device (Shield Extensions)
├── Shield (blocked app overlay)
│   └── Challenge View
│       ├── Math Challenge
│       ├── Pattern Challenge
│       ├── Memory Challenge
│       └── Puzzle Challenge
│           ├── Success → Celebration → Unlock
│           └── Failure → Hint → Retry
│
└── Companion App (optional, v1 minimal)
    ├── Avatar Display
    └── Challenge Practice (voluntary)
```

### 10.2 Navigation Patterns

- **Parent app:** Standard iOS tab bar (4 tabs). Navigation is push-based within each tab.
- **Settings:** Requires PIN entry before any navigation within the tab. PIN is cached for the session (until app backgrounds for >5 minutes).
- **Child challenge:** No navigation. Single full-screen view. Challenge → celebration → dismiss. No back button, no menu, no escape.
- **Onboarding:** Linear, sequential. Back button available (except Family Sharing — that's a system prompt, no back). Progress indicator ("Step 2 of 5") in navigation bar.

---

## 11. Platform Requirements

| Requirement | Specification |
|------------|--------------|
| iOS minimum | iOS 16.0 (DeviceActivityMonitor requirement, PRD §5.2) |
| Devices | iPhone and iPad (Universal) |
| Orientations | Portrait only (parent app). Portrait + Landscape (child challenges on iPad) |
| Dark mode | Parent app: supported. Child challenges: always light/cream. |
| Dynamic Type | Full support, both parent and child UIs |
| iPad multitasking | Supported (slide over, split view) for parent app. Challenge overlay is always full-screen. |
| App size | Target <30MB (no large assets; challenges are procedurally generated) |

---

## 12. Design Deliverables Checklist

| Deliverable | Status | Notes |
|------------|--------|-------|
| Color palette & tokens | Defined in §2.1 | Export as Swift Color assets |
| Typography scale | Defined in §2.2 | SF Rounded + SF Pro, system fonts |
| Icon set (challenge types) | Spec'd in §2.3 | 4 type icons + avatar set |
| Onboarding screens (7) | Wireframed in §4.1–4.2, §6.1 | |
| Parent dashboard (4 tabs) | Wireframed in §4.3–4.5, §4.13 | |
| Challenge screens (4 types × 3 age bands) | Wireframed in §4.6–4.10 | |
| Celebration animation | Spec'd in §4.11, §2.4 | Lottie or SpriteKit |
| Hint/error states | Wireframed in §4.12 | |
| Paywall | Wireframed in §4.14 | RevenueCat-managed |
| Avatar illustrations (12) | Spec'd in §2.3 | Custom warm-style animals |
| App icon | Not yet designed | Should be warm, recognizable, brain/shield motif |
| App Store screenshots (6) | Not yet designed | Show parent + child UX |

---

## Appendix A: Design Tokens (Swift Implementation Reference)

```swift
// Colors
enum ChildlockColor {
    static let sunriseOrange = Color(hex: "F2994A")
    static let coralWarm = Color(hex: "EB5757")
    static let honeyGold = Color(hex: "F2C94C")
    static let leafGreen = Color(hex: "6FCF97")
    static let skyCalm = Color(hex: "56CCF2")
    static let lavenderSoft = Color(hex: "BB6BD9")

    static let cream = Color(hex: "FFF8F0")
    static let warmWhite = Color(hex: "FEFCF9")
    static let sand = Color(hex: "E8DDD3")
    static let warmGray = Color(hex: "828282")
    static let charcoal = Color(hex: "333333")
    static let deepBrown = Color(hex: "1A1A1A")
}

// Typography
enum ChildlockFont {
    static func childTitle() -> Font { .system(.title, design: .rounded, weight: .bold) }
    static func childNumber() -> Font { .system(size: 48, weight: .heavy, design: .rounded) }
    static func childBody() -> Font { .system(size: 24, weight: .medium, design: .rounded) }
    static func parentHeader() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func parentBody() -> Font { .system(size: 17, weight: .regular) }
    static func parentStat() -> Font { .system(size: 34, weight: .bold, design: .rounded) }
    static func parentCaption() -> Font { .system(size: 13, weight: .regular) }
}

// Spacing
enum ChildlockSpacing {
    static let childMargin: CGFloat = 24
    static let childGutter: CGFloat = 16
    static let parentMargin: CGFloat = 20
    static let parentGutter: CGFloat = 12
    static let childTouchTarget: CGFloat = 60
    static let youngChildTouchTarget: CGFloat = 96
    static let parentTouchTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 14
}

// Animation
enum ChildlockAnimation {
    static let challengeAppear: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    static let buttonTap: Animation = .spring(response: 0.2, dampingFraction: 0.7)
    static let wrongAnswer: Animation = .default
    static let celebration: TimeInterval = 2.0
    static let cardFlip: TimeInterval = 0.3
}
```

## Appendix B: Challenge Content Guidelines

### Tone of Voice (Child-Facing)

| Situation | Say | Never Say |
|-----------|-----|-----------|
| Challenge appears | "Brain Break!" | "Test time" / "Quiz" |
| Instructions | "Count the stars!" | "Answer the question" |
| Wrong answer | "Almost! Try again!" | "Wrong" / "Incorrect" |
| Hint | "Here's a hint!" | "You need help" |
| Success | "Awesome!" / "You did it!" | "Finally" / "That took a while" |
| Multiple failures | "You're getting closer!" | "Are you sure?" |

### Tone of Voice (Parent-Facing)

| Context | Tone | Example |
|---------|------|---------|
| Dashboard stats | Factual, clean | "12 challenges completed today" |
| Empty states | Encouraging | "Challenges will appear here once [Child] starts using monitored apps" |
| Errors | Helpful, not alarming | "We couldn't sync data. We'll try again soon." |
| Upgrade prompts | Value-first, not pushy | "Unlock unlimited brain breaks for all your children" |

---

*This design specification should be read alongside `prd.md` v1.0. All section references (PRD §X.X) refer to that document.*
