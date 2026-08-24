import Foundation

public enum ChildlockRapidTesting {
    public static let buildFlagKey = "ChildlockRapidTestingEnabled"
    public static let intervalSeconds = 10

    public static var isBuildEnabled: Bool {
        isEnabled(infoDictionaryValue: Bundle.main.object(forInfoDictionaryKey: buildFlagKey))
    }

    public static func isEnabled(infoDictionaryValue: Any?) -> Bool {
        if let value = infoDictionaryValue as? Bool {
            return value
        }

        guard let value = infoDictionaryValue as? String else {
            return false
        }

        return ["1", "true", "yes"].contains(value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }

    public static func sanitizedIntervalSeconds(_ value: Int?) -> Int? {
        value == intervalSeconds ? intervalSeconds : nil
    }

    public static func threshold(
        intervalMinutes: Int,
        rapidTestIntervalSeconds: Int?
    ) -> DateComponents {
        if let seconds = sanitizedIntervalSeconds(rapidTestIntervalSeconds) {
            return DateComponents(second: seconds)
        }

        return DateComponents(minute: max(intervalMinutes, 1))
    }

    public static func shouldRestartMonitoring(storedStatus: String?) -> Bool {
        storedStatus == "running" || storedStatus == "interval_started"
    }
}

public struct ShieldBrainBreakState: Codable, Equatable, Sendable {
    public enum Phase: String, Codable, Sendable {
        case question
        case retry
        case success
    }

    public enum QuestionKind: String, Codable, CaseIterable, Sendable {
        case counting
        case addition
        case subtraction
        case missingNumber
        case nextNumber
        case comparison
        case alternatingPattern
        case skipCounting
    }

    public enum AnswerOutcome: Equatable, Sendable {
        case retry
        case nextQuestion
        case success
    }

    public static let requiredCorrectAnswers = 2

    public var id: UUID
    public var profileID: UUID?
    public var age: Int
    public var prompt: String
    public var primaryAnswer: String
    public var secondaryAnswer: String
    public var correctAnswerIndex: Int
    public var questionKind: QuestionKind
    public var correctAnswers: Int
    public var requiredAnswers: Int
    public var attempts: Int
    public var difficultyLevel: Int
    public var presentedAt: Date
    public var phase: Phase

    public init(
        id: UUID = UUID(),
        profileID: UUID?,
        age: Int = 5,
        prompt: String,
        primaryAnswer: String,
        secondaryAnswer: String,
        correctAnswerIndex: Int,
        questionKind: QuestionKind = .addition,
        correctAnswers: Int = 0,
        requiredAnswers: Int = ShieldBrainBreakState.requiredCorrectAnswers,
        attempts: Int = 0,
        difficultyLevel: Int,
        presentedAt: Date = Date(),
        phase: Phase = .question
    ) {
        self.id = id
        self.profileID = profileID
        self.age = max(3, min(age, 12))
        self.prompt = prompt
        self.primaryAnswer = primaryAnswer
        self.secondaryAnswer = secondaryAnswer
        self.correctAnswerIndex = correctAnswerIndex
        self.questionKind = questionKind
        self.correctAnswers = max(0, correctAnswers)
        self.requiredAnswers = max(1, requiredAnswers)
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
        var generator = SystemRandomNumberGenerator()
        return make(
            profileID: profileID,
            age: age,
            difficultyLevel: difficultyLevel,
            presentedAt: presentedAt,
            using: &generator
        )
    }

    public static func make<R: RandomNumberGenerator>(
        profileID: UUID?,
        age: Int,
        difficultyLevel: Int,
        presentedAt: Date = Date(),
        using generator: inout R
    ) -> ShieldBrainBreakState {
        let sanitizedAge = max(3, min(age, 12))
        let sanitizedDifficulty = max(1, min(difficultyLevel, 10))
        let question = makeQuestion(
            age: sanitizedAge,
            difficultyLevel: sanitizedDifficulty,
            excluding: nil,
            using: &generator
        )

        return ShieldBrainBreakState(
            profileID: profileID,
            age: sanitizedAge,
            prompt: question.prompt,
            primaryAnswer: question.primaryAnswer,
            secondaryAnswer: question.secondaryAnswer,
            correctAnswerIndex: question.correctAnswerIndex,
            questionKind: question.kind,
            difficultyLevel: sanitizedDifficulty,
            presentedAt: presentedAt
        )
    }

    @discardableResult
    public mutating func submit(answerIndex: Int) -> AnswerOutcome {
        var generator = SystemRandomNumberGenerator()
        return submit(answerIndex: answerIndex, using: &generator)
    }

    @discardableResult
    public mutating func submit<R: RandomNumberGenerator>(
        answerIndex: Int,
        using generator: inout R
    ) -> AnswerOutcome {
        guard phase != .success else { return .success }

        attempts += 1
        let isCorrect = answerIndex == correctAnswerIndex
        if isCorrect {
            correctAnswers += 1
            guard correctAnswers < requiredAnswers else {
                phase = .success
                return .success
            }

            phase = .question
            replaceQuestion(using: &generator)
            return .nextQuestion
        }

        // A miss never reveals that the other button was correct. A fresh
        // question replaces it and resets the short two-question checkpoint.
        correctAnswers = 0
        phase = .retry
        replaceQuestion(using: &generator)
        return .retry
    }

    public var guidanceText: String {
        if phase == .retry {
            return "Almost! Try this one · 1 of \(requiredAnswers)"
        }
        if correctAnswers > 0 {
            return "Nice! One more · \(correctAnswers + 1) of \(requiredAnswers)"
        }
        return "Brain Break · 1 of \(requiredAnswers)"
    }

    private mutating func replaceQuestion<R: RandomNumberGenerator>(using generator: inout R) {
        let question = Self.makeQuestion(
            age: age,
            difficultyLevel: difficultyLevel,
            excluding: questionKind,
            using: &generator
        )
        prompt = question.prompt
        primaryAnswer = question.primaryAnswer
        secondaryAnswer = question.secondaryAnswer
        correctAnswerIndex = question.correctAnswerIndex
        questionKind = question.kind
    }

    private struct GeneratedQuestion {
        let kind: QuestionKind
        let prompt: String
        let primaryAnswer: String
        let secondaryAnswer: String
        let correctAnswerIndex: Int
    }

    private static func makeQuestion<R: RandomNumberGenerator>(
        age: Int,
        difficultyLevel: Int,
        excluding excludedKind: QuestionKind?,
        using generator: inout R
    ) -> GeneratedQuestion {
        let eligibleKinds: [QuestionKind]
        switch age {
        case ...3:
            eligibleKinds = [.counting, .nextNumber, .comparison]
        case 4:
            eligibleKinds = [.counting, .addition, .subtraction, .nextNumber, .alternatingPattern]
        case 5:
            eligibleKinds = [.addition, .subtraction, .missingNumber, .comparison, .alternatingPattern, .skipCounting]
        case 6...8:
            eligibleKinds = [.addition, .subtraction, .missingNumber, .skipCounting]
        default:
            eligibleKinds = [.addition, .subtraction, .missingNumber, .skipCounting]
        }

        let candidates = eligibleKinds.filter { $0 != excludedKind }
        let kind = candidates.randomElement(using: &generator)
            ?? eligibleKinds.randomElement(using: &generator)
            ?? .addition

        let prompt: String
        let correct: Int
        let alternate: Int

        switch kind {
        case .counting:
            let upper = age <= 3 ? 6 : min(10, 7 + difficultyLevel / 3)
            let lower = age <= 3 ? 3 : max(5, upper - 3)
            correct = Int.random(in: lower...upper, using: &generator)
            prompt = "How many stars? " + Array(repeating: "★", count: correct).joined(separator: " ")
            alternate = numericDistractor(for: correct, minimum: 1, maximum: 12, using: &generator)

        case .addition:
            let resultRange: ClosedRange<Int>
            switch age {
            case ...3: resultRange = 3...6
            case 4: resultRange = 5...9
            case 5: resultRange = 7...12
            case 6...8: resultRange = 10...(12 + difficultyLevel * 2)
            default: resultRange = 15...(20 + difficultyLevel * 3)
            }
            correct = Int.random(in: resultRange, using: &generator)
            let left = Int.random(in: 1..<correct, using: &generator)
            let right = correct - left
            prompt = "What is \(left) + \(right)?"
            alternate = numericDistractor(for: correct, minimum: 1, maximum: resultRange.upperBound + 3, using: &generator)

        case .subtraction:
            let upper = age <= 4 ? 9 : age == 5 ? 12 : 12 + difficultyLevel * 2
            let minuend = Int.random(in: max(5, upper - 4)...upper, using: &generator)
            let right = Int.random(in: 1..<minuend, using: &generator)
            correct = minuend - right
            prompt = "What is \(minuend) − \(right)?"
            alternate = numericDistractor(for: correct, minimum: 0, maximum: upper, using: &generator)

        case .missingNumber:
            let upper = age <= 5 ? 12 : 12 + difficultyLevel * 2
            let total = Int.random(in: max(6, upper - 5)...upper, using: &generator)
            correct = Int.random(in: 1..<total, using: &generator)
            let shown = total - correct
            prompt = "\(shown) + ? = \(total)"
            alternate = numericDistractor(for: correct, minimum: 1, maximum: total - 1, using: &generator)

        case .nextNumber:
            let start = Int.random(in: 1...(age <= 3 ? 5 : 8), using: &generator)
            correct = start + 1
            prompt = "What comes after \(start)?"
            alternate = numericDistractor(for: correct, minimum: 1, maximum: 10, using: &generator)

        case .comparison:
            let upper = age <= 3 ? 7 : 12
            let first = Int.random(in: 1...(upper - 2), using: &generator)
            let second = Int.random(in: (first + 2)...upper, using: &generator)
            let showFirstLow = Bool.random(using: &generator)
            let left = showFirstLow ? first : second
            let right = showFirstLow ? second : first
            correct = max(first, second)
            alternate = min(first, second)
            prompt = "Which is bigger: \(left) or \(right)?"

        case .alternatingPattern:
            let first = Int.random(in: 1...7, using: &generator)
            var second = Int.random(in: 1...8, using: &generator)
            if second == first { second = first == 8 ? 7 : first + 1 }
            correct = first
            alternate = second
            prompt = "What comes next? \(first), \(second), \(first), \(second), …"

        case .skipCounting:
            let step = age <= 5 ? 2 : Int.random(in: 2...4, using: &generator)
            let start = Int.random(in: 1...5, using: &generator)
            correct = start + step * 3
            alternate = Bool.random(using: &generator) ? correct - 1 : correct + 1
            prompt = "What comes next? \(start), \(start + step), \(start + step * 2), …"
        }

        return makeQuestion(
            kind: kind,
            prompt: prompt,
            correct: String(correct),
            alternate: String(alternate),
            using: &generator
        )
    }

    private static func makeQuestion<R: RandomNumberGenerator>(
        kind: QuestionKind,
        prompt: String,
        correct: String,
        alternate: String,
        using generator: inout R
    ) -> GeneratedQuestion {
        let correctFirst = Bool.random(using: &generator)
        return GeneratedQuestion(
            kind: kind,
            prompt: prompt,
            primaryAnswer: correctFirst ? correct : alternate,
            secondaryAnswer: correctFirst ? alternate : correct,
            correctAnswerIndex: correctFirst ? 0 : 1
        )
    }

    private static func numericDistractor<R: RandomNumberGenerator>(
        for correct: Int,
        minimum: Int,
        maximum: Int,
        using generator: inout R
    ) -> Int {
        let candidates = [-2, -1, 1, 2]
            .shuffled(using: &generator)
            .map { correct + $0 }
            .filter { $0 >= minimum && $0 <= maximum && $0 != correct }
        return candidates.first ?? (correct == minimum ? correct + 1 : correct - 1)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case profileID
        case age
        case prompt
        case primaryAnswer
        case secondaryAnswer
        case correctAnswerIndex
        case questionKind
        case correctAnswers
        case requiredAnswers
        case attempts
        case difficultyLevel
        case presentedAt
        case phase
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        profileID = try container.decodeIfPresent(UUID.self, forKey: .profileID)
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 5
        prompt = try container.decode(String.self, forKey: .prompt)
        primaryAnswer = try container.decode(String.self, forKey: .primaryAnswer)
        secondaryAnswer = try container.decode(String.self, forKey: .secondaryAnswer)
        correctAnswerIndex = try container.decode(Int.self, forKey: .correctAnswerIndex)
        questionKind = try container.decodeIfPresent(QuestionKind.self, forKey: .questionKind) ?? .addition
        correctAnswers = try container.decodeIfPresent(Int.self, forKey: .correctAnswers) ?? 0
        requiredAnswers = try container.decodeIfPresent(Int.self, forKey: .requiredAnswers)
            ?? Self.requiredCorrectAnswers
        attempts = try container.decode(Int.self, forKey: .attempts)
        difficultyLevel = try container.decode(Int.self, forKey: .difficultyLevel)
        presentedAt = try container.decode(Date.self, forKey: .presentedAt)
        phase = try container.decode(Phase.self, forKey: .phase)
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
        public static let activeMonitoringIntervalSeconds = "activeMonitoringIntervalSeconds"
        public static let activeMonitoringProfileAge = "activeMonitoringProfileAge"
        public static let activeMonitoringDifficultyLevel = "activeMonitoringDifficultyLevel"
        public static let rapidTestIntervalSeconds = "rapidTestIntervalSeconds"
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
        Key.activeMonitoringIntervalSeconds,
        Key.activeMonitoringProfileAge,
        Key.activeMonitoringDifficultyLevel,
        Key.rapidTestIntervalSeconds,
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
