import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

public enum ChildlockNotificationAuthorizationStatus: String, Sendable {
    case notDetermined
    case denied
    case authorized
    case provisional
    case ephemeral
    case unavailable

    public var allowsDelivery: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined, .denied, .unavailable:
            return false
        }
    }
}

public enum NotificationService {
    public static func requestPermission() async -> Bool {
        #if os(iOS) && canImport(UserNotifications)
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound, .timeSensitive]
            return try await UNUserNotificationCenter.current().requestAuthorization(options: options)
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    public static func authorizationStatus() async -> ChildlockNotificationAuthorizationStatus {
        #if os(iOS) && canImport(UserNotifications)
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        #if os(iOS)
        case .ephemeral:
            return .ephemeral
        #endif
        @unknown default:
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }

    public static func scheduleDailySummary(challengesCompleted: Int, accuracy: Int) {
        #if os(iOS) && canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Today's Brain Breaks"
        content.body = challengesCompleted > 0
            ? "Your kids completed \(challengesCompleted) challenges today with \(accuracy)% accuracy."
            : "No brain breaks today. Open Childlock to check your settings."
        content.sound = .default

        // Schedule for 8pm today
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: SharedDefaults.NotificationIdentifier.dailySummary,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [SharedDefaults.NotificationIdentifier.dailySummary])
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    public static func cancelDailySummary() {
        #if os(iOS) && canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [SharedDefaults.NotificationIdentifier.dailySummary])
        #endif
    }

    public static func sendStruggleAlert(childName: String, challengeType: String) {
        #if os(iOS) && canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "\(childName) needed help"
        content.body = "\(childName) used a hint on a \(challengeType) challenge. You might want to adjust the difficulty."
        content.sound = .default

        // Send after 5 second delay (so it's not instant)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "struggle_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
        #endif
    }

    public static func cancelAll() {
        #if os(iOS) && canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #endif
    }

    public static func clearBrainBreakAlerts() {
        removeNotifications(withIdentifiers: [SharedDefaults.NotificationIdentifier.brainBreak])
    }

    public static func clearMoreTimeRequestAlerts() {
        removeNotifications(withIdentifiers: [SharedDefaults.NotificationIdentifier.moreTimeRequest])
    }

    public static func clearShieldFlowAlerts() {
        removeNotifications(withIdentifiers: [
            SharedDefaults.NotificationIdentifier.brainBreak,
            SharedDefaults.NotificationIdentifier.moreTimeRequest,
        ])
    }

    private static func removeNotifications(withIdentifiers identifiers: [String]) {
        #if os(iOS) && canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
        #endif
    }
}
