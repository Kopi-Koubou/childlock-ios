import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

public enum NotificationService {
    public static func requestPermission() async -> Bool {
        #if canImport(UserNotifications)
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    public static func scheduleDailySummary(challengesCompleted: Int, accuracy: Int) {
        #if canImport(UserNotifications)
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
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_summary"])
        UNUserNotificationCenter.current().add(request)
        #endif
    }

    public static func sendStruggleAlert(childName: String, challengeType: String) {
        #if canImport(UserNotifications)
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
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #endif
    }
}
