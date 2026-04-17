# Childlock Go-To-Market Plan

**Version:** 2.0  
**Date:** 2026-03-14 (SGT)  
**Project:** childlock  
**Plan horizon:** 90 days (2026-03-14 to 2026-06-12)

## 1. Operating Context

- PRD confirms the core wedge: transform passive screen time into active thinking moments (not hard cutoffs).
- Deploy receipt confirms production web deployment succeeded on **2026-03-13T18:40:19Z** at **https://childlock.vercel.app**.
- Pipeline history shows implementation/qa/deploy completed, GTM docs existed but were placeholder-level and not execution-ready.
- GTM objective now: convert the concept into a repeatable parent acquisition + activation + paid conversion engine.

## 2. Positioning

### Category
Childlock is a **screen-time habit trainer** for families, not a traditional parental blocker and not a standalone educational app.

### Positioning statement
Childlock turns passive screen time into active brain breaks. Kids solve short, age-appropriate challenges to continue watching. Parents get calmer transitions, better habits, and real progress signals.

### One-line value prop
**Turn screen time into brain time.**

### Message pillars
1. **Active engagement over punishment**
- Traditional limits end in shutdown + conflict.
- Childlock uses "effort -> reward" loops.

2. **Works with real family behavior**
- Parents do not need to remove YouTube/Netflix/games.
- Childlock upgrades existing routines instead of forcing full replacement.

3. **Calm child experience**
- Friendly challenge language and celebration-first feedback.
- Avoids punitive tone.

4. **Parent-grade control + visibility**
- Interval control, app targeting, profile-based settings, and usage summaries.

### Persona-led message map
| Persona | Core pain | Primary promise | Conversion trigger |
|---|---|---|---|
| Guilt-Ridden Grace | "I feel bad about passive iPad time" | "Keep screen time, add meaningful thinking moments" | Sees first 3-5 successful interruptions with low resistance |
| Structured Sam | "I need more than blunt limits" | "Conditional access + measurable completion metrics" | Trust in controls, reports, and reliability |
| Overwhelmed Omar | "I need survival-mode screens without guilt" | "Free tier that already improves outcomes" | Hits daily limit and sees behavior improvement |

## 3. Product-Market Offer Design

### Packaging and pricing (from PRD, GTM-ready)
- Free: 3 interruptions/day, 1 child, basic stats.
- Premium monthly: $4.99.
- Premium annual: $39.99.

### Conversion architecture
- **Activation moment:** Parent config complete + child solves first challenge.
- **Value moment:** Parent sees at least 3 completed interruptions in first 24h.
- **Upgrade moment:** Free interruption cap reached after clear behavior benefit.

### Paywall framing
- Lead with outcomes, not feature list:
  - "More calm transitions"
  - "More brain breaks"
  - "More control for busy days"

## 4. 90-Day GTM Phases

## Phase 0: Readiness (2026-03-14 to 2026-03-21)
**Goal:** Ensure traffic can convert and onboarding friction is visible in analytics.

- Finalize waitlist/landing experience with clear CTA: "Join iOS beta".
- Confirm production URL routes used for campaign pages are accessible.
- Implement event taxonomy (install -> onboarding -> first challenge -> day-7 retained -> upgrade).
- Build messaging kit: landing copy, creator brief, community post templates.

**Exit criteria:**
- Tracking events firing end-to-end in test flow.
- Beta application funnel live.
- 10 parent discovery calls scheduled.

## Phase 1: Closed Beta (2026-03-22 to 2026-04-18)
**Goal:** Prove retention and challenge acceptance before broad launch.

- Recruit 75-100 families (balanced across age bands 3-5, 6-8, 9-12).
- Run weekly parent interviews (minimum 8 calls/week).
- Capture friction reasons: setup drop-off, challenge difficulty mismatch, bypass attempts.
- Publish weekly beta digest to waitlist + social proof snippets.

**Exit criteria:**
- D7 parent retention >= 30%.
- Challenge completion >= 80%.
- Family Sharing setup completion >= 65%.

## Phase 2: Launch Wave (2026-04-19 to 2026-05-10)
**Goal:** Public launch with credible proof and premium conversion assets.

- App Store metadata and screenshot sequence published.
- Creator wave 1: 15 parenting micro-creators (10k-80k followers).
- Community launch threads: r/Parenting, r/Mommit, r/daddit, parent Facebook groups.
- Product Hunt launch with demo video and parent testimonial clips.

**Exit criteria:**
- 1,500+ waitlist total.
- 500+ launch-week installs.
- Free -> trial conversion >= 12%.

## Phase 3: Optimization + Scale (2026-05-11 to 2026-06-12)
**Goal:** Reach Month-3 PRD targets and harden growth loops.

- Referral loop live: "Give 1 month, get 1 month".
- Creator wave 2 with top-performing hooks only.
- Paid experiments (small budget) on Meta and TikTok with strict CAC guardrails.
- Add lifecycle messaging: day-1 coaching, day-3 setup nudge, day-7 progress summary.

**Exit criteria (target by 2026-06-12):**
- WAF >= 500.
- D7 >= 35%.
- Free -> trial >= 15%.
- Trial -> paid >= 40%.

## 5. Channel Strategy

### 1) App Store (high-intent)
- Keyword focus: "screen time for kids", "parental controls", "kids brain games", "screen time challenge".
- Use outcome-first subtitle and first screenshot headline.
- Collect reviews from high-satisfaction beta cohort during launch week.

### 2) Parenting communities (trust-driven)
- Operate as problem-solution posts, not promo dumps.
- Weekly founder notes: "what we learned from X families this week".
- Share practical tips regardless of install to build credibility.

### 3) Micro-creators (authentic proof)
- Prioritize creators with kids in 4-10 age range.
- Request "routine" style videos, not polished ad reads.
- Keep claims specific: interruptions/day, tantrum delta, solve rate.

### 4) Referral
- Trigger referral ask only after parent sees 5+ successful challenges.
- In-app prompt: "Know another parent fighting passive screen time?"

### 5) PR and editorial
- Pitch angle: "Parental controls that teach effort, not punishment."
- Targets: parenting media and education-tech newsletters.

## 6. Premium Creative Direction (Aligned to premium-ui-designer)

### Visual intent
Warm, trustworthy, professional. Calm confidence, not toy-like chaos and not clinical enterprise control.

### Palette and tone
- Base background: warm neutral (`#F8F7F4` / `#FAFAF8`).
- Text: near-black (`#1A1A1A`), not pure black.
- Accent: warm coral/orange (single accent only) for CTA and key highlights.
- Semantic colors muted and parent-safe.

### Typography hierarchy
- Headline: expressive serif for emotional trust.
- Body/UI: clean sans for legibility.
- Max 3-4 visible sizes per frame.

### Screenshot design rules (before.click-grade)
- One message per screenshot, no overloaded feature dumps.
- Strong top-third headline with short sentence length.
- Device frame + focused UI crop + one supporting metric.
- Use generous spacing and left-aligned body copy.
- Keep accent usage sparse (2-3 key accents per frame).

### App Store screenshot storyboard
1. **Hero outcome:** "Turn screen time into brain time"
2. **Core loop:** "Watch -> Solve -> Continue"
3. **Child experience:** calm, friendly challenge prompt
4. **Parent control:** set interval + selected apps
5. **Progress proof:** weekly completion + accuracy summary
6. **Multi-child profiles:** one home, multiple age bands
7. **Tantrum-safe framing:** rewards over hard shutoffs
8. **Pricing anchor:** useful free tier, simple premium upgrade

### Creative references to emulate
- **Gentler Streak:** warm encouragement and humane progress language.
- **Wise / Monzo:** trust-first clarity and premium information hierarchy.
- **Amie:** polished composition with personality and restraint.
- **before.click gallery:** sequence discipline, conversion-first screenshot storytelling.

### Voice and copy style
- Warm + professional + non-judgmental.
- Avoid guilt-shaming language.
- Replace "control your child" with "build better habits together".

## 7. Measurement Plan

### North star
- **Weekly Active Families (WAF):** >=1 child completed >=3 challenges in last 7 days.

### KPI dashboard (weekly)
| Funnel stage | KPI | Month-3 target |
|---|---|---|
| Acquisition | CTR to waitlist/app page | >= 2.5% |
| Activation | Install -> first challenge complete | >= 55% |
| Setup quality | Family Sharing setup completion | >= 70% |
| Engagement | Challenges per child per day | >= 4 |
| Learning loop quality | Challenge completion rate | >= 85% |
| Monetization | Free -> trial | >= 15% |
| Monetization | Trial -> paid | >= 40% |
| Retention | D7 parent retention | >= 35% |
| Retention | D30 parent retention | >= 20% |

### Guardrails
- App rating >= 4.5.
- Crash rate < 0.5%.
- Challenge load < 500ms.
- Shield activation latency < 2s.

## 8. Experiment Backlog (Ranked)

| Priority | Hypothesis | Test | Success threshold |
|---|---|---|---|
| P0 | Outcome-first hero beats feature hero | A/B landing hero copy | +20% waitlist conversion |
| P0 | 10-min default interval improves completion | Default interval test | +8% challenge completion |
| P1 | Progress-summary push on day 2 lifts D7 | Day-2 push experiment | +5pp D7 retention |
| P1 | Parent testimonial video outperforms static image ad | Creator ad format test | +25% CTR |
| P2 | Annual plan framing boosts paid conversion | Paywall annual emphasis | +15% annual mix |

## 9. Budget and Resourcing (First 90 Days)

### Lean baseline ($7k total)
- Creator seeding + whitelisting: $4k
- Creative production (screenshots/video): $1.5k
- Paid testing reserve: $1k
- Community tooling/misc: $500

### Team ownership
- GTM lead: Kato/Xavier
- Creative system + screenshot pack: design owner
- Creator operations: growth owner
- Analytics instrumentation + dashboards: product/engineering owner

## 10. Risk Register and Mitigation

| Risk | Impact | Mitigation |
|---|---|---|
| Family Sharing setup drop-off | High | Step-by-step onboarding visuals + setup concierge content |
| iOS Screen Time edge-case instability | High | Explicit "known limits" messaging + fallback playbook |
| Creative drift into generic "kids app" look | Medium | Enforce premium-ui-designer token constraints + screenshot QA checklist |
| Community backlash ("too controlling") | Medium | Lead with reward framing and non-punitive language |
| Web landing reliability gap | Medium-High | Verify production route health before paid or creator traffic |

## 11. Decision Gates

- **Gate A (2026-03-28):** If setup completion < 50%, pause top-of-funnel spend and fix onboarding.
- **Gate B (2026-04-18):** If D7 < 25% in beta, delay launch and recalibrate challenge flow.
- **Gate C (2026-05-10):** If free->trial < 10%, rework paywall trigger and value proof sequence.
- **Gate D (2026-06-12):** If WAF < 300 and paid churn > 10%, narrow ICP and reset channel mix.

## 12. Immediate 14-Day Execution Checklist

1. Finalize landing + waitlist messaging and route checks.
2. Produce App Store screenshot v1 using the storyboard above.
3. Prepare creator briefing kit (hooks, claims, do/don't examples).
4. Implement event schema and dashboard for activation/retention/conversion.
5. Run first 20 parent interviews and publish learnings summary.
6. Ship first referral flow copy and in-app trigger logic.

