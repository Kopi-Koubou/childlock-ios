import Foundation

public enum AgeBand: String, Codable, CaseIterable {
    case young   // 3-5
    case middle  // 6-8
    case older   // 9-12
}

public enum DifficultyOverride: String, Codable, CaseIterable {
    case auto
    case easy
    case medium
    case hard
}

public struct ChildProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var age: Int
    public var avatarName: String
    public var intervalMinutes: Int
    public var difficultyOverride: DifficultyOverride
    public var createdAt: Date
    public var updatedAt: Date

    // Opaque FamilyControls payload.
    public var monitoredActivitiesData: Data?

    public init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        avatarName: String,
        intervalMinutes: Int,
        difficultyOverride: DifficultyOverride = .auto,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        monitoredActivitiesData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.avatarName = avatarName
        self.intervalMinutes = intervalMinutes
        self.difficultyOverride = difficultyOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.monitoredActivitiesData = monitoredActivitiesData
    }

    public var ageBand: AgeBand {
        switch age {
        case 3...5: return .young
        case 6...8: return .middle
        case 9...12: return .older
        default: return .middle
        }
    }

    public var monitoredSelectionTokenData: Data? {
        guard
            let monitoredActivitiesData,
            let payload = try? JSONDecoder().decode(MonitoredActivitiesPayload.self, from: monitoredActivitiesData)
        else {
            return nil
        }

        return payload.selectionTokenData
    }

    public var monitoredAppDisplayNames: [String] {
        guard let monitoredActivitiesData else {
            return []
        }

        if let payload = try? JSONDecoder().decode(MonitoredActivitiesPayload.self, from: monitoredActivitiesData) {
            return payload.displayNames
        }

        // Legacy format migration: `[String]` only.
        if let names = try? JSONDecoder().decode([String].self, from: monitoredActivitiesData) {
            return names
        }

        return []
    }

    public mutating func setMonitoredSelectionData(_ tokenData: Data?, displayNames: [String]) {
        let payload = MonitoredActivitiesPayload(
            schemaVersion: 1,
            selectionTokenData: tokenData,
            displayNames: Self.normalizedDisplayNames(displayNames)
        )

        monitoredActivitiesData = try? JSONEncoder().encode(payload)
        updatedAt = Date()
    }

    public mutating func setMonitoredAppDisplayNames(_ names: [String]) {
        setMonitoredSelectionData(nil, displayNames: names)
    }

    private static func normalizedDisplayNames(_ names: [String]) -> [String] {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let filtered = trimmed.filter { !$0.isEmpty }
        return Array(NSOrderedSet(array: filtered)) as? [String] ?? filtered
    }
}

private struct MonitoredActivitiesPayload: Codable, Equatable {
    let schemaVersion: Int
    let selectionTokenData: Data?
    let displayNames: [String]
}
