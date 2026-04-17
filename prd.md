# Childlock — Product Requirements Document

**Version:** 1.0
**Date:** 2026-03-13
**Author:** Kato (AI Chief of Staff)
**Status:** Draft — pending Xavier review
**Project slug:** childlock

---

## 1. Problem Statement

### The Parent Pain Point

Parents face an impossible tension: screens are unavoidable (education, entertainment, travel sanity), but passive consumption — endless YouTube, TikTok, mindless gaming — erodes attention spans, delays development, and creates withdrawal tantrums when limits hit.

Current solutions fail parents in one of two ways:

1. **Screen time limiters** (Apple Screen Time, Google Family Link, Bark) — blunt instruments. They cut off access entirely, causing meltdowns and offering no developmental upside. Kids learn nothing; they just lose access.
2. **Educational apps** (Khan Academy Kids, ABCmouse) — require parents to substitute entertainment apps entirely. Kids resist. Parents cave. The apps go unused.

Neither approach addresses the real problem: **kids consume passively for hours with zero cognitive engagement.**

### The Child Development Concern

The American Academy of Pediatrics recommends limited screen time, but the nuance matters — it's not screens that damage development, it's *passive* consumption. A child who watches 2 hours of YouTube without any active thought exercises different neural pathways than one who periodically stops to solve a problem.

Research shows that **interleaved cognitive challenges** during passive activities:
- Improve working memory and attention switching
- Reduce the "zombie state" of passive consumption
- Build positive associations between effort and reward
- Create natural break points that reduce screen addiction patterns

### The Gap

No product exists that **transforms passive screen time into active learning moments** without replacing the entertainment entirely. Parents don't need another educational app. They need a system that makes their kids *think* during the screen time that's already happening.

---

## 2. Solution Overview

**Childlock** is an iOS app that interrupts children's passive screen time with age-appropriate mental challenges at parent-configured intervals. It does not replace screen time — it punctuates it with cognitive micro-workouts.

### Core Loop

```
Kid watches/plays (10 min) → Screen locks → Challenge appears →
Kid solves challenge → Screen unlocks (10 min) → Repeat
```

### Key Differentiator: Active Engagement, Not Restriction

Childlock is **not a screen time limiter**. It's a **habit trainer**. The mental model shift:

| Traditional Approach | Childlock Approach |
|---|---|
| "You've used 1 hour, you're done" | "Solve this puzzle to keep watching" |
| Punishment-based (loss of access) | Reward-based (earn continued access) |
| Binary (on/off) | Continuous (engage → reward → engage) |
| Zero developmental benefit | Builds cognitive skills passively |
| Causes tantrums at cutoff | Normalizes thinking breaks |

Over time, kids internalize the pattern: **effort unlocks reward**. This is habit training disguised as parental control.

---

## 3. Target Users & Personas

### Primary: Parents (Decision Makers + Purchasers)

**Persona 1: "Guilt-Ridden Grace"** (35, mother of 2, ages 5 and 8)
- Lets kids use iPads but feels guilty about passive consumption
- Has tried Screen Time limits — kids throw tantrums when time expires
- Wants kids to "at least learn something" during screen time
- Willing to pay for peace of mind
- Discovers products through mom Facebook groups and Instagram

**Persona 2: "Structured Sam"** (40, father of 1, age 10)
- Already uses Apple Screen Time aggressively
- Wants more granular control — not just limits, but conditions
- Data-driven, wants usage reports and progress tracking
- Finds products through tech blogs, Reddit, App Store search

**Persona 3: "Overwhelmed Omar"** (32, single parent, age 4)
- Relies on screens as a babysitter (no judgment — survival mode)
- Doesn't want to remove screens, wants to make them "less bad"
- Price-sensitive, needs free tier to be genuinely useful
- Word-of-mouth discovery via daycare parent groups

### Secondary: Children (End Users)

| Age Band | Developmental Stage | Challenge Style |
|---|---|---|
| 3–5 | Pre-literacy, shape/color recognition | Tap the matching shape, count objects, color matching |
| 6–8 | Early math, reading, logical reasoning | Simple arithmetic, word completion, pattern sequences |
| 9–12 | Abstract thinking, multi-step problems | Multi-digit math, logic puzzles, spatial reasoning, memory grids |

### Future (B2B): Schools & Daycares

- Teachers managing shared iPads
- Bulk licensing, classroom-level controls
- Curriculum-aligned challenge packs
- Admin dashboard with per-student reporting
- **Deferred to v2** — B2C product-market fit first

---

## 4. Core Features

### MVP (v1.0) — Ship Target: 8 weeks

#### 4.1 Challenge Engine

The heart of the product. A library of age-graded mini-challenges that appear at timed intervals.

**Challenge Types (MVP):**

| Type | 3–5 | 6–8 | 9–12 |
|---|---|---|---|
| **Math** | Count objects (1-10) | Addition/subtraction (1-100) | Multiplication, fractions, order of operations |
| **Pattern** | Complete the sequence (shapes) | Number patterns, mirror patterns | Matrix reasoning, rotational patterns |
| **Memory** | Match 3 pairs | Match 6 pairs, sequence recall | Match 9+ pairs, n-back sequences |
| **Puzzle** | Drag shape into outline | Jigsaw (4-9 pieces), tangrams | Sliding puzzles, logic grids |

**Challenge UX:**
- Full-screen overlay that cannot be dismissed
- Clear, friendly instruction text + voice prompt for pre-readers (3-5)
- Visual timer (not stressful — encouraging, not countdown-doom)
- Success: Celebration animation → screen unlocks
- Failure: "Try again!" with hint after 2 attempts → solve to continue
- No "skip" option (defeats the purpose)

**Content volume (MVP):** 50 challenges per type per age band = 600 total challenges. Procedurally generated math/pattern challenges provide infinite variety for those categories.

#### 4.2 Timer & Interruption System

- Parent configures interval: 5, 10, 15, 20, or 30 minutes
- Timer runs while monitored apps are in foreground
- Timer pauses when device is locked or monitored app is backgrounded
- At interval expiry: monitored apps are blocked, challenge overlay appears
- After challenge completion: timer resets, apps unblock

**Technical approach:** Uses iOS Screen Time API (ManagedSettings / DeviceActivityMonitor) via Family Sharing to shield/unshield apps on a schedule. Challenge presented via a Device Activity Report extension or ShieldAction handler.

#### 4.3 Parent Dashboard (In-App)

- **App Selection:** Choose which apps trigger the challenge loop (e.g., YouTube, Netflix, games — not educational apps)
- **Interval Control:** Per-app or global interval setting
- **Difficulty:** Auto (age-based) or manual override
- **Age Profile:** One profile per child, supports multiple children
- **Usage Summary:** Daily/weekly view — total screen time, challenges completed, accuracy rate, time spent on challenges
- **PIN Protection:** 4-digit PIN to access parent settings (prevent kids from changing config)

#### 4.4 Child Profiles

- Support 1-5 child profiles per family
- Each profile: name, age (determines challenge difficulty), avatar selection
- Profiles linked via Family Sharing (child's Apple ID)

#### 4.5 Onboarding

1. Parent downloads Childlock on *their* device
2. Family Sharing setup prompt (if not already configured)
3. Create child profile (name, age, avatar)
4. Select apps to monitor on child's device
5. Set challenge interval
6. Done — Childlock active on child's device

### v2.0 Features (Post-PMF)

- **Reward System:** Kids earn stars/coins for challenges → unlock avatar items, themes
- **Streak Tracking:** "7-day streak!" encourages consistency
- **Custom Challenges:** Parents upload their own questions (spelling words, homework review)
- **Curriculum Packs:** Downloadable packs aligned to Common Core / national standards
- **B2B Classroom Mode:** Teacher dashboard, per-student profiles, bulk device management
- **Android Support**
- **Challenge Difficulty Adaptation:** ML-based — adjusts difficulty based on accuracy and completion time
- **Weekly Parent Report (Push/Email):** "This week, Mia completed 47 challenges with 82% accuracy"
- **Sibling Competition:** Leaderboard between siblings (opt-in)

---

## 5. Technical Architecture

### 5.1 Platform & Stack

| Layer | Technology | Rationale |
|---|---|---|
| **iOS App** | Swift / SwiftUI | Native performance required for screen management APIs |
| **Screen Time Integration** | FamilyControls, ManagedSettings, DeviceActivityMonitor | Apple's official API for parental controls (requires Family Sharing entitlement) |
| **Challenge Engine** | Local Swift module | Challenges must work offline; no network dependency for core loop |
| **Backend** | Supabase (PostgreSQL + Auth + Edge Functions) | Fast to ship, handles auth/data/push |
| **Parent Dashboard Data** | Supabase Realtime | Sync usage data from child device → parent dashboard |
| **Push Notifications** | APNs via Supabase | Daily summary, streak reminders |
| **Analytics** | PostHog (self-hosted or cloud) | Funnel tracking, retention, feature usage |
| **Payments** | RevenueCat | StoreKit 2 wrapper, subscription management, paywall A/B testing |

### 5.2 iOS Screen Time API Architecture

This is the most technically complex and critical component.

```
┌─────────────────────────────────────────────┐
│              Parent's iPhone                 │
│  ┌────────────────────────────────────────┐  │
│  │         Childlock Parent App           │  │
│  │  - Child profiles                      │  │
│  │  - App selection (FamilyActivityPicker)│  │
│  │  - Interval/difficulty config          │  │
│  │  - Usage reports                       │  │
│  └────────────────────────────────────────┘  │
│               │ FamilyControls                │
│               │ AuthorizationCenter           │
│               ▼                               │
│  ┌────────────────────────────────────────┐  │
│  │  ManagedSettingsStore (per child)      │  │
│  │  - Shield selected apps               │  │
│  │  - Configure shield appearance         │  │
│  └────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                    │
          Family Sharing sync
                    ▼
┌─────────────────────────────────────────────┐
│              Child's iPad/iPhone             │
│  ┌────────────────────────────────────────┐  │
│  │    DeviceActivityMonitor Extension     │  │
│  │  - Monitors app usage intervals        │  │
│  │  - Triggers shield at interval expiry  │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │    ShieldConfiguration Extension       │  │
│  │  - Custom shield UI = Challenge screen │  │
│  │  - On solve → remove shield            │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │    Childlock Companion App (child)     │  │
│  │  - Avatar, streaks, reward display     │  │
│  │  - Challenge practice mode (voluntary) │  │
│  └────────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Key API constraints:**
- `FamilyControls` requires the parent to authorize via `AuthorizationCenter.shared.requestAuthorization(for: .child)`
- `DeviceActivityMonitor` runs as an app extension with strict memory/CPU limits — challenge UI must be lightweight
- Shield customization is limited — may need to use `ShieldAction` to redirect to the companion app for richer challenge UI
- App selection uses `FamilyActivityPicker` (opaque tokens — Apple does not expose app bundle IDs for privacy)
- Requires iOS 16+ for full DeviceActivityMonitor support

**Risk:** Apple's Screen Time API is notoriously restrictive and poorly documented. Fallback: Guided Access mode with manual parent activation (degraded UX but functional).

### 5.3 Data Model (Core)

```
Family
├── parent_id (Supabase Auth UUID)
├── subscription_status
└── children[]
    ├── child_id
    ├── name
    ├── age
    ├── avatar
    ├── monitored_apps[] (opaque FamilyControls tokens)
    ├── interval_minutes
    ├── difficulty_override (auto | easy | medium | hard)
    └── sessions[]
        ├── session_id
        ├── date
        ├── app_category
        ├── screen_time_minutes
        ├── challenges_presented
        ├── challenges_completed
        ├── challenges_failed
        ├── avg_solve_time_seconds
        └── challenge_details[]
            ├── type (math | pattern | memory | puzzle)
            ├── difficulty_level
            ├── presented_at
            ├── completed_at
            ├── attempts
            └── correct (bool)
```

### 5.4 Offline-First

The challenge engine and timer system must work entirely offline. Network is only needed for:
- Initial Family Sharing authorization
- Syncing usage data to parent dashboard (batched, background)
- Subscription validation (cached with grace period)
- Challenge pack downloads (v2)

---

## 6. Success Metrics

### North Star Metric

**Weekly Active Families (WAF):** Families where at least one child completed 3+ challenges in the past 7 days.

### Primary Metrics

| Metric | Target (Month 3) | Target (Month 6) |
|---|---|---|
| D1 Retention (parent app) | 60% | 65% |
| D7 Retention (parent app) | 35% | 40% |
| D30 Retention (parent app) | 20% | 25% |
| Challenge completion rate | 85% | 90% |
| Avg challenges/child/day | 4 | 6 |
| Free → Trial conversion | 15% | 20% |
| Trial → Paid conversion | 40% | 50% |
| Monthly churn (paid) | <8% | <6% |

### Secondary Metrics

| Metric | Why It Matters |
|---|---|
| Avg solve time by age band | Validates difficulty calibration |
| Challenge skip/abandon rate | Should be <5% — if higher, challenges are too hard or UX is broken |
| Apps most frequently monitored | Informs partnerships and content strategy |
| Family Sharing setup completion rate | Critical onboarding friction point |
| Time from install → first challenge served | Must be <5 minutes |
| NPS (quarterly survey) | Target: 50+ |

### Guardrail Metrics (Do Not Regress)

- App Store rating: maintain 4.5+
- Crash rate: <0.5%
- Challenge load time: <500ms
- Shield activation latency: <2s after interval expiry

---

## 7. Risks & Mitigations

### High Risk

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Apple Screen Time API limitations** | Core feature may not work as designed; shield customization is minimal | High | Prototype API integration in week 1. Fallback: Guided Access mode with manual activation. Engage Apple Developer Technical Support early. |
| **App Store rejection** | Parental control apps face extra scrutiny; Apple may reject for policy reasons | Medium | Study Apple's Parental Controls app review guidelines. Ensure full compliance with MDM/Screen Time API usage policies. No private API usage. |
| **Kids find workarounds** | Kids are resourceful — force quit, restart device, disable extensions | Medium | Test with actual kids during QA. Use `ManagedSettings` store persistence. Shield reactivates on app relaunch. Document known bypass vectors. |
| **Onboarding drop-off** | Family Sharing setup is complex; parents may abandon | High | In-app step-by-step guide with screenshots. Track funnel meticulously. Offer "demo mode" that works without Family Sharing for trial. |

### Medium Risk

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Challenge fatigue** | Kids get bored of same challenge types | Medium | Procedural generation for math/patterns. Track repetition. v2: downloadable challenge packs, community content. |
| **Age miscalibration** | Challenges too easy (boring) or too hard (frustrating) | Medium | Beta test with 20+ families across age bands. Add "too easy" / "too hard" feedback button. v2: adaptive difficulty. |
| **Parent-child conflict** | Kid gets frustrated, blames parent, tantrums increase | Low-Medium | Position challenges as "fun brain games" not punishment. Celebration animations. Never use negative language. Provide parent talking-points in onboarding. |
| **Privacy/COPPA** | Collecting data on children under 13 triggers COPPA compliance | High | Minimal data collection on child device. No PII stored for children. Parent consent via Apple's Family Sharing (built-in parental consent mechanism). Privacy policy reviewed by counsel. |

### Low Risk

| Risk | Impact | Likelihood | Mitigation |
|---|---|---|---|
| **Competitor fast-follow** | Larger player copies the concept | Medium | First-mover advantage in "active engagement" framing. Build brand in parenting communities. Moat = challenge content library + adaptive engine (v2). |
| **Screen Time API deprecation** | Apple changes/removes APIs | Low | Monitor WWDC annually. Maintain abstraction layer over Apple APIs. |

---

## 8. Go-to-Market Strategy

### Phase 1: Seed Community (Pre-Launch, Weeks 1-4)

- **Landing page** with email capture: "Turn screen time into brain time"
- **Waitlist** with referral mechanic (refer 3 friends → early access)
- Seed 5-10 **parenting Facebook groups** with authentic posts (not spammy — genuine problem discussion)
- Identify 3-5 **mom/dad micro-influencers** (10K-50K followers) for beta access
- Post in **r/Parenting**, **r/Mommit**, **r/daddit** with genuine ask for beta testers

### Phase 2: Beta (Weeks 5-8)

- 50-100 beta families via TestFlight
- Weekly feedback calls with 5 parents
- Iterate on challenge difficulty, onboarding flow, interval UX
- Collect testimonials and before/after usage data

### Phase 3: Launch (Week 9)

- **App Store Optimization:** Keywords — "screen time for kids", "parental controls", "kids brain games", "screen time challenges"
- **Launch on Product Hunt** — "The app that makes your kids think before they watch"
- **Press:** Pitch to parenting blogs (Fatherly, Motherly, Scary Mommy) and education tech outlets
- **Influencer wave:** Send to 20 parenting creators with kids in target age range
- **App Store feature pitch:** Apple loves parental wellbeing + Screen Time API usage — submit for editorial consideration

### Phase 4: Growth (Months 2-6)

- **Referral program:** "Give a friend 1 month free, get 1 month free"
- **Content marketing:** Blog posts on "screen time guilt", "making screen time productive", "best parental control approaches"
- **School/daycare partnerships:** Pilot with 5 local daycares for B2B validation
- **Seasonal campaigns:** Back-to-school, summer break ("Summer Brain Challenge")
- **Localization:** Spanish (largest US minority), then major EU languages

### Positioning Statement

> Childlock turns passive screen time into active learning moments. Instead of cutting kids off — which causes tantrums and teaches nothing — Childlock punctuates entertainment with age-appropriate brain challenges. Kids earn their screen time. Parents get peace of mind. Everyone wins.

### Competitive Landscape

| Product | What It Does | Why Childlock Wins |
|---|---|---|
| Apple Screen Time | Hard time limits, app restrictions | No cognitive engagement. Binary on/off. Tantrums. |
| Google Family Link | Android equivalent of Screen Time | Same limitations. Android-only. |
| Bark | Content monitoring + time limits | Focused on safety, not development. No challenges. |
| Qustodio | Cross-platform monitoring | Enterprise-grade, complex. No active engagement. |
| OurPact | Schedule-based blocking | Same on/off paradigm. No learning component. |
| Khan Academy Kids | Educational content | Requires replacing entertainment. Kids resist. |

**Childlock's unique position:** The only app that works *with* existing screen time rather than against it. Not a replacement. Not a limiter. A **habit trainer**.

---

## 9. Monetization

### Pricing Model

| Tier | Price | Includes |
|---|---|---|
| **Free** | $0 | 3 challenge interruptions/day, 1 child profile, basic usage stats |
| **Premium Monthly** | $4.99/mo | Unlimited challenges, up to 5 children, full reports, all challenge types, custom intervals |
| **Premium Annual** | $39.99/yr ($3.33/mo) | Same as monthly — 33% savings |
| **Family (v2)** | $7.99/mo | Premium + shared with Family Sharing group (up to 6 adults) |

### Why This Works

- **Free tier is genuinely useful** — 3 challenges/day = ~30 min of "protected" screen time. Enough for parents to see the value.
- **Upgrade trigger is natural** — kids hit the 3-challenge limit, parent sees it working, wants more.
- **Annual discount encourages commitment** — parental control is a long-term need, not a one-time purchase.
- **Price point ($4.99/mo)** is below the "impulse threshold" for parents who spend $5-15/mo on kids' apps already.

### Revenue Projections (Conservative)

| Month | WAF | Paid Families | MRR |
|---|---|---|---|
| 3 | 500 | 75 (15%) | $375 |
| 6 | 2,000 | 400 (20%) | $2,000 |
| 12 | 8,000 | 2,000 (25%) | $10,000 |

---

## 10. MVP Scope & Timeline

### Week 1-2: Foundation

- [ ] Screen Time API prototype — confirm shield + unshield flow works
- [ ] FamilyControls authorization flow
- [ ] Basic app shell (SwiftUI) with parent/child mode
- [ ] Supabase project setup (auth, database schema)

### Week 3-4: Challenge Engine

- [ ] Challenge data model and rendering framework
- [ ] Math challenges (all 3 age bands, procedural generation)
- [ ] Pattern challenges (all 3 age bands)
- [ ] Memory game (all 3 age bands)
- [ ] Challenge completion → shield removal flow

### Week 5-6: Parent Controls

- [ ] FamilyActivityPicker integration (app selection)
- [ ] Interval configuration UI
- [ ] Child profile management (CRUD)
- [ ] PIN-protected parent settings
- [ ] Basic usage stats (today's summary)

### Week 7: Polish & Payments

- [ ] RevenueCat integration (free/premium tiers)
- [ ] Paywall UI
- [ ] Onboarding flow (step-by-step Family Sharing guide)
- [ ] Challenge celebration animations
- [ ] Voice prompts for 3-5 age band

### Week 8: QA & Launch Prep

- [ ] Beta testing with 20+ families
- [ ] App Store assets (screenshots, description, keywords)
- [ ] Privacy policy & COPPA compliance review
- [ ] Crash/performance testing
- [ ] TestFlight → App Store submission

---

## Appendix A: Design Principles

1. **Warm, not clinical.** This is about kids — use rounded shapes, friendly colors (warm palette, not generic blue), playful illustrations. Reference: Apple Fitness+ encouragement tone.
2. **Celebrate effort, not perfection.** Wrong answers get "Almost! Try again!" — never "Wrong." Success animations are joyful.
3. **Parent trust.** The parent dashboard should feel competent and data-rich, not dumbed down. Parents are smart — give them real information.
4. **Invisible when working.** On the child's device, Childlock should be invisible until the challenge appears. No persistent UI, no nagging.
5. **Fast.** Challenge load <500ms. Shield activation <2s. No loading spinners. Kids have zero patience.

## Appendix B: COPPA Compliance Notes

- No account creation for children — profiles are parent-created, parent-owned
- No PII collected from children (no name storage on server — only local device)
- Usage data is anonymized and aggregated before server sync
- Parent provides consent implicitly via Family Sharing (Apple's verified parent-child relationship)
- Privacy policy must clearly state data practices for children under 13
- Legal review required before launch

## Appendix C: Open Questions

1. **Shield UI richness:** Can we render a full mini-game inside a `ShieldConfiguration` extension, or must we redirect to the companion app? Needs API prototyping in week 1.
2. **Multiple device support:** If a child has both iPad and iPhone, does the timer sync? Initial answer: per-device timers (simpler). Revisit in v2.
3. **Accessibility:** VoiceOver support for challenges is critical for inclusivity but adds scope. MVP: voice prompts for youngest age band. v2: full VoiceOver.
4. **Offline grace period:** How long should subscription validation cache last? Recommendation: 7 days (generous — this is a kids' app, not a security product).
