import Foundation

public enum ChallengeType: String, Codable, CaseIterable {
    case math
    case pattern
    case memory
    case puzzle
}

public struct ChallengeSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var childProfileID: UUID
    public var date: Date
    public var screenTimeSeconds: Int
    public var synced: Bool
    public var results: [ChallengeResult]

    public init(
        id: UUID = UUID(),
        childProfileID: UUID,
        date: Date = Date(),
        screenTimeSeconds: Int,
        synced: Bool = false,
        results: [ChallengeResult] = []
    ) {
        self.id = id
        self.childProfileID = childProfileID
        self.date = date
        self.screenTimeSeconds = screenTimeSeconds
        self.synced = synced
        self.results = results
    }

    public var challengesPresented: Int { results.count }

    public var challengesCompleted: Int {
        results.filter(\.completed).count
    }

    public var accuracy: Double {
        guard challengesPresented > 0 else { return 0 }
        return Double(challengesCompleted) / Double(challengesPresented)
    }
}

public struct ChallengeResult: Identifiable, Codable, Equatable {
    public var id: UUID
    public var type: ChallengeType
    public var difficultyLevel: Int
    public var presentedAt: Date
    public var completedAt: Date?
    public var attempts: Int
    public var completed: Bool
    public var hintUsed: Bool
    public var solveTimeSeconds: Double?

    public init(
        id: UUID = UUID(),
        type: ChallengeType,
        difficultyLevel: Int,
        presentedAt: Date,
        completedAt: Date?,
        attempts: Int,
        completed: Bool,
        hintUsed: Bool,
        solveTimeSeconds: Double? = nil
    ) {
        self.id = id
        self.type = type
        self.difficultyLevel = difficultyLevel
        self.presentedAt = presentedAt
        self.completedAt = completedAt
        self.attempts = attempts
        self.completed = completed
        self.hintUsed = hintUsed
        self.solveTimeSeconds = solveTimeSeconds
    }

    public var solveTime: Double? {
        guard let completedAt else { return nil }
        return completedAt.timeIntervalSince(presentedAt)
    }
}
