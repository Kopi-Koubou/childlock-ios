import Foundation
import Observation

@MainActor
@Observable
public final class ChallengeViewModel {
    public enum ChallengeState {
        case presenting
        case correct
        case incorrect
        case completed
        case handback
    }

    public private(set) var challenge: (any Challenge)?
    public private(set) var state: ChallengeState = .presenting
    public private(set) var attempts = 0
    public private(set) var hintVisible = false
    public private(set) var feedbackText: String?
    public private(set) var results: [ChallengeResult] = []
    public private(set) var activeProfile: ChildProfile?

    public var onCompletedResult: ((ChallengeResult) -> Void)?
    /// Asked before re-arming monitoring after a completed challenge.
    /// Return false to stop scheduling further brain breaks (e.g. free daily cap reached).
    public var shouldRearmAfterCompletion: (() -> Bool)?

    public var lastSolveTimeSeconds: Double? {
        results.last?.solveTimeSeconds
    }

    private let engine: ChallengeEngine
    private let screenTime: ScreenTimeManaging
    private let celebrationDuration: TimeInterval
    private let scheduler: @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> Void
    private let clock: () -> Date

    private var startTime: Date?

    public init(
        engine: ChallengeEngine? = nil,
        screenTime: ScreenTimeManaging? = nil,
        celebrationDuration: TimeInterval = 2.0,
        scheduler: @escaping @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> Void = {
            delay, action in
            if delay <= 0 {
                action()
                return
            }

            Task { @MainActor in
                let nanoseconds = UInt64(delay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
                action()
            }
        },
        clock: @escaping () -> Date = Date.init
    ) {
        self.engine = engine ?? .shared
        self.screenTime = screenTime ?? ScreenTimeManager.shared
        self.celebrationDuration = celebrationDuration
        self.scheduler = scheduler
        self.clock = clock
    }

    public func presentChallenge(for profile: ChildProfile, type: ChallengeType? = nil) {
        activeProfile = profile
        if let type {
            challenge = engine.generateChallenge(type: type, for: profile)
        } else {
            challenge = engine.generateChallenge(for: profile)
        }

        state = .presenting
        attempts = 0
        hintVisible = false
        feedbackText = nil
        startTime = clock()
    }

    public func submitMathAnswer(_ selectedAnswer: Int) {
        guard let mathChallenge = challenge as? MathChallenge else { return }
        submitAnswer(selected: selectedAnswer, correct: mathChallenge.correctAnswer)
    }

    public func submitPatternAnswer(_ selectedAnswer: String) {
        guard let patternChallenge = challenge as? PatternChallenge else { return }
        submitAnswer(selected: selectedAnswer, correct: patternChallenge.correctAnswer)
    }

    public func submitPuzzleAnswer(_ selectedAnswer: String) {
        guard let puzzleChallenge = challenge as? PuzzleChallenge else { return }
        submitAnswer(selected: selectedAnswer, correct: puzzleChallenge.correctAnswer)
    }

    public func submitMemoryCompletion() {
        guard challenge is MemoryChallenge else { return }
        guard acceptsChallengeInput else { return }

        attempts += 1
        _ = recordResult(completed: true)
        completeChallenge()
    }

    public func clearChallenge() {
        challenge = nil
        activeProfile = nil
        state = .presenting
        attempts = 0
        hintVisible = false
        feedbackText = nil
        startTime = nil
    }

    #if DEBUG
    public func debugPresentHandBack(for profile: ChildProfile) {
        activeProfile = profile
        challenge = engine.generateChallenge(type: .math, for: profile)
        state = .handback
        attempts = 1
        hintVisible = false
        feedbackText = nil
        startTime = clock()
    }
    #endif

    private func submitAnswer<T: Equatable>(selected: T, correct: T) {
        guard acceptsChallengeInput else { return }

        attempts += 1

        if selected == correct {
            _ = recordResult(completed: true)
            completeChallenge()
        } else {
            feedbackText = "Almost! Try again!"
            state = .incorrect

            if attempts >= 2 {
                hintVisible = true
            }

            scheduler(0.5) { [weak self] in
                guard let self else { return }
                self.state = .presenting
            }
        }
    }

    private var acceptsChallengeInput: Bool {
        state == .presenting
    }

    private func completeChallenge() {
        state = .completed
        feedbackText = nil
        screenTime.removeShields()
        SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)
        NotificationService.clearBrainBreakAlerts()
        rearmMonitoringIfNeeded()

        scheduler(celebrationDuration) { [weak self] in
            guard let self, self.challenge != nil else { return }
            self.state = .handback
        }
    }

    /// Restarting monitoring resets the DeviceActivity usage threshold, so the
    /// next brain break fires after another full interval. Without this the
    /// threshold event fires only once per day.
    private func rearmMonitoringIfNeeded() {
        guard let profile = activeProfile else { return }

        let status = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus)
        guard ChildlockMonitoringStatus(storedValue: status)?.canRearmMonitoring == true else { return }

        guard shouldRearmAfterCompletion?() ?? true else {
            screenTime.stopMonitoring(profile: profile)
            SharedDefaults.shared.set(
                Date().timeIntervalSince1970,
                forKey: SharedDefaults.Key.dailyLimitReachedAt
            )
            return
        }

        try? screenTime.startMonitoring(profile: profile)
    }

    @discardableResult
    private func recordResult(completed: Bool) -> ChallengeResult? {
        guard let challenge else { return nil }

        let startedAt = startTime ?? clock()
        let completedAt = completed ? clock() : nil
        let solveTime = completedAt.map { $0.timeIntervalSince(startedAt) }

        let result = ChallengeResult(
            type: challenge.type,
            difficultyLevel: challenge.difficulty,
            presentedAt: startedAt,
            completedAt: completedAt,
            attempts: attempts,
            completed: completed,
            hintUsed: hintVisible,
            solveTimeSeconds: solveTime
        )

        results.append(result)

        if completed {
            onCompletedResult?(result)
        }

        return result
    }
}
