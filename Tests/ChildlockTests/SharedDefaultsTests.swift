import XCTest
@testable import Childlock

final class SharedDefaultsTests: XCTestCase {
    func testRapidTestingBuildFlagParsesXcodeValues() {
        XCTAssertTrue(ChildlockRapidTesting.isEnabled(infoDictionaryValue: true))
        XCTAssertTrue(ChildlockRapidTesting.isEnabled(infoDictionaryValue: "YES"))
        XCTAssertTrue(ChildlockRapidTesting.isEnabled(infoDictionaryValue: "true"))
        XCTAssertFalse(ChildlockRapidTesting.isEnabled(infoDictionaryValue: "NO"))
        XCTAssertFalse(ChildlockRapidTesting.isEnabled(infoDictionaryValue: nil))
    }

    func testRapidTestingThresholdUsesTenSecondsOnlyForSupportedOverride() {
        XCTAssertEqual(
            ChildlockRapidTesting.threshold(
                intervalMinutes: 5,
                rapidTestIntervalSeconds: ChildlockRapidTesting.intervalSeconds
            ),
            DateComponents(second: 10)
        )
        XCTAssertEqual(
            ChildlockRapidTesting.threshold(intervalMinutes: 5, rapidTestIntervalSeconds: 5),
            DateComponents(minute: 5)
        )
        XCTAssertEqual(
            ChildlockRapidTesting.threshold(intervalMinutes: 0, rapidTestIntervalSeconds: nil),
            DateComponents(minute: 1)
        )
    }

    func testRapidTestingRestartsAnAlreadyTimingMonitor() {
        XCTAssertTrue(ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: "running"))
        XCTAssertTrue(ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: "interval_started"))
        XCTAssertFalse(ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: "threshold_reached"))
        XCTAssertFalse(ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: "stopped"))
        XCTAssertFalse(ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: nil))
    }

    func testClearLocalSetupStateRemovesScreenTimeAndSetupKeys() {
        let suiteName = "childlock-shared-defaults-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        SharedDefaults.localSetupStateKeys.forEach { defaults.set("present", forKey: $0) }

        SharedDefaults.clearLocalSetupState(defaults: defaults)

        SharedDefaults.localSetupStateKeys.forEach { key in
            XCTAssertNil(defaults.object(forKey: key), "Expected \(key) to be cleared")
        }

        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.challengePending))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringProfileID))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringSelectionData))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringIntervalMinutes))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringProfileAge))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringDifficultyLevel))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.familyActivitySelection))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.challengeAlertsEnabled))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.shieldBrainBreakState))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.pendingShieldBrainBreakCompletions))
    }

    func testShieldBrainBreakReplacesMissAndRequiresTwoCorrectAnswers() {
        var generator = SeededGenerator(seed: 42)
        var state = ShieldBrainBreakState.make(
            profileID: UUID(),
            age: 5,
            difficultyLevel: 8,
            using: &generator
        )
        let firstQuestionKind = state.questionKind
        let wrongAnswerIndex = state.correctAnswerIndex == 0 ? 1 : 0

        XCTAssertEqual(
            state.submit(answerIndex: wrongAnswerIndex, using: &generator),
            .retry
        )
        XCTAssertEqual(state.phase, .retry)
        XCTAssertEqual(state.correctAnswers, 0)
        XCTAssertEqual(state.attempts, 1)
        XCTAssertNotEqual(state.questionKind, firstQuestionKind)
        XCTAssertEqual(state.guidanceText, "Almost! Try this one · 1 of 2")

        let retryQuestionKind = state.questionKind
        XCTAssertEqual(
            state.submit(answerIndex: state.correctAnswerIndex, using: &generator),
            .nextQuestion
        )
        XCTAssertEqual(state.phase, .question)
        XCTAssertEqual(state.correctAnswers, 1)
        XCTAssertEqual(state.attempts, 2)
        XCTAssertNotEqual(state.questionKind, retryQuestionKind)
        XCTAssertEqual(state.guidanceText, "Nice! One more · 2 of 2")

        XCTAssertEqual(
            state.submit(answerIndex: state.correctAnswerIndex, using: &generator),
            .success
        )
        XCTAssertEqual(state.phase, .success)
        XCTAssertEqual(state.correctAnswers, 2)
        XCTAssertEqual(state.attempts, 3)
    }

    func testYoungShieldQuestionPoolsAreVariedAndAnswersStayDistinct() {
        let expectedKinds: [Int: Set<ShieldBrainBreakState.QuestionKind>] = [
            3: [.counting, .nextNumber, .comparison],
            4: [.counting, .addition, .subtraction, .nextNumber, .alternatingPattern],
            5: [.addition, .subtraction, .missingNumber, .comparison, .alternatingPattern, .skipCounting],
        ]

        for age in 3...5 {
            var generator = SeededGenerator(seed: UInt64(age * 101))
            var observedKinds = Set<ShieldBrainBreakState.QuestionKind>()

            for _ in 0..<240 {
                let state = ShieldBrainBreakState.make(
                    profileID: nil,
                    age: age,
                    difficultyLevel: age == 3 ? 3 : age == 4 ? 6 : 9,
                    using: &generator
                )
                observedKinds.insert(state.questionKind)
                XCTAssertNotEqual(state.primaryAnswer, state.secondaryAnswer)
                XCTAssertTrue((0...1).contains(state.correctAnswerIndex))
                XCTAssertFalse(state.prompt.isEmpty)
                XCTAssertEqual(state.requiredAnswers, 2)
            }

            XCTAssertEqual(observedKinds, expectedKinds[age])
        }
    }

    func testShieldBrainBreakStateAndCompletionQueueRoundTrip() {
        let suiteName = "childlock-shield-brain-break-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let state = ShieldBrainBreakState(
            profileID: UUID(),
            prompt: "What is 4 + 4?",
            primaryAnswer: "8",
            secondaryAnswer: "9",
            correctAnswerIndex: 0,
            attempts: 1,
            difficultyLevel: 4,
            phase: .success
        )
        let completion = ShieldBrainBreakCompletion(state: state)

        SharedDefaults.saveShieldBrainBreak(state, defaults: defaults)
        SharedDefaults.appendShieldBrainBreakCompletion(completion, defaults: defaults)
        SharedDefaults.appendShieldBrainBreakCompletion(completion, defaults: defaults)

        XCTAssertEqual(SharedDefaults.shieldBrainBreak(defaults: defaults), state)
        XCTAssertEqual(SharedDefaults.pendingShieldBrainBreakCompletions(defaults: defaults), [completion])

        SharedDefaults.clearShieldBrainBreak(defaults: defaults)
        SharedDefaults.removeShieldBrainBreakCompletions(ids: [completion.id], defaults: defaults)

        XCTAssertNil(SharedDefaults.shieldBrainBreak(defaults: defaults))
        XCTAssertTrue(SharedDefaults.pendingShieldBrainBreakCompletions(defaults: defaults).isEmpty)
    }

    func testShieldBrainBreakDecodesStateSavedBeforeTwoQuestionCheckpoint() throws {
        let state = ShieldBrainBreakState(
            profileID: UUID(),
            prompt: "What is 4 + 4?",
            primaryAnswer: "8",
            secondaryAnswer: "9",
            correctAnswerIndex: 0,
            attempts: 1,
            difficultyLevel: 4
        )
        let encoded = try JSONEncoder().encode(state)
        var legacyObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        ["age", "questionKind", "correctAnswers", "requiredAnswers"].forEach {
            legacyObject.removeValue(forKey: $0)
        }

        let decoded = try JSONDecoder().decode(
            ShieldBrainBreakState.self,
            from: JSONSerialization.data(withJSONObject: legacyObject)
        )

        XCTAssertEqual(decoded.age, 5)
        XCTAssertEqual(decoded.questionKind, .addition)
        XCTAssertEqual(decoded.correctAnswers, 0)
        XCTAssertEqual(decoded.requiredAnswers, 2)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
