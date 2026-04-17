import Foundation

public struct AppStateSnapshot: Codable, Equatable {
    public var hasCompletedOnboarding: Bool
    public var currentTab: AppState.Tab
    public var isPINLocked: Bool
    public var profiles: [ChildProfile]
    public var sessions: [ChallengeSession]
    public var activeProfileID: UUID?
    public var settings: AppSettings

    public init(
        hasCompletedOnboarding: Bool,
        currentTab: AppState.Tab,
        isPINLocked: Bool,
        profiles: [ChildProfile],
        sessions: [ChallengeSession],
        activeProfileID: UUID?,
        settings: AppSettings
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.currentTab = currentTab
        self.isPINLocked = isPINLocked
        self.profiles = profiles
        self.sessions = sessions
        self.activeProfileID = activeProfileID
        self.settings = settings
    }
}

public protocol AppStateStoring {
    func load() -> AppStateSnapshot?
    func save(_ snapshot: AppStateSnapshot)
    func clear()
}

public final class AppGroupFileAppStateStore: AppStateStoring {
    private let fileManager: FileManager
    private let fileURL: URL
    private let fallbackStore: UserDefaultsAppStateStore
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        fileManager: FileManager = .default,
        fileName: String = "app-state-v2.json",
        stateDirectoryURL: URL? = nil,
        fallbackDefaults: UserDefaults = SharedDefaults.shared,
        fallbackKey: String = SharedDefaults.Key.appStateSnapshot
    ) {
        self.fileManager = fileManager
        self.fallbackStore = UserDefaultsAppStateStore(defaults: fallbackDefaults, key: fallbackKey)

        let directoryURL = stateDirectoryURL ?? SharedDefaults.appGroupStateDirectory(fileManager: fileManager)
        self.fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)
    }

    public func load() -> AppStateSnapshot? {
        if
            let data = try? Data(contentsOf: fileURL),
            let container = try? decoder.decode(AppStateSnapshotContainer.self, from: data)
        {
            return container.snapshot
        }

        guard let fallbackSnapshot = fallbackStore.load() else {
            return nil
        }

        // Legacy migration: promote existing defaults snapshot into the App Group file store.
        save(fallbackSnapshot)
        return fallbackSnapshot
    }

    public func save(_ snapshot: AppStateSnapshot) {
        let container = AppStateSnapshotContainer(schemaVersion: 2, snapshot: snapshot, savedAt: Date())

        guard let data = try? encoder.encode(container) else {
            fallbackStore.save(snapshot)
            return
        }

        do {
            try ensureDirectoryExists()
            try data.write(to: fileURL, options: .atomic)
        } catch {
            fallbackStore.save(snapshot)
            return
        }

        fallbackStore.save(snapshot)
    }

    public func clear() {
        try? fileManager.removeItem(at: fileURL)
        fallbackStore.clear()
    }

    private func ensureDirectoryExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}

public final class UserDefaultsAppStateStore: AppStateStoring {
    private let defaults: UserDefaults
    private let key: String

    public init(
        defaults: UserDefaults = SharedDefaults.shared,
        key: String = SharedDefaults.Key.appStateSnapshot
    ) {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> AppStateSnapshot? {
        guard let data = defaults.data(forKey: key) else {
            return nil
        }

        if let snapshot = try? JSONDecoder().decode(AppStateSnapshot.self, from: data) {
            return snapshot
        }

        if let legacy = try? JSONDecoder().decode(LegacyAppStateSnapshot.self, from: data) {
            return AppStateSnapshot(
                hasCompletedOnboarding: legacy.hasCompletedOnboarding,
                currentTab: .home,
                isPINLocked: legacy.isPINLocked,
                profiles: legacy.profiles,
                sessions: legacy.sessions,
                activeProfileID: legacy.activeProfileID,
                settings: .default
            )
        }

        return nil
    }

    public func save(_ snapshot: AppStateSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

public final class InMemoryAppStateStore: AppStateStoring {
    public private(set) var snapshot: AppStateSnapshot?

    public init(snapshot: AppStateSnapshot? = nil) {
        self.snapshot = snapshot
    }

    public func load() -> AppStateSnapshot? {
        snapshot
    }

    public func save(_ snapshot: AppStateSnapshot) {
        self.snapshot = snapshot
    }

    public func clear() {
        snapshot = nil
    }
}

private struct AppStateSnapshotContainer: Codable {
    let schemaVersion: Int
    let snapshot: AppStateSnapshot
    let savedAt: Date
}

private struct LegacyAppStateSnapshot: Codable {
    let hasCompletedOnboarding: Bool
    let isPINLocked: Bool
    let profiles: [ChildProfile]
    let sessions: [ChallengeSession]
    let activeProfileID: UUID?
}
