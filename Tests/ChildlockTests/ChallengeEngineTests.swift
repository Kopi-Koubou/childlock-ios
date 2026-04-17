import XCTest
@testable import Childlock

@MainActor
final class ChallengeEngineTests: XCTestCase {
    private let mathGenerator = MathChallengeGenerator()

    func testCountingChallengeForYoungAgeBandContainsCorrectAnswer() {
        guard let challenge = mathGenerator.generate(ageBand: .young, difficulty: 3) as? MathChallenge else {
            XCTFail("Expected MathChallenge")
            return
        }

        XCTAssertEqual(challenge.ageBand, .young)
        XCTAssertTrue(challenge.allAnswers.contains(challenge.correctAnswer))
        XCTAssertEqual(challenge.allAnswers.count, 3)
        XCTAssertGreaterThan(challenge.correctAnswer, 0)
        XCTAssertLessThanOrEqual(challenge.correctAnswer, 10)
        XCTAssertEqual(Set(challenge.allAnswers).count, challenge.allAnswers.count)
    }

    func testArithmeticNeverProducesNegativeResultsForMiddleBand() {
        for _ in 0..<120 {
            guard let challenge = mathGenerator.generate(ageBand: .middle, difficulty: 5) as? MathChallenge else {
                XCTFail("Expected MathChallenge")
                return
            }

            XCTAssertGreaterThanOrEqual(challenge.correctAnswer, 0)
            XCTAssertTrue(challenge.allAnswers.allSatisfy { $0 >= 0 })
        }
    }

    func testWrongAnswersStayWithinPlausibleRangeForOlderBand() {
        for _ in 0..<80 {
            guard let challenge = mathGenerator.generate(ageBand: .older, difficulty: 7) as? MathChallenge else {
                XCTFail("Expected MathChallenge")
                return
            }

            let correct = challenge.correctAnswer
            let expectedRange = max(0, correct - 20)...(correct + 20)

            for answer in challenge.allAnswers where answer != correct {
                XCTAssertTrue(expectedRange.contains(answer))
            }
        }
    }

    func testMiddleAndOlderBandsRenderFourOptions() {
        guard let middle = mathGenerator.generate(ageBand: .middle, difficulty: 5) as? MathChallenge,
              let older = mathGenerator.generate(ageBand: .older, difficulty: 8) as? MathChallenge else {
            XCTFail("Expected MathChallenge")
            return
        }

        XCTAssertEqual(middle.allAnswers.count, 4)
        XCTAssertEqual(older.allAnswers.count, 4)
    }

    func testDifficultyResolutionUsesAgeBandAndOverrides() {
        let engine = ChallengeEngine()
        let autoYoung = ChildProfile(name: "A", age: 4, avatarName: "fox", intervalMinutes: 10)
        XCTAssertEqual(engine.effectiveDifficulty(for: autoYoung), 6)

        let hardOverride = ChildProfile(
            name: "B",
            age: 9,
            avatarName: "owl",
            intervalMinutes: 10,
            difficultyOverride: .hard
        )
        XCTAssertEqual(engine.effectiveDifficulty(for: hardOverride), 8)

        let easyOverride = ChildProfile(
            name: "C",
            age: 9,
            avatarName: "bear",
            intervalMinutes: 10,
            difficultyOverride: .easy
        )
        XCTAssertEqual(engine.effectiveDifficulty(for: easyOverride), 3)
    }
}
