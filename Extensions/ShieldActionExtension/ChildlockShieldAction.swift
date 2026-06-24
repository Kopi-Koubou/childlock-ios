import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import os
import UserNotifications

@available(iOS 17.0, *)
final class ChildlockShieldAction: ShieldActionDelegate {
    private let logger = Logger(subsystem: "com.kopikoubou.childlock.shield-action", category: "ShieldAction")

    override init() {
        super.init()
        logger.info("ShieldAction initialized")
    }

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    private func handleAction(
        _ action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        logger.info("Shield action triggered: \(action.rawValue)")

        switch action {
        case .primaryButtonPressed:
            handleStartChallenge()
            // .close exits the blocked app to the home screen — the shield
            // can't launch Childlock, so the refreshed notification is the
            // child's tappable path into the challenge.
            completionHandler(.close)
        case .secondaryButtonPressed:
            handleRequestMoreTime()
            completionHandler(.close)
        @unknown default:
            logger.warning("Unknown shield action: \(action.rawValue)")
            completionHandler(.close)
        }
    }

    private func handleStartChallenge() {
        logger.info("User started challenge")

        let defaults = SharedDefaults.shared
        defaults.set(true, forKey: SharedDefaults.Key.challengePending)
        defaults.set("challenge_requested", forKey: SharedDefaults.Key.monitoringStatus)
        postBrainBreakNotification()
    }

    private func postBrainBreakNotification() {
        let alertsEnabled = SharedDefaults.shared.object(forKey: SharedDefaults.Key.challengeAlertsEnabled) as? Bool ?? true
        guard alertsEnabled else {
            logger.info("Skipping brain break notification because challenge alerts are disabled")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Brain break ready"
        content.body = "Tap to open Childlock and finish your brain break."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let center = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)

        let request = UNNotificationRequest(
            identifier: SharedDefaults.NotificationIdentifier.brainBreak,
            content: content,
            trigger: nil
        )
        center.add(request) { [logger] error in
            if let error {
                logger.error("Failed to post brain break notification: \(error.localizedDescription)")
            }
        }
    }

    private func handleRequestMoreTime() {
        logger.info("User requested more time")

        let defaults = SharedDefaults.shared
        let requestCount = defaults.integer(forKey: SharedDefaults.Key.moreTimeRequestCount)
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        defaults.set(requestCount + 1, forKey: SharedDefaults.Key.moreTimeRequestCount)
        defaults.set(Date(), forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
        defaults.set("more_time_requested", forKey: SharedDefaults.Key.monitoringStatus)

        logger.info("More time request recorded (count: \(requestCount + 1))")

        let content = UNMutableNotificationContent()
        content.title = "More time requested"
        content.body = "Hand this device to your parent so they can respond in Childlock."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let center = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.moreTimeRequest]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)

        let request = UNNotificationRequest(
            identifier: SharedDefaults.NotificationIdentifier.moreTimeRequest,
            content: content,
            trigger: nil
        )
        center.add(request)
    }
}
