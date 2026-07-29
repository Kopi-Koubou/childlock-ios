import XCTest
@testable import Childlock

final class SharedDefaultsTests: XCTestCase {
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

    func testShieldBrainBreakTracksRetryThenSuccess() {
        var state = ShieldBrainBreakState(
            profileID: UUID(),
            prompt: "What is 2 + 3?",
            primaryAnswer: "4",
            secondaryAnswer: "5",
            correctAnswerIndex: 1,
            difficultyLevel: 3
        )

        XCTAssertFalse(state.submit(answerIndex: 0))
        XCTAssertEqual(state.phase, .retry)
        XCTAssertEqual(state.attempts, 1)

        XCTAssertTrue(state.submit(answerIndex: 1))
        XCTAssertEqual(state.phase, .success)
        XCTAssertEqual(state.attempts, 2)
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
}
