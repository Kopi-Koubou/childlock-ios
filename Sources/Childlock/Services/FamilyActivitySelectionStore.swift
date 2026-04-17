import Foundation

public struct FamilyActivitySelectionSnapshot: Codable, Equatable, Sendable {
    public var tokenData: Data?
    public var displayNames: [String]
    public var updatedAt: Date

    public init(tokenData: Data?, displayNames: [String], updatedAt: Date = Date()) {
        self.tokenData = tokenData
        self.displayNames = displayNames
        self.updatedAt = updatedAt
    }
}

public protocol FamilyActivitySelectionStoring {
    func load() -> FamilyActivitySelectionSnapshot?
    func save(_ snapshot: FamilyActivitySelectionSnapshot)
    func clear()
}

public final class AppGroupFamilyActivitySelectionStore: FamilyActivitySelectionStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = SharedDefaults.shared,
        key: String = SharedDefaults.Key.familyActivitySelection
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> FamilyActivitySelectionSnapshot? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        return try? JSONDecoder().decode(FamilyActivitySelectionSnapshot.self, from: data)
    }

    public func save(_ snapshot: FamilyActivitySelectionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

