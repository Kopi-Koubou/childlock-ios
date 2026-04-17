import XCTest
@testable import Childlock

@MainActor
final class ChallengeViewModelTests: XCTestCase {
    func testHintAppearsAfterTwoWrongMathAnswers() {
        let screenTime = MockScreenTimeManager()
        let viewModel = ChallengeViewModel(
            screenTime: screenTime,
            celebrationDuration: 0,
            scheduler: { _, action in action() }
        )

        let profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        viewModel.presentChallenge(for: profile, type: .math)

        guard let challenge = viewModel.challenge as? MathChallenge,
              let wrong = challenge.allAnswers.first(where: { $0 != challenge.correctAnswer }) else {
            XCTFail("Expected generated math challenge")
            return
        }

        viewModel.submitMathAnswer(wrong)
        viewModel.submitMathAnswer(wrong)

        XCTAssertTrue(viewModel.hintVisible)
        XCTAssertEqual(viewModel.attempts, 2)
    }

    func testCorrectAnswerRemovesShieldAndClearsPendingFlag() {
        let screenTime = MockScreenTimeManager()
        let viewModel = ChallengeViewModel(
            screenTime: screenTime,
            celebrationDuration: 0,
            scheduler: { _, action in action() }
        )

        SharedDefaults.shared.set(true, forKey: SharedDefaults.Key.challengePending)

        let profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 10)
        viewModel.presentChallenge(for: profile, type: .math)

        guard let challenge = viewModel.challenge as? MathChallenge else {
            XCTFail("Expected generated math challenge")
            return
        }

        viewModel.submitMathAnswer(challenge.correctAnswer)

        XCTAssertTrue(screenTime.shieldsRemoved)
        XCTAssertFalse(SharedDefaults.shared.bool(forKey: SharedDefaults.Key.challengePending))
        XCTAssertEqual(viewModel.results.count, 1)
    }

    func testMemoryCompletionUnlocksAndEmitsResult() {
        let screenTime = MockScreenTimeManager()
        let viewModel = ChallengeViewModel(
            screenTime: screenTime,
            celebrationDuration: 0,
            scheduler: { _, action in action() }
        )

        var completedResults: [ChallengeResult] = []
        viewModel.onCompletedResult = { completedResults.append($0) }

        let profile = ChildProfile(name: "Noah", age: 5, avatarName: "turtle", intervalMinutes: 5)
        viewModel.presentChallenge(for: profile, type: .memory)
        viewModel.submitMemoryCompletion()

        XCTAssertTrue(screenTime.shieldsRemoved)
        XCTAssertEqual(viewModel.results.count, 1)
        XCTAssertEqual(completedResults.count, 1)
        XCTAssertEqual(completedResults.first?.type, .memory)
    }
}
