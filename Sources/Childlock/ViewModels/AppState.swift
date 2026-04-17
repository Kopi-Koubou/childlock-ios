import Foundation
import Observation

public struct DailySummary: Equatable {
    public let challengesPresented: Int
    public let challengesCompleted: Int
    public let screenTimeSeconds: Int
    public let challengeSolveSeconds: Int

    public init(
        challengesPresented: Int,
        challengesCompleted: Int,
        screenTimeSeconds: Int,
        challengeSolveSeconds: Int = 0
    ) {
        self.challengesPresented = challengesPresented
        self.challengesCompleted = challengesCompleted
        self.screenTimeSeconds = screenTimeSeconds
        self.challengeSolveSeconds = challengeSolveSeconds
    }

    public var accuracy: Double {
        guard challengesPresented > 0 else { return 0 }
        return Double(challengesCompleted) / Double(challengesPresented)
    }

    public var screenTimeFormatted: String {
        Self.formatDuration(seconds: screenTimeSeconds)
    }

    public var challengeTimeFormatted: String {
        Self.formatDuration(seconds: challengeSolveSeconds)
    }

    public var averageSolveTimeSeconds: Double? {
        guard challengesCompleted > 0 else { return nil }
        return Double(challengeSolveSeconds) / Double(challengesCompleted)
    }

    public var averageSolveTimeFormatted: String {
        guard let averageSolveTimeSeconds else { return "—" }
        return "\(Int(averageSolveTimeSeconds.rounded()))s"
    }

    private static func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

public struct ActivityFeedItem: Identifiable, Equatable {
    public var id: UUID { result.id }
    public let profileID: UUID
    public let profileName: String
    public let avatarName: String
    public let result: ChallengeResult

    public init(profileID: UUID, profileName: String, avatarName: String, result: ChallengeResult) {
        self.profileID = profileID
        self.profileName = profileName
        self.avatarName = avatarName
        self.result = result
    }
}

@MainActor
@Observable
public final class AppState {
    public static let shared = AppState(store: AppGroupFileAppStateStore())

    public var isAuthenticated = false
    public var hasCompletedOnboarding = false {
        didSet { persistIfNeeded() }
    }
    public var currentTab: Tab = .home {
        didSet { persistIfNeeded() }
    }
    public var isPINLocked = true {
        didSet { persistIfNeeded() }
    }
    public var activeChallenge: (any Challenge)?

    public var profiles: [ChildProfile] = [] {
        didSet { persistIfNeeded() }
    }
    public var sessions: [ChallengeSession] = [] {
        didSet { persistIfNeeded() }
    }
    public var activeProfileID: UUID? {
        didSet { persistIfNeeded() }
    }
    public var settings: AppSettings = .default {
        didSet { persistIfNeeded() }
    }

    public enum Tab: Int, Codable {
        case home
        case children
        case apps
        case settings
    }

    public enum ActivityWindow: String, CaseIterable, Codable, Identifiable {
        case day
        case week
        case allTime

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .day:
                return "Day"
            case .week:
                return "Week"
            case .allTime:
                return "All Time"
            }
        }
    }

    private static let supportedIntervals = [5, 10, 15, 20, 30]

    private let store: AppStateStoring
    private var isHydratingSnapshot = false

    public init(store: AppStateStoring = AppGroupFileAppStateStore()) {
        self.store = store
        hydrateFromStore()
    }

    public var activeProfile: ChildProfile? {
        guard let activeProfileID else { return profiles.first }
        return profiles.first { $0.id == activeProfileID }
    }

    public var monitoredAppNames: [String] {
        activeProfile?.monitoredAppDisplayNames ?? []
    }

    public var todaySummary: DailySummary {
        summary(window: .day)
    }

    public func summary(
        window: ActivityWindow = .day,
        profileID: UUID? = nil,
        referenceDate: Date = Date()
    ) -> DailySummary {
        let relevantSessions = filteredSessions(
            window: window,
            profileID: profileID,
            referenceDate: referenceDate
        )
        let challengeSolveSeconds = relevantSessions
            .flatMap(\.results)
            .compactMap(\.solveTimeSeconds)
            .reduce(0.0, +)

        return DailySummary(
            challengesPresented: relevantSessions.reduce(0) { $0 + $1.challengesPresented },
            challengesCompleted: relevantSessions.reduce(0) { $0 + $1.challengesCompleted },
            screenTimeSeconds: relevantSessions.reduce(0) { $0 + $1.screenTimeSeconds },
            challengeSolveSeconds: Int(challengeSolveSeconds.rounded())
        )
    }

    public func recentActivity(
        limit: Int = 12,
        profileID: UUID? = nil,
        window: ActivityWindow = .allTime,
        referenceDate: Date = Date()
    ) -> [ActivityFeedItem] {
        filteredSessions(window: window, profileID: profileID, referenceDate: referenceDate)
            .flatMap { session in
                session.results.map { result in
                    let profile = profiles.first(where: { $0.id == session.childProfileID })
                    return ActivityFeedItem(
                        profileID: session.childProfileID,
                        profileName: profile?.name ?? "Child",
                        avatarName: profile?.avatarName ?? "fox",
                        result: result
                    )
                }
            }
            .sorted { $0.result.presentedAt > $1.result.presentedAt }
            .prefix(limit)
            .map { $0 }
    }

    public func completeOnboarding(with profile: ChildProfile, pinConfigured: Bool) {
        if profiles.contains(where: { $0.id == profile.id }) {
            updateProfile(profile)
        } else {
            profiles.append(profile)
        }

        activeProfileID = profile.id
        hasCompletedOnboarding = true
        isPINLocked = pinConfigured

        var updatedSettings = settings
        updatedSettings.hasCompletedOnboarding = true
        settings = updatedSettings
    }

    public func setActiveProfile(id: UUID) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        activeProfileID = id
    }

    public func updateProfile(_ profile: ChildProfile) {
        if let existingIndex = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[existingIndex] = profile
        } else {
            profiles.append(profile)
        }
    }

    @discardableResult
    public func setMonitoredSelection(
        for profileID: UUID,
        tokenData: Data?,
        displayNames: [String]
    ) -> Bool {
        guard let existingIndex = profiles.firstIndex(where: { $0.id == profileID }) else {
            return false
        }

        var profile = profiles[existingIndex]
        profile.setMonitoredSelectionData(tokenData, displayNames: displayNames)
        profiles[existingIndex] = profile
        return true
    }

    @discardableResult
    public func applyActiveProfileMonitoredSelectionToAllChildren() -> Int {
        guard let sourceProfile = activeProfile else {
            return 0
        }

        let sourceTokenData = sourceProfile.monitoredSelectionTokenData
        let sourceDisplayNames = sourceProfile.monitoredAppDisplayNames

        var updatedChildrenCount = 0

        for index in profiles.indices where profiles[index].id != sourceProfile.id {
            var profile = profiles[index]
            profile.setMonitoredSelectionData(sourceTokenData, displayNames: sourceDisplayNames)
            profiles[index] = profile
            updatedChildrenCount += 1
        }

        return updatedChildrenCount
    }

    @discardableResult
    public func addProfile(
        name: String,
        age: Int,
        avatarName: String,
        intervalMinutes: Int,
        difficultyOverride: DifficultyOverride = .auto,
        inheritMonitoredAppsFromActiveProfile: Bool = true
    ) -> ChildProfile? {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else { return nil }

        let normalizedAge = min(max(age, 3), 12)
        let normalizedInterval = Self.normalizedInterval(intervalMinutes)

        var profile = ChildProfile(
            name: normalizedName,
            age: normalizedAge,
            avatarName: avatarName,
            intervalMinutes: normalizedInterval,
            difficultyOverride: difficultyOverride
        )

        if inheritMonitoredAppsFromActiveProfile, let activeProfile {
            profile.monitoredActivitiesData = activeProfile.monitoredActivitiesData
        }

        profiles.append(profile)
        activeProfileID = profile.id
        return profile
    }

    public func recordChallengeResult(_ result: ChallengeResult, for profileID: UUID) {
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return }

        let dayStart = Calendar.current.startOfDay(for: result.presentedAt)
        let sessionIndex = sessions.firstIndex {
            $0.childProfileID == profileID && Calendar.current.isDate($0.date, inSameDayAs: dayStart)
        }

        if let sessionIndex {
            sessions[sessionIndex].results.append(result)
            sessions[sessionIndex].screenTimeSeconds += profile.intervalMinutes * 60
        } else {
            let newSession = ChallengeSession(
                childProfileID: profileID,
                date: dayStart,
                screenTimeSeconds: profile.intervalMinutes * 60,
                synced: false,
                results: [result]
            )
            sessions.append(newSession)
        }
    }

    public func unlockSettings(with pin: String, pinService: PINService = .shared) -> Bool {
        let isValid = pinService.verify(pin)
        if isValid {
            isPINLocked = false
        }
        return isValid
    }

    public func lockSettings(pinService: PINService = .shared) {
        isPINLocked = true
        pinService.lockSession()
    }

    public func resetForTesting() {
        isHydratingSnapshot = true
        isAuthenticated = false
        hasCompletedOnboarding = false
        currentTab = .home
        isPINLocked = true
        activeChallenge = nil
        profiles = []
        sessions = []
        activeProfileID = nil
        settings = .default
        isHydratingSnapshot = false

        store.clear()
    }

    private func hydrateFromStore() {
        guard let snapshot = store.load() else {
            return
        }

        isHydratingSnapshot = true
        hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        currentTab = snapshot.currentTab
        isPINLocked = snapshot.isPINLocked
        profiles = snapshot.profiles
        sessions = snapshot.sessions
        activeProfileID = snapshot.activeProfileID
        settings = snapshot.settings
        isHydratingSnapshot = false
    }

    private func persistIfNeeded() {
        guard !isHydratingSnapshot else {
            return
        }

        store.save(
            AppStateSnapshot(
                hasCompletedOnboarding: hasCompletedOnboarding,
                currentTab: currentTab,
                isPINLocked: isPINLocked,
                profiles: profiles,
                sessions: sessions,
                activeProfileID: activeProfileID,
                settings: settings
            )
        )
    }

    private func filteredSessions(
        window: ActivityWindow,
        profileID: UUID?,
        referenceDate: Date
    ) -> [ChallengeSession] {
        let bounds = Self.windowBounds(for: window, referenceDate: referenceDate)

        return sessions.filter { session in
            let matchesProfile = profileID.map { session.childProfileID == $0 } ?? true
            let matchesWindow: Bool
            if let bounds {
                matchesWindow = session.date >= bounds.start && session.date < bounds.end
            } else {
                matchesWindow = true
            }

            return matchesProfile && matchesWindow
        }
    }

    private static func normalizedInterval(_ intervalMinutes: Int) -> Int {
        supportedIntervals.min { lhs, rhs in
            abs(lhs - intervalMinutes) < abs(rhs - intervalMinutes)
        } ?? 15
    }

    private static func windowBounds(
        for window: ActivityWindow,
        referenceDate: Date
    ) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: referenceDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? referenceDate

        switch window {
        case .day:
            return (dayStart, dayEnd)
        case .week:
            let weekStart = calendar.date(byAdding: .day, value: -6, to: dayStart) ?? dayStart
            return (weekStart, dayEnd)
        case .allTime:
            return nil
        }
    }
}
