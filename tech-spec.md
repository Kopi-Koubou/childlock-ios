# Childlock — Technical Specification

**Version:** 1.0
**Date:** 2026-03-13
**Author:** Kato (AI Chief of Staff)
**Status:** Draft — pending Xavier review
**PRD Reference:** `prd.md` v1.0
**Design Reference:** `design-spec.md` v1.0

---

## 1. Architecture Overview

### 1.1 High-Level Architecture

Childlock is a native iOS app built with **SwiftUI + MVVM + Combine**, leveraging Apple's Screen Time framework (FamilyControls, ManagedSettings, DeviceActivityMonitor) for parental controls. The app runs as two logical units: a **parent app** (configuration + dashboard) and a set of **app extensions** that run on the child's device (monitoring + shielding + challenges).

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Childlock Architecture                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────────────┐     ┌──────────────────────┐             │
│  │   Parent App (Host)  │     │   App Extensions      │             │
│  │                      │     │   (Child's Device)    │             │
│  │  ┌────────────────┐  │     │                        │             │
│  │  │  SwiftUI Views │  │     │  ┌──────────────────┐  │             │
│  │  │  (4 tabs)      │  │     │  │ DeviceActivity   │  │             │
│  │  └───────┬────────┘  │     │  │ Monitor Extension│  │             │
│  │          │           │     │  └──────────────────┘  │             │
│  │  ┌───────▼────────┐  │     │  ┌──────────────────┐  │             │
│  │  │  ViewModels    │  │     │  │ Shield Config    │  │             │
│  │  │  (MVVM)        │  │     │  │ Extension        │  │             │
│  │  └───────┬────────┘  │     │  └──────────────────┘  │             │
│  │          │           │     │  ┌──────────────────┐  │             │
│  │  ┌───────▼────────┐  │     │  │ Shield Action    │  │             │
│  │  │  Services      │  │     │  │ Extension        │  │             │
│  │  │  Layer         │  │     │  └──────────────────┘  │             │
│  │  └───────┬────────┘  │     │                        │             │
│  │          │           │     └──────────────────────┘             │
│  └──────────┼───────────┘                                          │
│             │                                                       │
│  ┌──────────▼───────────────────────────────────────────┐          │
│  │                    Shared Layer                       │          │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │          │
│  │  │Challenge │ │ SwiftData│ │ Screen   │ │ Auth   │ │          │
│  │  │Engine    │ │ Store    │ │ Time Mgr │ │Service │ │          │
│  │  └──────────┘ └──────────┘ └──────────┘ └────────┘ │          │
│  └──────────────────────────────────────────────────────┘          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────┐          │
│  │            External Services (Background)            │          │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │          │
│  │  │ Supabase │  │RevenueCat│  │  PostHog  │          │          │
│  │  │ (Auth +  │  │(Payments)│  │(Analytics)│          │          │
│  │  │  Data)   │  │          │  │           │          │          │
│  │  └──────────┘  └──────────┘  └──────────┘          │          │
│  └──────────────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Module Structure

```
Childlock/
├── App/
│   ├── ChildlockApp.swift              # App entry point
│   └── AppState.swift                  # Global app state (observable)
│
├── Models/                             # Data models (shared with extensions)
│   ├── ChildProfile.swift
│   ├── ChallengeSession.swift
│   ├── ChallengeResult.swift
│   ├── ChallengeType.swift
│   └── AppSettings.swift
│
├── Views/
│   ├── Onboarding/
│   │   ├── WelcomeView.swift
│   │   ├── FamilySharingAuthView.swift
│   │   ├── ChildProfileCreationView.swift
│   │   ├── AppSelectionView.swift
│   │   ├── IntervalPickerView.swift
│   │   ├── PINSetupView.swift
│   │   └── OnboardingCompleteView.swift
│   │
│   ├── Dashboard/
│   │   ├── HomeTabView.swift
│   │   ├── DailySummaryCard.swift
│   │   ├── ChildOverviewCard.swift
│   │   └── ActivityFeedView.swift
│   │
│   ├── Children/
│   │   ├── ChildrenTabView.swift
│   │   ├── ChildDetailView.swift
│   │   ├── ChallengeBreakdownChart.swift
│   │   └── ChallengeHistoryList.swift
│   │
│   ├── Apps/
│   │   ├── AppsTabView.swift
│   │   └── MonitoredAppRow.swift
│   │
│   ├── Settings/
│   │   ├── SettingsTabView.swift
│   │   ├── PINEntryView.swift
│   │   └── PaywallView.swift
│   │
│   ├── Challenges/                     # Challenge UI (shared with extensions)
│   │   ├── ChallengeContainerView.swift
│   │   ├── MathChallengeView.swift
│   │   ├── PatternChallengeView.swift
│   │   ├── MemoryChallengeView.swift
│   │   ├── PuzzleChallengeView.swift
│   │   ├── CelebrationView.swift
│   │   └── HintView.swift
│   │
│   └── Shared/
│       ├── DesignTokens.swift          # Colors, fonts, spacing (design-spec.md Appendix A)
│       ├── AnswerButton.swift
│       ├── ProgressDots.swift
│       └── AvatarView.swift
│
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── ChildDetailViewModel.swift
│   ├── AppsViewModel.swift
│   ├── SettingsViewModel.swift
│   └── ChallengeViewModel.swift
│
├── Services/
│   ├── ScreenTimeManager.swift         # FamilyControls + ManagedSettings wrapper
│   ├── ChallengeEngine.swift           # Challenge generation + difficulty
│   ├── AuthService.swift               # Supabase Auth
│   ├── DataSyncService.swift           # Background sync to Supabase
│   ├── SubscriptionService.swift       # RevenueCat wrapper
│   ├── PINService.swift                # Keychain-backed PIN storage
│   ├── AudioService.swift              # Voice prompts for ages 3-5
│   └── HapticsService.swift            # Haptic feedback
│
├── Persistence/
│   ├── SwiftDataContainer.swift        # ModelContainer setup
│   └── SyncQueue.swift                 # Offline data queue
│
├── Extensions/
│   ├── DeviceActivityMonitorExtension/ # Monitors app usage intervals
│   │   └── ChildlockMonitor.swift
│   ├── ShieldConfigurationExtension/   # Custom shield UI
│   │   └── ChildlockShieldConfig.swift
│   └── ShieldActionExtension/          # Handle shield button taps
│       └── ChildlockShieldAction.swift
│
└── Resources/
    ├── Assets.xcassets                 # Colors, images, app icon
    ├── VoicePrompts/                   # Pre-recorded audio for ages 3-5
    └── Localizable.strings
```

### 1.3 Technology Choices

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| UI Framework | SwiftUI | Declarative, modern, excellent for animations. iOS 16+ aligns with Screen Time API requirement. |
| Architecture | MVVM + Combine | Clean separation. ViewModels expose `@Published` properties. Combine handles async data flow. |
| Local Storage | SwiftData | Apple's modern persistence. Shared between app and extensions via App Groups. Lighter than CoreData for this use case. |
| Networking | Supabase Swift SDK | Auth + Realtime + PostgreSQL. Minimal backend code. |
| Payments | RevenueCat SDK | Handles StoreKit 2, subscription state, paywall A/B testing. |
| Analytics | PostHog iOS SDK | Privacy-focused, COPPA-compatible with anonymization. |
| Screen Time | FamilyControls / ManagedSettings / DeviceActivityMonitor | Apple's only sanctioned API for parental controls. No private API usage. |

**Why SwiftData over CoreData:** SwiftData uses `@Model` macros, integrates natively with SwiftUI's observation system, and reduces boilerplate. Given iOS 17+ adoption is >85% (and our floor is iOS 16), we target SwiftData with an iOS 17 minimum. This simplifies persistence significantly.

> **Decision: Raise minimum to iOS 17.** DeviceActivityMonitor gained critical stability fixes in iOS 17. SwiftData requires iOS 17. The intersection of "parents with kids using Family Sharing" and "running iOS 16 but not 17" is negligibly small.

---

## 2. Data Models

### 2.1 SwiftData Models

```swift
import SwiftData
import FamilyControls

// MARK: - Child Profile

@Model
final class ChildProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var avatarName: String                        // e.g., "fox", "owl", "bear"
    var intervalMinutes: Int                       // 5, 10, 15, 20, or 30
    var difficultyOverride: DifficultyOverride     // .auto, .easy, .medium, .hard
    var createdAt: Date
    var updatedAt: Date

    // FamilyControls — stored as Data (opaque tokens, not decodable)
    var monitoredActivitiesData: Data?

    @Relationship(deleteRule: .cascade, inverse: \ChallengeSession.child)
    var sessions: [ChallengeSession] = []

    var ageBand: AgeBand {
        switch age {
        case 3...5:  return .young
        case 6...8:  return .middle
        case 9...12: return .older
        default:     return .middle
        }
    }
}

enum AgeBand: String, Codable {
    case young   // 3-5
    case middle  // 6-8
    case older   // 9-12
}

enum DifficultyOverride: String, Codable {
    case auto, easy, medium, hard
}

// MARK: - Challenge Session

@Model
final class ChallengeSession {
    @Attribute(.unique) var id: UUID
    var child: ChildProfile?
    var date: Date
    var screenTimeSeconds: Int
    var synced: Bool                               // false until pushed to Supabase

    @Relationship(deleteRule: .cascade, inverse: \ChallengeResult.session)
    var results: [ChallengeResult] = []

    var challengesPresented: Int { results.count }
    var challengesCompleted: Int { results.filter(\.completed).count }
    var accuracy: Double {
        guard challengesPresented > 0 else { return 0 }
        return Double(challengesCompleted) / Double(challengesPresented)
    }
}

// MARK: - Challenge Result

@Model
final class ChallengeResult {
    @Attribute(.unique) var id: UUID
    var session: ChallengeSession?
    var type: ChallengeType
    var difficultyLevel: Int                      // 1-10 within age band
    var presentedAt: Date
    var completedAt: Date?
    var attempts: Int
    var completed: Bool
    var hintUsed: Bool
    var solveTimeSeconds: Double?

    var solveTime: Double? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(presentedAt)
    }
}

// MARK: - Challenge Type

enum ChallengeType: String, Codable, CaseIterable {
    case math
    case pattern
    case memory
    case puzzle
}

// MARK: - App Settings (singleton, stored in UserDefaults via AppStorage)

struct AppSettings {
    @AppStorage("parentPINHash") static var parentPINHash: String = ""
    @AppStorage("hasCompletedOnboarding") static var hasCompletedOnboarding: Bool = false
    @AppStorage("voicePromptsEnabled") static var voicePromptsEnabled: Bool = true
    @AppStorage("dailySummaryNotification") static var dailySummaryNotification: Bool = true
    @AppStorage("challengeAlertNotification") static var challengeAlertNotification: Bool = true
    @AppStorage("freeChallengesUsedToday") static var freeChallengesUsedToday: Int = 0
    @AppStorage("freeChallengesResetDate") static var freeChallengesResetDate: String = ""
}
```

### 2.2 App Groups for Extension Data Sharing

All SwiftData models, UserDefaults, and FamilyControls tokens are stored in a shared App Group container so the host app and all three extensions can access the same data.

```swift
// Shared container ID
let appGroupID = "group.com.childlock.shared"

// SwiftData container setup (used by both host app and extensions)
struct PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init() {
        let schema = Schema([
            ChildProfile.self,
            ChallengeSession.self,
            ChallengeResult.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            url: FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
                .appending(path: "childlock.store"),
            allowsSave: true
        )
        container = try! ModelContainer(for: schema, configurations: [config])
    }
}
```

### 2.3 Supabase Schema (Remote — Background Sync Only)

```sql
-- Parents (via Supabase Auth — no separate table needed for MVP)
-- auth.users handles authentication

-- Anonymized usage data (no child PII — COPPA compliant)
CREATE TABLE usage_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    child_profile_id UUID NOT NULL,          -- local UUID, not linked to auth
    age_band TEXT NOT NULL,                   -- 'young', 'middle', 'older'
    date DATE NOT NULL,
    screen_time_seconds INT NOT NULL,
    challenges_presented INT NOT NULL,
    challenges_completed INT NOT NULL,
    avg_solve_time_seconds REAL,
    challenge_breakdown JSONB,               -- {"math": 4, "pattern": 2, ...}
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Row-level security: parents can only read/write their own data
ALTER TABLE usage_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their data"
    ON usage_sessions FOR ALL
    USING (auth.uid() = parent_id);

-- Index for dashboard queries
CREATE INDEX idx_usage_sessions_parent_date
    ON usage_sessions(parent_id, date DESC);
```

---

## 3. iOS Screen Time API Integration

This is the highest-risk, most technically complex component. The architecture wraps Apple's three Screen Time frameworks behind a single `ScreenTimeManager` service.

### 3.1 Framework Overview

| Framework | Purpose | Runs On |
|-----------|---------|---------|
| **FamilyControls** | Authorization + `FamilyActivityPicker` for app selection | Parent device |
| **ManagedSettings** | Apply/remove shields (block/unblock apps) | Child device (via Family Sharing) |
| **DeviceActivityMonitor** | Schedule monitoring events (interval-based triggers) | Child device (extension) |

### 3.2 ScreenTimeManager Service

```swift
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

@Observable
final class ScreenTimeManager {
    static let shared = ScreenTimeManager()

    private(set) var isAuthorized = false
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

    // MARK: - Authorization (Parent Device)

    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .child)
        isAuthorized = true
    }

    // MARK: - Shield Management

    /// Apply shields to selected apps for a specific child profile
    func applyShields(for profile: ChildProfile) {
        guard let activities = profile.decodedActivities else { return }

        store.shield.applications = activities.applicationTokens
        store.shield.applicationCategories =
            .specific(activities.categoryTokens)

        // Custom shield label
        store.shield.webDomainCategories = nil
    }

    /// Remove all shields (after challenge completion)
    func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    // MARK: - Activity Monitoring (Schedules interval-based checks)

    func startMonitoring(profile: ChildProfile) throws {
        let intervalMinutes = profile.intervalMinutes

        // DeviceActivitySchedule repeats the monitoring window
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // DeviceActivityEvent triggers when threshold is reached
        let event = DeviceActivityEvent(
            applications: profile.decodedActivities?.applicationTokens ?? [],
            categories: profile.decodedActivities?.categoryTokens ?? [],
            threshold: DateComponents(minute: intervalMinutes)
        )

        let activityName = DeviceActivityName("childlock.\(profile.id.uuidString)")

        try center.startMonitoring(
            activityName,
            during: schedule,
            events: [
                DeviceActivityEvent.Name("interval_reached"): event
            ]
        )
    }

    func stopMonitoring(profile: ChildProfile) {
        let activityName = DeviceActivityName("childlock.\(profile.id.uuidString)")
        center.stopMonitoring([activityName])
    }
}
```

### 3.3 DeviceActivityMonitor Extension

This extension runs on the **child's device** as a separate process. It fires when the monitored app usage hits the configured interval.

```swift
import DeviceActivity
import ManagedSettings

class ChildlockMonitor: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    // Called when the usage event threshold is reached
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        // Shield the apps — this triggers ShieldConfiguration to render
        // the challenge UI
        guard let profile = loadActiveProfile(for: activity) else { return }

        store.shield.applications = profile.decodedActivities?.applicationTokens
        store.shield.applicationCategories =
            .specific(profile.decodedActivities?.categoryTokens ?? [])

        // Write a flag to shared UserDefaults so the ShieldAction extension
        // knows a challenge is pending
        let defaults = UserDefaults(suiteName: "group.com.childlock.shared")
        defaults?.set(true, name: "challengePending")
        defaults?.set(profile.id.uuidString, forKey: "activeProfileID")
    }

    // Called when the monitoring interval resets
    override func intervalDidEnd(for activity: DeviceActivityName) {
        // Re-start monitoring for the next interval
        // (DeviceActivitySchedule handles this automatically if `repeats: true`)
    }

    private func loadActiveProfile(for activity: DeviceActivityName) -> ChildProfile? {
        let context = PersistenceController.shared.container.mainContext
        let profileID = activity.rawValue.replacingOccurrences(of: "childlock.", with: "")
        guard let uuid = UUID(uuidString: profileID) else { return nil }
        let predicate = #Predicate<ChildProfile> { $0.id == uuid }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }
}
```

### 3.4 ShieldConfiguration Extension

Renders the custom UI shown when an app is shielded. This is where challenges appear.

```swift
import ManagedSettings
import SwiftUI

class ChildlockShieldConfig: ShieldConfigurationDataSource {

    override func configuration(
        shielding application: Application
    ) -> ShieldConfiguration {
        // Minimal config — the shield shows a "Brain Break" message
        // with a button that opens the main app for the full challenge UI
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterial,
            backgroundColor: UIColor(named: "Cream"),
            icon: UIImage(named: "BrainBreakIcon"),
            title: ShieldConfiguration.Label(
                text: "Brain Break!",
                color: UIColor(named: "SunriseOrange") ?? .orange
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Solve a quick challenge to continue",
                color: UIColor(named: "Charcoal") ?? .darkGray
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start Challenge",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(named: "SunriseOrange") ?? .orange,
            secondaryButtonLabel: nil
        )
    }
}
```

> **Key constraint:** `ShieldConfiguration` only supports static text, an icon, and up to 2 buttons. We **cannot** render a full interactive challenge inside the shield. The primary button triggers the `ShieldAction` extension, which opens the main app where the actual challenge runs.

### 3.5 ShieldAction Extension

Handles taps on shield buttons.

```swift
import ManagedSettings

class ChildlockShieldAction: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: Application,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Open the main app to present the challenge
            // The main app will check for `challengePending` flag
            completionHandler(.defer)  // keeps shield active, opens app

        case .secondaryButtonPressed:
            completionHandler(.none)

        @unknown default:
            completionHandler(.none)
        }
    }
}
```

### 3.6 Challenge Flow on Shield Activation

```
1. DeviceActivityMonitor fires eventDidReachThreshold
2. Monitor extension applies shield via ManagedSettingsStore
3. Child sees ShieldConfiguration UI ("Brain Break!")
4. Child taps "Start Challenge"
5. ShieldAction returns .defer → iOS opens the main Childlock app
6. App reads challengePending flag from shared UserDefaults
7. App presents full-screen ChallengeContainerView (no dismiss possible)
8. Child solves challenge
9. App records ChallengeResult to SwiftData
10. App calls ScreenTimeManager.removeShields()
11. App writes challengePending = false
12. Child returns to their app (shield removed)
13. DeviceActivityMonitor resets timer for next interval
```

### 3.7 Known Limitations & Mitigations

| Limitation | Impact | Mitigation |
|-----------|--------|------------|
| ShieldConfiguration cannot render interactive UI | Challenge must happen in the main app, not inline | ShieldAction `.defer` opens main app. UX is 1 extra tap. |
| DeviceActivityMonitor has 15MB memory limit | Extension must be lightweight | All challenge logic runs in the main app, not the extension |
| FamilyActivityPicker uses opaque tokens | Cannot display actual app names/icons | Show app categories. Apple's intentional privacy design. |
| ManagedSettingsStore persists across reboots | Good — prevents bypass | Leverage this as a feature. Shield survives restart. |
| Extensions run in separate processes | Cannot share in-memory state with host app | Use App Groups (shared UserDefaults + SwiftData) |
| iOS 17+ required for reliable DeviceActivityMonitor | Excludes iOS 16 users | Acceptable — iOS 17 adoption >85%. Screen Time API was unstable on iOS 16. |

---

## 4. Challenge Engine Architecture

### 4.1 Protocol-Based Design

Every challenge type conforms to a single protocol, making it trivial to add new challenge types in the future.

```swift
// MARK: - Challenge Protocol

protocol Challenge {
    var type: ChallengeType { get }
    var ageBand: AgeBand { get }
    var difficulty: Int { get }          // 1-10 within age band
    var instruction: String { get }
    var voicePrompt: String? { get }     // For ages 3-5
    var hintText: String { get }
}

// A challenge that presents multiple choice answers
protocol MultipleChoiceChallenge: Challenge {
    associatedtype Answer: Equatable
    var correctAnswer: Answer { get }
    var allAnswers: [Answer] { get }     // Shuffled, includes correct
}

// A challenge with interactive grid (memory game)
protocol GridChallenge: Challenge {
    associatedtype Cell
    var grid: [[Cell]] { get }
    func isComplete() -> Bool
}

// A challenge with drag-and-drop
protocol DragDropChallenge: Challenge {
    associatedtype Piece
    associatedtype Target
    var pieces: [Piece] { get }
    var targets: [Target] { get }
    func isCorrectPlacement(_ piece: Piece, on target: Target) -> Bool
}
```

### 4.2 Challenge Generators

Each challenge type has a generator that produces challenges procedurally based on age band and difficulty.

```swift
// MARK: - Challenge Generator Protocol

protocol ChallengeGenerator {
    var challengeType: ChallengeType { get }
    func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge
}

// MARK: - Math Challenge Generator

struct MathChallenge: MultipleChoiceChallenge {
    let type = ChallengeType.math
    let ageBand: AgeBand
    let difficulty: Int
    let instruction: String
    let voicePrompt: String?
    let hintText: String
    let expression: String             // "24 + 13 = ?"
    let correctAnswer: Int
    let allAnswers: [Int]
}

final class MathChallengeGenerator: ChallengeGenerator {
    let challengeType = ChallengeType.math

    func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge {
        switch ageBand {
        case .young:
            return generateCounting(difficulty: difficulty)
        case .middle:
            return generateArithmetic(difficulty: difficulty, ops: [.add, .subtract])
        case .older:
            return generateArithmetic(difficulty: difficulty, ops: [.add, .subtract, .multiply, .divide])
        }
    }

    private func generateCounting(difficulty: Int) -> MathChallenge {
        let count = min(difficulty + 2, 10)  // 3-10 objects
        let correct = count
        let wrong = generateWrongAnswers(correct: correct, count: 2, range: 1...10)

        return MathChallenge(
            ageBand: .young,
            difficulty: difficulty,
            instruction: "Count the stars!",
            voicePrompt: "Count the stars!",
            hintText: "Try pointing to each star as you count.",
            expression: "\(count) stars",
            correctAnswer: correct,
            allAnswers: (wrong + [correct]).shuffled()
        )
    }

    private func generateArithmetic(
        difficulty: Int,
        ops: [MathOp]
    ) -> MathChallenge {
        let op = ops.randomElement()!
        let (a, b, result) = op.generate(difficulty: difficulty)
        let expression = "\(a) \(op.symbol) \(b) = ?"
        let wrong = generateWrongAnswers(correct: result, count: 3, range: max(0, result - 20)...result + 20)

        return MathChallenge(
            ageBand: difficulty <= 5 ? .middle : .older,
            difficulty: difficulty,
            instruction: "Solve it!",
            voicePrompt: nil,
            hintText: op.hint(a: a, b: b),
            expression: expression,
            correctAnswer: result,
            allAnswers: (wrong + [result]).shuffled()
        )
    }

    /// Generate plausible wrong answers (within ±20%, no duplicates, no negatives)
    private func generateWrongAnswers(correct: Int, count: Int, range: ClosedRange<Int>) -> [Int] {
        var wrongs = Set<Int>()
        while wrongs.count < count {
            let candidate = Int.random(in: range)
            if candidate != correct && candidate >= 0 {
                wrongs.insert(candidate)
            }
        }
        return Array(wrongs)
    }
}

private enum MathOp {
    case add, subtract, multiply, divide

    var symbol: String {
        switch self {
        case .add: "+"
        case .subtract: "−"
        case .multiply: "×"
        case .divide: "÷"
        }
    }

    func generate(difficulty: Int) -> (Int, Int, Int) {
        switch self {
        case .add:
            let a = Int.random(in: 1...(difficulty * 10))
            let b = Int.random(in: 1...(difficulty * 10))
            return (a, b, a + b)
        case .subtract:
            let b = Int.random(in: 1...(difficulty * 5))
            let result = Int.random(in: 0...(difficulty * 5))
            return (result + b, b, result)             // ensures non-negative result
        case .multiply:
            let a = Int.random(in: 2...(difficulty + 2))
            let b = Int.random(in: 2...(difficulty + 2))
            return (a, b, a * b)
        case .divide:
            let b = Int.random(in: 2...(difficulty + 2))
            let result = Int.random(in: 1...(difficulty + 2))
            return (result * b, b, result)             // ensures clean division
        }
    }

    func hint(a: Int, b: Int) -> String {
        switch self {
        case .add: "Try breaking it down: \(a) + \(b / 2) = \(a + b / 2), then add \(b - b / 2)."
        case .subtract: "Start at \(a) and count back \(b)."
        case .multiply: "Think of it as \(a) groups of \(b)."
        case .divide: "How many groups of \(b) fit in \(a)?"
        }
    }
}
```

### 4.3 Challenge Engine (Coordinator)

```swift
final class ChallengeEngine {
    static let shared = ChallengeEngine()

    private let generators: [ChallengeType: ChallengeGenerator] = [
        .math: MathChallengeGenerator(),
        .pattern: PatternChallengeGenerator(),
        .memory: MemoryChallengeGenerator(),
        .puzzle: PuzzleChallengeGenerator(),
    ]

    /// Generate a random challenge appropriate for the given child
    func generateChallenge(for profile: ChildProfile) -> any Challenge {
        let type = ChallengeType.allCases.randomElement()!
        let difficulty = effectiveDifficulty(for: profile)
        return generators[type]!.generate(ageBand: profile.ageBand, difficulty: difficulty)
    }

    /// Generate a challenge of a specific type
    func generateChallenge(
        type: ChallengeType,
        for profile: ChildProfile
    ) -> any Challenge {
        let difficulty = effectiveDifficulty(for: profile)
        return generators[type]!.generate(ageBand: profile.ageBand, difficulty: difficulty)
    }

    private func effectiveDifficulty(for profile: ChildProfile) -> Int {
        switch profile.difficultyOverride {
        case .auto:
            // Scale 1-10 based on age within band
            switch profile.ageBand {
            case .young:  return max(1, min(10, (profile.age - 2) * 3))
            case .middle: return max(1, min(10, (profile.age - 5) * 3))
            case .older:  return max(1, min(10, (profile.age - 8) * 3))
            }
        case .easy: return 3
        case .medium: return 5
        case .hard: return 8
        }
    }
}
```

### 4.4 Adding a New Challenge Type (Example)

To add a new challenge type (e.g., `wordScramble` in v2):

1. Add case to `ChallengeType` enum
2. Create `WordScrambleChallenge` conforming to `Challenge` (or `MultipleChoiceChallenge`)
3. Create `WordScrambleChallengeGenerator` conforming to `ChallengeGenerator`
4. Register in `ChallengeEngine.generators` dictionary
5. Create `WordScrambleChallengeView` in Views/Challenges/
6. Add case to `ChallengeContainerView`'s switch

No existing code needs modification. This is the strength of protocol-based design.

---

## 5. Local Storage Architecture

### 5.1 SwiftData (Primary Persistence)

All child profiles, challenge sessions, and results are stored in SwiftData with an App Group container (see §2.2). This enables:

- **Offline-first operation:** Challenges generate and record locally without network.
- **Extension data sharing:** DeviceActivityMonitor extension reads child profiles from the same store.
- **Background sync:** `SyncQueue` marks records as `synced: false`, background task uploads to Supabase.

### 5.2 UserDefaults (via App Groups)

Lightweight flags and settings shared between app and extensions:

```swift
// Shared UserDefaults keys
enum SharedDefaults {
    static let suiteName = "group.com.childlock.shared"

    enum Key {
        static let challengePending = "challengePending"
        static let activeProfileID = "activeProfileID"
        static let lastSubscriptionCheck = "lastSubscriptionCheck"
        static let subscriptionActive = "subscriptionActive"
    }

    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }
}
```

### 5.3 Keychain (Security-Sensitive Data)

- Parent PIN hash (bcrypt or SHA-256 + salt)
- Supabase auth tokens
- RevenueCat user ID

```swift
import Security

enum KeychainService {
    static func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary) // Remove existing
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else {
            return nil
        }
        return result as? Data
    }
}
```

### 5.4 Offline Sync Queue

```swift
final class SyncQueue {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Enqueue a session for background sync
    func enqueue(_ session: ChallengeSession) {
        session.synced = false
    }

    /// Push all unsynced sessions to Supabase
    func syncPending() async throws {
        let predicate = #Predicate<ChallengeSession> { !$0.synced }
        let unsynced = try context.fetch(FetchDescriptor(predicate: predicate))

        for session in unsynced {
            try await DataSyncService.shared.upload(session)
            session.synced = true
        }
        try context.save()
    }
}
```

Background sync is triggered via `BGAppRefreshTask` (registered in `ChildlockApp.swift`):

```swift
import BackgroundTasks

// Register in app init
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.childlock.sync",
    using: nil
) { task in
    Task {
        let queue = SyncQueue(context: PersistenceController.shared.container.mainContext)
        try? await queue.syncPending()
        task.setTaskCompleted(success: true)
    }
}
```

---

## 6. Networking

### 6.1 Scope (MVP)

Networking is **minimal and non-blocking**. The core challenge loop works entirely offline. Network is used for:

| Use Case | Frequency | Critical? |
|----------|-----------|-----------|
| Supabase Auth (Apple Sign In) | Once (onboarding) | Yes — blocks onboarding |
| Usage data sync (child → parent dashboard) | Background, batched | No — graceful degradation |
| Subscription validation (RevenueCat) | On app launch, cached 7 days | No — cached grace period |
| Push notification registration | Once | No — nice-to-have |

### 6.2 Supabase Client

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://xxxxx.supabase.co")!,
    supabaseKey: "eyJ..."  // anon key — safe to embed, RLS enforced
)

// Auth with Apple
func signInWithApple(idToken: String, nonce: String) async throws {
    try await supabase.auth.signInWithIdToken(
        credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
    )
}
```

### 6.3 Data Sync Service

```swift
final class DataSyncService {
    static let shared = DataSyncService()

    func upload(_ session: ChallengeSession) async throws {
        let payload: [String: AnyJSON] = [
            "child_profile_id": .string(session.child?.id.uuidString ?? ""),
            "age_band": .string(session.child?.ageBand.rawValue ?? ""),
            "date": .string(ISO8601DateFormatter().string(from: session.date)),
            "screen_time_seconds": .integer(session.screenTimeSeconds),
            "challenges_presented": .integer(session.challengesPresented),
            "challenges_completed": .integer(session.challengesCompleted),
            "avg_solve_time_seconds": .double(avgSolveTime(session)),
            "challenge_breakdown": .object(breakdown(session)),
        ]

        try await supabase
            .from("usage_sessions")
            .insert(payload)
            .execute()
    }
}
```

---

## 7. State Management

### 7.1 Architecture Pattern: Observable + Combine

SwiftUI's `@Observable` macro (iOS 17+) replaces the need for a separate state management library. Each ViewModel is an `@Observable` class that owns its state and exposes it directly to views.

```swift
// MARK: - App State (Global, singleton)

@Observable
final class AppState {
    static let shared = AppState()

    var isAuthenticated = false
    var hasCompletedOnboarding = false
    var currentTab: Tab = .home
    var isPINLocked = true                // Settings tab requires PIN
    var activeChallenge: (any Challenge)? // Non-nil when challenge is in progress

    enum Tab: Int {
        case home, children, apps, settings
    }
}

// MARK: - Dashboard ViewModel

@Observable
final class DashboardViewModel {
    var todaySummary: DailySummary?
    var children: [ChildProfile] = []
    var recentActivity: [ChallengeResult] = []
    var isLoading = false

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadDashboard() {
        let today = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<ChallengeSession> { $0.date >= today }
        let sessions = (try? context.fetch(FetchDescriptor(predicate: predicate))) ?? []

        todaySummary = DailySummary(
            challengesPresented: sessions.reduce(0) { $0 + $1.challengesPresented },
            challengesCompleted: sessions.reduce(0) { $0 + $1.challengesCompleted },
            screenTimeSeconds: sessions.reduce(0) { $0 + $1.screenTimeSeconds }
        )

        children = (try? context.fetch(FetchDescriptor<ChildProfile>())) ?? []

        recentActivity = sessions
            .flatMap(\.results)
            .sorted { $0.presentedAt > $1.presentedAt }
    }
}

struct DailySummary {
    let challengesPresented: Int
    let challengesCompleted: Int
    let screenTimeSeconds: Int

    var accuracy: Double {
        guard challengesPresented > 0 else { return 0 }
        return Double(challengesCompleted) / Double(challengesPresented)
    }

    var screenTimeFormatted: String {
        let hours = screenTimeSeconds / 3600
        let minutes = (screenTimeSeconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
```

### 7.2 Challenge ViewModel

```swift
@Observable
final class ChallengeViewModel {
    var challenge: (any Challenge)?
    var state: ChallengeState = .presenting
    var attempts = 0
    var hintVisible = false
    var selectedAnswer: Int?
    var startTime: Date?

    enum ChallengeState {
        case presenting       // Challenge is visible
        case correct          // Answered correctly, showing celebration
        case incorrect        // Just answered wrong, showing feedback
        case completed        // Celebration done, unlocking
    }

    private let engine = ChallengeEngine.shared
    private let screenTime = ScreenTimeManager.shared
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func presentChallenge(for profile: ChildProfile) {
        challenge = engine.generateChallenge(for: profile)
        state = .presenting
        attempts = 0
        hintVisible = false
        startTime = Date()
    }

    func submitAnswer<T: Equatable>(selected: T, correct: T) {
        attempts += 1
        if selected == correct {
            state = .correct
            recordResult(completed: true)

            // After celebration delay, unlock
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.state = .completed
                self?.screenTime.removeShields()
                SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)
            }
        } else {
            state = .incorrect
            if attempts >= 2 {
                hintVisible = true
            }
            // Reset to presenting after brief feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state = .presenting
            }
        }
    }

    private func recordResult(completed: Bool) {
        guard let challenge else { return }
        let result = ChallengeResult(
            id: UUID(),
            type: challenge.type,
            difficultyLevel: challenge.difficulty,
            presentedAt: startTime ?? Date(),
            completedAt: completed ? Date() : nil,
            attempts: attempts,
            completed: completed,
            hintUsed: hintVisible
        )
        // Insert into today's session (or create one)
        // ... (session management logic)
        try? context.save()
    }
}
```

### 7.3 Data Flow Diagram

```
View (SwiftUI)
  │  @State, user interactions
  ▼
ViewModel (@Observable)
  │  Business logic, state mutations
  ├──▶ ChallengeEngine (pure logic, no side effects)
  ├──▶ ScreenTimeManager (shield/unshield side effects)
  ├──▶ SwiftData ModelContext (persistence)
  └──▶ SyncQueue → Supabase (background, non-blocking)
```

---

## 8. Security

### 8.1 Parent Authentication

| Layer | Mechanism |
|-------|-----------|
| **App login** | Apple Sign In → Supabase Auth (JWT token, stored in Keychain) |
| **Settings protection** | 4-digit PIN, hashed with SHA-256 + device-unique salt, stored in Keychain |
| **PIN session** | Cached for current app session; expires after 5 minutes in background |
| **Subscription** | Validated by RevenueCat (server-side receipt validation) |

```swift
final class PINService {
    static let shared = PINService()

    private let keychainKey = "com.childlock.pin"
    private var sessionUnlocked = false
    private var lastUnlockTime: Date?

    func setPIN(_ pin: String) {
        let salt = UUID().uuidString
        let hash = SHA256.hash(data: Data((pin + salt).utf8))
        let stored = PINStorage(hash: hash.description, salt: salt)
        let data = try! JSONEncoder().encode(stored)
        KeychainService.save(key: keychainKey, data: data)
    }

    func verify(_ pin: String) -> Bool {
        guard let data = KeychainService.load(key: keychainKey),
              let stored = try? JSONDecoder().decode(PINStorage.self, from: data) else {
            return false
        }
        let hash = SHA256.hash(data: Data((pin + stored.salt).utf8))
        let matches = hash.description == stored.hash
        if matches {
            sessionUnlocked = true
            lastUnlockTime = Date()
        }
        return matches
    }

    var isSessionUnlocked: Bool {
        guard sessionUnlocked, let lastUnlock = lastUnlockTime else { return false }
        // Expire after 5 minutes in background
        return Date().timeIntervalSince(lastUnlock) < 300
    }

    func lockSession() {
        sessionUnlocked = false
        lastUnlockTime = nil
    }
}

private struct PINStorage: Codable {
    let hash: String
    let salt: String
}
```

### 8.2 Child-Proofing

| Vector | Protection |
|--------|-----------|
| Dismiss challenge | No close button, no swipe-to-dismiss, no back button. Challenge is presented in a `.fullScreenCover` with `interactiveDismissDisabled(true)`. |
| Force-quit monitored app | `ManagedSettingsStore` persists shields across process lifecycle. Shield reactivates on next launch. |
| Restart device | `ManagedSettingsStore` survives reboot. Shield state is persisted to disk by iOS. |
| Delete companion app | Shield is managed by extensions registered via MDM-like profile. Extensions persist independently. |
| Access parent settings | PIN-protected. 4-digit PIN with session expiry. |
| Change system time | `DeviceActivityMonitor` uses system uptime, not wall clock. Cannot be bypassed by changing time. |

### 8.3 COPPA Compliance

| Requirement | Implementation |
|------------|---------------|
| No child accounts | Children have local profiles only — no Supabase account, no auth identity |
| No child PII on server | Names stored locally only. Server receives `child_profile_id` (UUID) and `age_band` (string) — no name, no age, no avatar |
| Parent consent | Apple Family Sharing acts as verified parent-child relationship (Apple's built-in parental consent) |
| Data minimization | Only aggregated usage stats are synced. Individual challenge content is not uploaded. |
| Deletion | Parent can delete child profile → all local data deleted. Server data deleted via Supabase cascade on account deletion. |

### 8.4 Data at Rest

- SwiftData store: encrypted by iOS Data Protection (default `NSFileProtectionCompleteUntilFirstUserAuthentication`)
- Keychain items: `kSecAttrAccessibleAfterFirstUnlock`
- No sensitive data in UserDefaults (only flags and non-sensitive settings)

---

## 9. Testing Strategy

### 9.1 Unit Tests

| Module | Coverage Target | Key Tests |
|--------|----------------|-----------|
| ChallengeEngine | 95% | Correct answer is always in options. No duplicate answers. No negative results for young/middle age bands. Difficulty scaling. |
| MathChallengeGenerator | 95% | All operations produce valid results. Wrong answers are plausible (within range). Division always clean. |
| PatternChallengeGenerator | 95% | Patterns are solvable. Correct answer follows the rule. |
| MemoryChallengeGenerator | 90% | Grid has correct pair count. All pairs are unique. |
| PINService | 100% | Hash + verify round-trip. Session expiry after 5 minutes. Wrong PIN rejected. |
| SyncQueue | 90% | Unsynced sessions found. Synced flag set after upload. |
| ChildProfile model | 90% | Age band calculation. Difficulty override logic. |

```swift
import Testing
@testable import Childlock

@Suite("Math Challenge Generator")
struct MathChallengeGeneratorTests {

    let generator = MathChallengeGenerator()

    @Test("Counting challenge for young age band")
    func countingChallenge() {
        let challenge = generator.generate(ageBand: .young, difficulty: 3)
            as! MathChallenge
        #expect(challenge.ageBand == .young)
        #expect(challenge.allAnswers.contains(challenge.correctAnswer))
        #expect(challenge.allAnswers.count == 3)  // 2 wrong + 1 correct
        #expect(challenge.correctAnswer > 0)
        #expect(challenge.correctAnswer <= 10)
        #expect(Set(challenge.allAnswers).count == challenge.allAnswers.count) // no dupes
    }

    @Test("Arithmetic never produces negatives for middle band")
    func noNegativeResults() {
        for _ in 0..<100 {
            let challenge = generator.generate(ageBand: .middle, difficulty: 5)
                as! MathChallenge
            #expect(challenge.correctAnswer >= 0)
            #expect(challenge.allAnswers.allSatisfy { $0 >= 0 })
        }
    }

    @Test("Wrong answers are plausible (within 20%)")
    func plausibleDistracters() {
        for _ in 0..<50 {
            let challenge = generator.generate(ageBand: .older, difficulty: 7)
                as! MathChallenge
            let correct = challenge.correctAnswer
            for answer in challenge.allAnswers where answer != correct {
                let range = max(1, correct - 20)...(correct + 20)
                #expect(range.contains(answer))
            }
        }
    }

    @Test("Four answer options for middle and older bands")
    func fourOptions() {
        let middle = generator.generate(ageBand: .middle, difficulty: 5) as! MathChallenge
        #expect(middle.allAnswers.count == 4)
        let older = generator.generate(ageBand: .older, difficulty: 8) as! MathChallenge
        #expect(older.allAnswers.count == 4)
    }
}
```

### 9.2 Integration Tests

| Scenario | What's Tested |
|----------|-------------|
| Onboarding flow | Family Sharing auth → child profile creation → app selection → interval set → PIN set → dashboard |
| Challenge lifecycle | Challenge generated → presented → solved → result saved → shield removed |
| Free tier limit | 3 challenges completed → 4th triggers paywall |
| Offline mode | Challenge works without network. Data queued. Sync on reconnect. |
| PIN lockout | Settings tab requires PIN. Wrong PIN rejected. Session expires. |

### 9.3 UI Tests

```swift
import XCTest

final class ChallengeFlowUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting", "--skip-onboarding"]
        app.launch()
    }

    func testMathChallengeCompletion() throws {
        // Trigger a test challenge
        app.buttons["Debug: Trigger Challenge"].tap()

        // Verify challenge screen
        XCTAssertTrue(app.staticTexts["Brain Break!"].exists)

        // Tap the correct answer (in test mode, correct answer is always first)
        app.buttons["answer_correct"].tap()

        // Verify celebration
        XCTAssertTrue(app.staticTexts["Awesome!"].waitForExistence(timeout: 2))

        // Verify returns to normal (celebration auto-dismisses)
        XCTAssertFalse(app.staticTexts["Brain Break!"].waitForExistence(timeout: 4))
    }

    func testChallengeCannotBeDismissed() throws {
        app.buttons["Debug: Trigger Challenge"].tap()
        XCTAssertTrue(app.staticTexts["Brain Break!"].exists)

        // Attempt swipe down to dismiss
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["Brain Break!"].exists) // Still there

        // No close button exists
        XCTAssertFalse(app.buttons["Close"].exists)
        XCTAssertFalse(app.buttons["Skip"].exists)
    }

    func testHintAppearsAfterTwoWrongAnswers() throws {
        app.buttons["Debug: Trigger Challenge"].tap()

        app.buttons["answer_wrong_1"].tap()
        XCTAssertTrue(app.staticTexts["Almost! Try again!"].waitForExistence(timeout: 1))

        app.buttons["answer_wrong_2"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Hint:'")).firstMatch
            .waitForExistence(timeout: 1))
    }
}
```

### 9.4 Screen Time API Tests

The Screen Time API cannot be unit tested in a simulator — it requires a physical device with Family Sharing configured. Testing approach:

1. **Manual test plan** (documented checklist, run before each release):
   - Authorization flow (parent grants access)
   - App selection via FamilyActivityPicker
   - Shield applies after interval
   - Shield persists after force-quit
   - Shield persists after reboot
   - Shield removes after challenge completion
   - Timer resets after challenge
   - Multiple child profiles work independently

2. **Mocked ScreenTimeManager** for unit/UI tests:

```swift
#if DEBUG
final class MockScreenTimeManager: ScreenTimeManager {
    var shieldsApplied = false
    var shieldsRemoved = false

    override func applyShields(for profile: ChildProfile) {
        shieldsApplied = true
    }

    override func removeShields() {
        shieldsRemoved = true
        shieldsApplied = false
    }
}
#endif
```

### 9.5 Test Matrix

| Test Type | Runner | CI? | Device |
|-----------|--------|-----|--------|
| Unit tests (models, engine) | Swift Testing | Yes (GitHub Actions) | Simulator |
| UI tests (flows, interactions) | XCTest UI | Yes (GitHub Actions) | Simulator |
| Screen Time integration | Manual checklist | No | Physical device + Family Sharing |
| Performance (challenge load <500ms) | XCTest metrics | Yes | Simulator |
| Accessibility audit | Xcode Accessibility Inspector | Pre-release | Simulator + device |

---

## 10. Week 1 Technical Spike Plan

### Goal

Validate that the Screen Time API can deliver the core Childlock UX: monitor app usage → shield apps at interval → present challenge → remove shield on completion.

### Day 1-2: Project Setup + FamilyControls Authorization

**Tasks:**
- [ ] Create Xcode project with SwiftUI lifecycle
- [ ] Add required entitlements: `com.apple.developer.family-controls`
- [ ] Configure App Group: `group.com.childlock.shared`
- [ ] Create three extension targets (DeviceActivityMonitor, ShieldConfiguration, ShieldAction)
- [ ] Implement `AuthorizationCenter.requestAuthorization(for: .child)`
- [ ] Test on physical device with two Apple IDs (parent + child in Family Sharing)

**Success criteria:** App can request and receive Family Sharing authorization on a physical device.

**Risk:** Apple's entitlement approval may take time. Apply for the `Family Controls` capability in the Apple Developer portal immediately.

### Day 3: App Selection + Shielding

**Tasks:**
- [ ] Embed `FamilyActivityPicker` in a SwiftUI view
- [ ] Store selected activity tokens in App Group UserDefaults
- [ ] Apply shield to selected apps via `ManagedSettingsStore`
- [ ] Verify shield appears on child's device
- [ ] Test shield persistence: force-quit, reboot, app deletion

**Success criteria:** Selected apps on child's device show Apple's default shield overlay.

### Day 4: DeviceActivityMonitor + Timed Shield

**Tasks:**
- [ ] Configure `DeviceActivitySchedule` with a short interval (2 minutes for testing)
- [ ] Implement `eventDidReachThreshold` in the monitor extension
- [ ] On threshold: apply shields via `ManagedSettingsStore`
- [ ] Verify the monitor fires at the configured interval
- [ ] Test: does the timer reset when shield is removed?

**Success criteria:** After 2 minutes of using a monitored app, the shield activates automatically.

### Day 5: Shield → Challenge → Unshield Flow

**Tasks:**
- [ ] Customize `ShieldConfiguration` with Childlock branding ("Brain Break!")
- [ ] Implement `ShieldAction` to open the main app on primary button tap
- [ ] Main app detects `challengePending` flag → presents a hardcoded math challenge
- [ ] On correct answer → `ManagedSettingsStore` removes shield
- [ ] Full end-to-end test: use app → 2min → shield → tap → challenge → solve → app resumes

**Success criteria:** Complete flow works on a physical device. The child can solve a challenge and return to their app.

### Spike Deliverables

| Deliverable | Due |
|------------|-----|
| Working prototype on physical device (video recording of full flow) | End of Day 5 |
| Technical findings document: what works, what doesn't, API limitations discovered | End of Day 5 |
| Go/no-go recommendation for ShieldConfiguration UI richness (can we render challenges inline or must we redirect to app?) | End of Day 5 |
| Updated risk assessment based on hands-on API experience | End of Day 5 |

### Spike Risks & Contingencies

| Risk | Contingency |
|------|------------|
| Family Controls entitlement not approved in time | Use Apple's sample code project which already has the entitlement. Or contact Apple Developer Technical Support. |
| DeviceActivityMonitor doesn't fire reliably | Try alternative: `DeviceActivitySchedule` with `warningTime` parameter. Or use local notifications as backup trigger. |
| ShieldConfiguration too limited for any useful UI | Redirect to main app for all challenge UI. Accept the extra tap in the flow. |
| Shield removal doesn't work from main app | Try removing shield from the ShieldAction extension instead. Or use `ManagedSettingsStore.clearAllSettings()`. |

---

## Appendix A: Xcode Project Configuration

### Targets

| Target | Type | Bundle ID |
|--------|------|-----------|
| Childlock | App | com.childlock.app |
| ChildlockMonitor | DeviceActivityMonitor Extension | com.childlock.app.monitor |
| ChildlockShieldConfig | ShieldConfiguration Extension | com.childlock.app.shield-config |
| ChildlockShieldAction | ShieldAction Extension | com.childlock.app.shield-action |

### Capabilities

| Capability | Target | Notes |
|-----------|--------|-------|
| Family Controls | All targets | Requires Apple Developer approval |
| App Groups | All targets | `group.com.childlock.shared` |
| Sign in with Apple | App only | For Supabase Auth |
| Background Modes | App only | Background fetch (data sync) |
| Push Notifications | App only | Daily summary, alerts |

### Dependencies (Swift Package Manager)

| Package | Version | Purpose |
|---------|---------|---------|
| supabase-swift | ~> 2.0 | Auth + database + realtime |
| RevenueCat/purchases-ios | ~> 5.0 | Subscription management |
| PostHog/posthog-ios | ~> 3.0 | Analytics (COPPA-configured) |

### Minimum Deployment Target

**iOS 17.0** — required for SwiftData + stable DeviceActivityMonitor.

---

## Appendix B: API Rate Limits & Performance Budgets

| Metric | Budget | Measured By |
|--------|--------|-------------|
| Challenge generation | <50ms | XCTest performance metric |
| Challenge UI render | <200ms | Time-to-interactive from view appear |
| Total challenge load (generation + render) | <500ms | End-to-end, per PRD guardrail |
| Shield activation latency | <2s after interval | DeviceActivityMonitor → shield visible |
| Background sync (per session) | <1s network time | Supabase insert round-trip |
| App launch to dashboard | <1.5s | Cold start on iPhone 12 |
| App bundle size | <30MB | Xcode archive |

---

## Appendix C: Environment & Build Configuration

```swift
// Configuration.swift — environment-specific values
enum Configuration {
    enum Environment {
        case debug
        case staging
        case production
    }

    static var current: Environment {
        #if DEBUG
        return .debug
        #else
        if Bundle.main.bundleIdentifier?.contains("staging") == true {
            return .staging
        }
        return .production
        #endif
    }

    static var supabaseURL: URL {
        switch current {
        case .debug, .staging:
            return URL(string: "https://xxxx-staging.supabase.co")!
        case .production:
            return URL(string: "https://xxxx.supabase.co")!
        }
    }

    static var revenueCatAPIKey: String {
        switch current {
        case .debug, .staging: return "appl_staging_xxxx"
        case .production: return "appl_xxxx"
        }
    }

    static var posthogAPIKey: String {
        switch current {
        case .debug: return "" // disabled
        case .staging: return "phc_staging_xxxx"
        case .production: return "phc_xxxx"
        }
    }
}
```

---

*This technical specification should be read alongside `prd.md` v1.0 and `design-spec.md` v1.0. Implementation begins with the Week 1 spike (§10) to validate Screen Time API feasibility before committing to the full build.*
