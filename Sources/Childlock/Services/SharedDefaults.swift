import Foundation

public struct ShieldBrainBreakState: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case question
        case retry
        case success
    }

    public var id: UUID
    public var profileID: UUID?
    public var prompt: String
    public var primaryAnswer: String
    public var secondaryAnswer: String
    public var correctAnswerIndex: Int
    public var attempts: Int
    public var difficultyLevel: Int
    public var presentedAt: Date
    public var phase: Phase

    public init(
        id: UUID = UUID(),
        profileID: UUID?,
        prompt: String,
        primaryAnswer: String,
        secondaryAnswer: String,
        correctAnswerIndex: Int,
        attempts: Int = 0,
        difficultyLevel: Int,
        presentedAt: Date = Date(),
        phase: Phase = .question
    ) {
        self.id = id
        self.profileID = profileID
        self.prompt = prompt
        self.primaryAnswer = primaryAnswer
        self.secondaryAnswer = secondaryAnswer
        self.correctAnswerIndex = correctAnswerIndex
        self.attempts = attempts
        self.difficultyLevel = difficultyLevel
        self.presentedAt = presentedAt
        self.phase = phase
    }

    public static func make(
        profileID: UUID?,
        age: Int,
        difficultyLevel: Int,
        presentedAt: Date = Date()
    ) -> ShieldBrainBreakState {
        let operandLimit: Int
        switch age {
        case ...5:
            operandLimit = 5
        case 6...8:
            operandLimit = 10
        default:
            operandLimit = 12
        }

        let left = Int.random(in: 1...operandLimit)
        let right = Int.random(in: 1...operandLimit)
        let correct = left + right
        let offset = Bool.random() ? 1 : -1
        let alternate = max(0, correct + offset)
        let correctFirst = Bool.random()

        return ShieldBrainBreakState(
            profileID: profileID,
            prompt: "What is \(left) + \(right)?",
            primaryAnswer: String(correctFirst ? correct : alternate),
            secondaryAnswer: String(correctFirst ? alternate : correct),
            correctAnswerIndex: correctFirst ? 0 : 1,
            difficultyLevel: max(1, min(difficultyLevel, 10)),
            presentedAt: presentedAt
        )
    }

    @discardableResult
    public mutating func submit(answerIndex: Int) -> Bool {
        guard phase != .success else { return true }

        attempts += 1
        let isCorrect = answerIndex == correctAnswerIndex
        phase = isCorrect ? .success : .retry
        return isCorrect
    }
}

public struct ShieldBrainBreakCompletion: Codable, Equatable, Sendable {
    public var id: UUID
    public var profileID: UUID?
    public var presentedAt: Date
    public var completedAt: Date
    public var attempts: Int
    public var difficultyLevel: Int

    public init(
        id: UUID,
        profileID: UUID?,
        presentedAt: Date,
        completedAt: Date,
        attempts: Int,
        difficultyLevel: Int
    ) {
        self.id = id
        self.profileID = profileID
        self.presentedAt = presentedAt
        self.completedAt = completedAt
        self.attempts = attempts
        self.difficultyLevel = difficultyLevel
    }

    public init(state: ShieldBrainBreakState, completedAt: Date = Date()) {
        self.init(
            id: state.id,
            profileID: state.profileID,
            presentedAt: state.presentedAt,
            completedAt: completedAt,
            attempts: state.attempts,
            difficultyLevel: state.difficultyLevel
        )
    }
}

public enum SharedDefaults {
    public static let suiteName = "group.com.childlock.shared"

    public enum Key {
        public static let appStateSnapshot = "appStateSnapshot"
        public static let challengePending = "challengePending"
        public static let activeProfileID = "activeProfileID"
        public static let lastSubscriptionCheck = "lastSubscriptionCheck"
        public static let subscriptionActive = "subscriptionActive"
        public static let familyActivitySelection = "familyActivitySelection"
        public static let activeMonitoringProfileID = "activeMonitoringProfileID"
        public static let activeMonitoringSelectionData = "activeMonitoringSelectionData"
        public static let activeMonitoringIntervalMinutes = "activeMonitoringIntervalMinutes"
        public static let activeMonitoringProfileAge = "activeMonitoringProfileAge"
        public static let activeMonitoringDifficultyLevel = "activeMonitoringDifficultyLevel"
        public static let monitoringStatus = "monitoringStatus"
        public static let monitoringLastError = "monitoringLastError"
        public static let monitoringLastStartedAt = "monitoringLastStartedAt"
        public static let moreTimeRequestCount = "moreTimeRequestCount"
        public static let lastMoreTimeRequestDate = "lastMoreTimeRequestDate"
        public static let dailyLimitReachedAt = "dailyLimitReachedAt"
        public static let challengeAlertsEnabled = "challengeAlertsEnabled"
        public static let shieldBrainBreakState = "shieldBrainBreakState"
        public static let pendingShieldBrainBreakCompletions = "pendingShieldBrainBreakCompletions"
    }

    public enum NotificationIdentifier {
        public static let brainBreak = "childlock_brain_break"
        public static let moreTimeRequest = "childlock_more_time_request"
        public static let dailySummary = "daily_summary"
    }

    public static let localSetupStateKeys = [
        Key.appStateSnapshot,
        Key.challengePending,
        Key.activeProfileID,
        Key.lastSubscriptionCheck,
        Key.subscriptionActive,
        Key.familyActivitySelection,
        Key.activeMonitoringProfileID,
        Key.activeMonitoringSelectionData,
        Key.activeMonitoringIntervalMinutes,
        Key.activeMonitoringProfileAge,
        Key.activeMonitoringDifficultyLevel,
        Key.monitoringStatus,
        Key.monitoringLastError,
        Key.monitoringLastStartedAt,
        Key.moreTimeRequestCount,
        Key.lastMoreTimeRequestDate,
        Key.dailyLimitReachedAt,
        Key.challengeAlertsEnabled,
        Key.shieldBrainBreakState,
        Key.pendingShieldBrainBreakCompletions,
    ]

    public static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public static func clearLocalSetupState(defaults: UserDefaults = shared) {
        localSetupStateKeys.forEach { defaults.removeObject(forKey: $0) }
    }

    public static func shieldBrainBreak(defaults: UserDefaults = shared) -> ShieldBrainBreakState? {
        guard let data = defaults.data(forKey: Key.shieldBrainBreakState) else {
            return nil
        }
        return try? JSONDecoder().decode(ShieldBrainBreakState.self, from: data)
    }

    public static func saveShieldBrainBreak(
        _ state: ShieldBrainBreakState,
        defaults: UserDefaults = shared
    ) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Key.shieldBrainBreakState)
    }

    public static func clearShieldBrainBreak(defaults: UserDefaults = shared) {
        defaults.removeObject(forKey: Key.shieldBrainBreakState)
    }

    public static func pendingShieldBrainBreakCompletions(
        defaults: UserDefaults = shared
    ) -> [ShieldBrainBreakCompletion] {
        guard
            let data = defaults.data(forKey: Key.pendingShieldBrainBreakCompletions),
            let completions = try? JSONDecoder().decode([ShieldBrainBreakCompletion].self, from: data)
        else {
            return []
        }
        return completions
    }

    public static func appendShieldBrainBreakCompletion(
        _ completion: ShieldBrainBreakCompletion,
        defaults: UserDefaults = shared
    ) {
        var completions = pendingShieldBrainBreakCompletions(defaults: defaults)
        guard !completions.contains(where: { $0.id == completion.id }) else { return }
        completions.append(completion)
        guard let data = try? JSONEncoder().encode(completions) else { return }
        defaults.set(data, forKey: Key.pendingShieldBrainBreakCompletions)
    }

    public static func removeShieldBrainBreakCompletions(
        ids: Set<UUID>,
        defaults: UserDefaults = shared
    ) {
        guard !ids.isEmpty else { return }
        let remaining = pendingShieldBrainBreakCompletions(defaults: defaults)
            .filter { !ids.contains($0.id) }

        guard !remaining.isEmpty else {
            defaults.removeObject(forKey: Key.pendingShieldBrainBreakCompletions)
            return
        }

        guard let data = try? JSONEncoder().encode(remaining) else { return }
        defaults.set(data, forKey: Key.pendingShieldBrainBreakCompletions)
    }

    public static func appGroupStateDirectory(fileManager: FileManager = .default) -> URL {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName) {
            return containerURL
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("ChildlockState", isDirectory: true)
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let fallbackBase = appSupport ?? fileManager.temporaryDirectory
        return fallbackBase.appendingPathComponent("ChildlockState", isDirectory: true)
    }
}
