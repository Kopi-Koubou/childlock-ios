import Foundation

public protocol Challenge {
    var type: ChallengeType { get }
    var ageBand: AgeBand { get }
    var difficulty: Int { get }
    var instruction: String { get }
    var voicePrompt: String? { get }
    var hintText: String { get }
}

public protocol MultipleChoiceChallenge: Challenge {
    associatedtype Answer: Equatable
    var correctAnswer: Answer { get }
    var allAnswers: [Answer] { get }
}

public struct MathChallenge: MultipleChoiceChallenge, Equatable {
    public let type: ChallengeType = .math
    public let ageBand: AgeBand
    public let difficulty: Int
    public let instruction: String
    public let voicePrompt: String?
    public let hintText: String
    public let expression: String
    public let correctAnswer: Int
    public let allAnswers: [Int]

    public init(
        ageBand: AgeBand,
        difficulty: Int,
        instruction: String,
        voicePrompt: String?,
        hintText: String,
        expression: String,
        correctAnswer: Int,
        allAnswers: [Int]
    ) {
        self.ageBand = ageBand
        self.difficulty = difficulty
        self.instruction = instruction
        self.voicePrompt = voicePrompt
        self.hintText = hintText
        self.expression = expression
        self.correctAnswer = correctAnswer
        self.allAnswers = allAnswers
    }
}

public struct PatternChallenge: MultipleChoiceChallenge, Equatable {
    public let type: ChallengeType = .pattern
    public let ageBand: AgeBand
    public let difficulty: Int
    public let instruction: String
    public let voicePrompt: String?
    public let hintText: String
    public let sequence: [String]
    public let correctAnswer: String
    public let allAnswers: [String]

    public init(
        ageBand: AgeBand,
        difficulty: Int,
        instruction: String,
        voicePrompt: String?,
        hintText: String,
        sequence: [String],
        correctAnswer: String,
        allAnswers: [String]
    ) {
        self.ageBand = ageBand
        self.difficulty = difficulty
        self.instruction = instruction
        self.voicePrompt = voicePrompt
        self.hintText = hintText
        self.sequence = sequence
        self.correctAnswer = correctAnswer
        self.allAnswers = allAnswers
    }
}

public struct MemoryChallenge: Challenge, Equatable {
    public let type: ChallengeType = .memory
    public let ageBand: AgeBand
    public let difficulty: Int
    public let instruction: String
    public let voicePrompt: String?
    public let hintText: String
    public let pairCount: Int
    public let symbols: [String]
}

public struct PuzzleChallenge: MultipleChoiceChallenge, Equatable {
    public let type: ChallengeType = .puzzle
    public let ageBand: AgeBand
    public let difficulty: Int
    public let instruction: String
    public let voicePrompt: String?
    public let hintText: String
    public let prompt: String
    public let correctAnswer: String
    public let allAnswers: [String]

    public init(
        ageBand: AgeBand,
        difficulty: Int,
        instruction: String,
        voicePrompt: String?,
        hintText: String,
        prompt: String,
        correctAnswer: String,
        allAnswers: [String]
    ) {
        self.ageBand = ageBand
        self.difficulty = difficulty
        self.instruction = instruction
        self.voicePrompt = voicePrompt
        self.hintText = hintText
        self.prompt = prompt
        self.correctAnswer = correctAnswer
        self.allAnswers = allAnswers
    }
}

public protocol ChallengeGenerator {
    var challengeType: ChallengeType { get }
    func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge
}

public final class MathChallengeGenerator: ChallengeGenerator {
    public let challengeType: ChallengeType = .math

    public init() {}

    public func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge {
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
        let count = min(max(difficulty + 2, 3), 10)
        let wrongAnswers = generateWrongAnswers(correct: count, count: 2, range: 1...10)

        return MathChallenge(
            ageBand: .young,
            difficulty: difficulty,
            instruction: "Count the stars!",
            voicePrompt: "Count the stars!",
            hintText: "Try pointing to each star as you count.",
            expression: "\(count) stars",
            correctAnswer: count,
            allAnswers: (wrongAnswers + [count]).shuffled()
        )
    }

    private func generateArithmetic(difficulty: Int, ops: [MathOp]) -> MathChallenge {
        let op = ops.randomElement() ?? .add
        let (a, b, result) = op.generate(difficulty: difficulty)
        let expression = "\(a) \(op.symbol) \(b) = ?"
        let wrongAnswers = generateWrongAnswers(
            correct: result,
            count: 3,
            range: max(0, result - 20)...(result + 20)
        )

        return MathChallenge(
            ageBand: difficulty <= 5 ? .middle : .older,
            difficulty: difficulty,
            instruction: "Solve it!",
            voicePrompt: nil,
            hintText: op.hint(a: a, b: b),
            expression: expression,
            correctAnswer: result,
            allAnswers: (wrongAnswers + [result]).shuffled()
        )
    }

    private func generateWrongAnswers(correct: Int, count: Int, range: ClosedRange<Int>) -> [Int] {
        var wrongAnswers = Set<Int>()
        var attempts = 0

        while wrongAnswers.count < count && attempts < 200 {
            attempts += 1
            let candidate = Int.random(in: range)
            if candidate != correct, candidate >= 0 {
                wrongAnswers.insert(candidate)
            }
        }

        if wrongAnswers.count < count {
            for fallback in range where wrongAnswers.count < count {
                if fallback != correct {
                    wrongAnswers.insert(fallback)
                }
            }
        }

        return Array(wrongAnswers.prefix(count))
    }
}

private enum MathOp {
    case add
    case subtract
    case multiply
    case divide

    var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
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
            return (result + b, b, result)
        case .multiply:
            let a = Int.random(in: 2...(difficulty + 2))
            let b = Int.random(in: 2...(difficulty + 2))
            return (a, b, a * b)
        case .divide:
            let b = Int.random(in: 2...(difficulty + 2))
            let result = Int.random(in: 1...(difficulty + 2))
            return (result * b, b, result)
        }
    }

    func hint(a: Int, b: Int) -> String {
        switch self {
        case .add:
            let half = b / 2
            return "Try splitting it: \(a) + \(half), then add \(b - half)."
        case .subtract:
            return "Start at \(a) and count back \(b)."
        case .multiply:
            return "Think of it as \(a) groups of \(b)."
        case .divide:
            return "How many groups of \(b) fit in \(a)?"
        }
    }
}

public final class PatternChallengeGenerator: ChallengeGenerator {
    public let challengeType: ChallengeType = .pattern

    private static let youngSymbolBank = ["🔴", "🔵", "🟡", "🟢", "⭐", "🌙", "🍎", "🐟"]

    public init() {}

    public func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge {
        switch ageBand {
        case .young:
            return generateYoungShapePattern(difficulty: difficulty)
        case .middle:
            return generateNumberPattern(difficulty: difficulty, ageBand: .middle)
        case .older:
            return generateOlderPattern(difficulty: difficulty)
        }
    }

    private func generateYoungShapePattern(difficulty: Int) -> PatternChallenge {
        let symbols = Self.youngSymbolBank.shuffled()
        let a = symbols[0]
        let b = symbols[1]
        let distractor = symbols[2]

        // Alternate between ABAB and AABB style repeats so the answer
        // can't be memorized across sessions.
        let useDoublePattern = Bool.random()
        let sequence: [String]
        let correct: String
        if useDoublePattern {
            sequence = [a, a, b, b, a, a]
            correct = b
        } else {
            sequence = [a, b, a, b, a]
            correct = b
        }

        return PatternChallenge(
            ageBand: .young,
            difficulty: difficulty,
            instruction: "Tap the next one",
            voicePrompt: "Tap the next one.",
            hintText: "Say the pattern out loud and listen for the repeat.",
            sequence: sequence,
            correctAnswer: correct,
            allAnswers: [correct, a == correct ? b : a, distractor].shuffled()
        )
    }

    private func generateNumberPattern(difficulty: Int, ageBand: AgeBand) -> PatternChallenge {
        let step = [2, 3, 4, 5, 10].randomElement() ?? 2
        let base = Int.random(in: 1...(difficulty * 3 + 2))
        let sequence = [base, base + step, base + step * 2].map(String.init)
        let correct = base + step * 3

        var wrongAnswers = Set<Int>()
        for candidate in [correct - 1, correct + 1, correct + step, correct - step, correct + 2] {
            if candidate != correct, candidate > 0 {
                wrongAnswers.insert(candidate)
            }
            if wrongAnswers.count == 3 { break }
        }

        return PatternChallenge(
            ageBand: ageBand,
            difficulty: difficulty,
            instruction: "Pick the next number.",
            voicePrompt: nil,
            hintText: "Each number goes up by \(step).",
            sequence: sequence,
            correctAnswer: String(correct),
            allAnswers: ([correct] + Array(wrongAnswers.prefix(3))).map(String.init).shuffled()
        )
    }

    private func generateOlderPattern(difficulty: Int) -> PatternChallenge {
        if Bool.random() {
            // Rotating arrow with random start and direction.
            let clockwise = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
            let direction = Bool.random() ? 1 : -1
            let stepSize = [1, 2].randomElement() ?? 1
            let start = Int.random(in: 0..<clockwise.count)

            let indices = (0..<4).map { offset in
                ((start + offset * stepSize * direction) % clockwise.count + clockwise.count) % clockwise.count
            }
            let sequence = indices.prefix(3).map { clockwise[$0] }
            let correct = clockwise[indices[3]]
            let wrong = clockwise.filter { $0 != correct }.shuffled().prefix(3)

            return PatternChallenge(
                ageBand: .older,
                difficulty: difficulty,
                instruction: "Find the rotation rule.",
                voicePrompt: nil,
                hintText: "The arrow turns the same amount each step.",
                sequence: sequence,
                correctAnswer: correct,
                allAnswers: ([correct] + wrong).shuffled()
            )
        }

        // Growing-step number pattern: +n, +n+1, +n+2...
        let base = Int.random(in: 2...12)
        let firstStep = Int.random(in: 2...5)
        let values = [
            base,
            base + firstStep,
            base + firstStep + (firstStep + 1),
            base + firstStep + (firstStep + 1) + (firstStep + 2),
        ]
        let sequence = values.prefix(3).map(String.init)
        let correct = values[3]
        let wrongAnswers = [correct - 1, correct + 1, correct + firstStep].filter { $0 != correct }

        return PatternChallenge(
            ageBand: .older,
            difficulty: difficulty,
            instruction: "Pick the next number.",
            voicePrompt: nil,
            hintText: "The jump between numbers grows by 1 each time.",
            sequence: sequence,
            correctAnswer: String(correct),
            allAnswers: ([correct] + wrongAnswers).map(String.init).shuffled()
        )
    }
}

public final class MemoryChallengeGenerator: ChallengeGenerator {
    public let challengeType: ChallengeType = .memory

    private let symbolBank = ["🍎", "⭐", "🌙", "☀️", "🎈", "🐢", "🧩", "🚀", "🍓", "🎯", "🐳", "🌈"]

    public init() {}

    public func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge {
        let pairCount: Int
        switch ageBand {
        case .young: pairCount = 3
        case .middle: pairCount = min(6 + max(difficulty - 4, 0) / 2, 8)
        case .older: pairCount = min(9 + max(difficulty - 5, 0) / 2, 12)
        }

        let symbols = Array(symbolBank.shuffled().prefix(pairCount))

        return MemoryChallenge(
            ageBand: ageBand,
            difficulty: difficulty,
            instruction: "Match the pairs.",
            voicePrompt: ageBand == .young ? "Match the same pictures." : nil,
            hintText: "Remember where each symbol appears before flipping.",
            pairCount: pairCount,
            symbols: symbols
        )
    }
}

public final class PuzzleChallengeGenerator: ChallengeGenerator {
    public let challengeType: ChallengeType = .puzzle

    private struct ShapeHunt {
        let name: String
        let symbol: String
        let hint: String
    }

    private static let shapeHunts: [ShapeHunt] = [
        ShapeHunt(name: "triangle", symbol: "🔺", hint: "It has three corners."),
        ShapeHunt(name: "circle", symbol: "🔵", hint: "It's perfectly round."),
        ShapeHunt(name: "square", symbol: "🟨", hint: "It has four equal sides."),
        ShapeHunt(name: "heart", symbol: "❤️", hint: "It means love."),
        ShapeHunt(name: "star", symbol: "⭐", hint: "It twinkles in the sky."),
    ]

    /// Odd-one-out groups: three of a kind plus one item that doesn't belong.
    private static let oddOneOutGroups: [(theme: String, members: [String], odd: String)] = [
        ("animals", ["🐶", "🐱", "🐰"], "🚗"),
        ("fruit", ["🍎", "🍌", "🍇"], "⚽"),
        ("vehicles", ["🚗", "🚌", "🚲"], "🍕"),
        ("sea creatures", ["🐟", "🐙", "🦀"], "🦅"),
        ("things that fly", ["🦅", "🦋", "✈️"], "🐢"),
        ("food", ["🍕", "🍔", "🌮"], "📚"),
    ]

    public init() {}

    public func generate(ageBand: AgeBand, difficulty: Int) -> any Challenge {
        switch ageBand {
        case .young:
            let hunt = Self.shapeHunts.randomElement() ?? Self.shapeHunts[0]
            let wrong = Self.shapeHunts
                .filter { $0.name != hunt.name }
                .shuffled()
                .prefix(2)
                .map(\.symbol)

            return PuzzleChallenge(
                ageBand: ageBand,
                difficulty: difficulty,
                instruction: "Find the shape.",
                voicePrompt: "Tap the \(hunt.name)!",
                hintText: hunt.hint,
                prompt: "Tap the \(hunt.name)",
                correctAnswer: hunt.symbol,
                allAnswers: ([hunt.symbol] + wrong).shuffled()
            )
        case .middle, .older:
            let group = Self.oddOneOutGroups.randomElement() ?? Self.oddOneOutGroups[0]
            return PuzzleChallenge(
                ageBand: ageBand,
                difficulty: difficulty,
                instruction: "Find the odd one out.",
                voicePrompt: nil,
                hintText: "Three of these are \(group.theme).",
                prompt: "Which one doesn't belong?",
                correctAnswer: group.odd,
                allAnswers: (group.members + [group.odd]).shuffled()
            )
        }
    }
}

@MainActor
public final class ChallengeEngine {
    public static let shared = ChallengeEngine()

    private let generators: [ChallengeType: any ChallengeGenerator]

    public init(generators: [ChallengeType: any ChallengeGenerator]? = nil) {
        if let generators {
            self.generators = generators
        } else {
            self.generators = [
                .math: MathChallengeGenerator(),
                .pattern: PatternChallengeGenerator(),
                .memory: MemoryChallengeGenerator(),
                .puzzle: PuzzleChallengeGenerator(),
            ]
        }
    }

    public func generateChallenge(for profile: ChildProfile) -> any Challenge {
        let type = ChallengeType.allCases.randomElement() ?? .math
        return generateChallenge(type: type, for: profile)
    }

    public func generateChallenge(type: ChallengeType, for profile: ChildProfile) -> any Challenge {
        let difficulty = effectiveDifficulty(for: profile)
        let generator = generators[type] ?? MathChallengeGenerator()
        return generator.generate(ageBand: profile.ageBand, difficulty: difficulty)
    }

    public func effectiveDifficulty(for profile: ChildProfile) -> Int {
        switch profile.difficultyOverride {
        case .auto:
            switch profile.ageBand {
            case .young:
                return max(1, min(10, (profile.age - 2) * 3))
            case .middle:
                return max(1, min(10, (profile.age - 5) * 3))
            case .older:
                return max(1, min(10, (profile.age - 8) * 3))
            }
        case .easy:
            return 3
        case .medium:
            return 5
        case .hard:
            return 8
        }
    }
}
