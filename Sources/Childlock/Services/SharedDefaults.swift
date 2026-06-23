import Foundation

public enum SharedDefaults {
    public static let suiteName = "group.com.childlock.shared"

    public enum Key {
        public static let appStateSnapshot = "appStateSnapshot"
        public static let challengePending = "challengePending"
        public static let activeProfileID = "activeProfileID"
        public static let lastSubscriptionCheck = "lastSubscriptionCheck"
        public static let subscriptionActive = "subscriptionActive"
        public static let familyActivitySelection = "familyActivitySelection"
        public static let activeMonitoringProfileID = "activeMonitoringProfileID"
        public static let activeMonitoringSelectionData = "activeMonitoringSelectionData"
        public static let monitoringStatus = "monitoringStatus"
        public static let monitoringLastError = "monitoringLastError"
        public static let monitoringLastStartedAt = "monitoringLastStartedAt"
        public static let moreTimeRequestCount = "moreTimeRequestCount"
        public static let lastMoreTimeRequestDate = "lastMoreTimeRequestDate"
        public static let dailyLimitReachedAt = "dailyLimitReachedAt"
        public static let challengeAlertsEnabled = "challengeAlertsEnabled"
    }

    public enum NotificationIdentifier {
        public static let brainBreak = "childlock_brain_break"
        public static let moreTimeRequest = "childlock_more_time_request"
        public static let dailySummary = "daily_summary"
    }

    public static let localSetupStateKeys = [
        Key.appStateSnapshot,
        Key.challengePending,
        Key.activeProfileID,
        Key.lastSubscriptionCheck,
        Key.subscriptionActive,
        Key.familyActivitySelection,
        Key.activeMonitoringProfileID,
        Key.activeMonitoringSelectionData,
        Key.monitoringStatus,
        Key.monitoringLastError,
        Key.monitoringLastStartedAt,
        Key.moreTimeRequestCount,
        Key.lastMoreTimeRequestDate,
        Key.dailyLimitReachedAt,
        Key.challengeAlertsEnabled,
    ]

    public static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    public static func clearLocalSetupState(defaults: UserDefaults = shared) {
        localSetupStateKeys.forEach { defaults.removeObject(forKey: $0) }
    }

    public static func appGroupStateDirectory(fileManager: FileManager = .default) -> URL {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: suiteName) {
            return containerURL
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Application Support", isDirectory: true)
                .appendingPathComponent("ChildlockState", isDirectory: true)
        }

        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let fallbackBase = appSupport ?? fileManager.temporaryDirectory
        return fallbackBase.appendingPathComponent("ChildlockState", isDirectory: true)
    }
}
