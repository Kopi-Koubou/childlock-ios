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
    }

    public private(set) var challenge: (any Challenge)?
    public private(set) var state: ChallengeState = .presenting
    public private(set) var attempts = 0
    public private(set) var hintVisible = false
    public private(set) var feedbackText: String?
    public private(set) var results: [ChallengeResult] = []

    public var onCompletedResult: ((ChallengeResult) -> Void)?

    private let engine: ChallengeEngine
    private let screenTime: ScreenTimeManaging
    private let celebrationDuration: TimeInterval
    private let scheduler: @MainActor (TimeInterval, @escaping @MainActor () -> Void) -> Void
    private let clock: () -> Date

    private var startTime: Date?

    public init(
        engine: ChallengeEngine = .shared,
        screenTime: ScreenTimeManaging = ScreenTimeManager.shared,
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
        self.engine = engine
        self.screenTime = screenTime
        self.celebrationDuration = celebrationDuration
        self.scheduler = scheduler
        self.clock = clock
    }

    public func presentChallenge(for profile: ChildProfile, type: ChallengeType? = nil) {
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

        attempts += 1
        feedbackText = "Awesome!"
        state = .correct
        _ = recordResult(completed: true)

        scheduler(celebrationDuration) { [weak self] in
            self?.unlockAndDismiss()
        }
    }

    public func clearChallenge() {
        challenge = nil
        state = .presenting
        attempts = 0
        hintVisible = false
        feedbackText = nil
        startTime = nil
    }

    private func submitAnswer<T: Equatable>(selected: T, correct: T) {
        attempts += 1

        if selected == correct {
            feedbackText = "Awesome!"
            state = .correct
            _ = recordResult(completed: true)

            scheduler(celebrationDuration) { [weak self] in
                self?.unlockAndDismiss()
            }
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

    private func unlockAndDismiss() {
        state = .completed
        screenTime.removeShields()
        SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)

        scheduler(0.35) { [weak self] in
            self?.clearChallenge()
        }
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
