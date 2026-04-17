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
    }

    public static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
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
