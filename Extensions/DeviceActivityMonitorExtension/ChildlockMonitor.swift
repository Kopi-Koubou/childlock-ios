import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import os
import UserNotifications

@available(iOS 17.0, *)
final class ChildlockMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let logger = Logger(subsystem: "com.kopikoubou.childlock.monitor", category: "DeviceActivity")
    
    override init() {
        super.init()
        logger.info("Monitor initialized")
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        logger.info("Interval started: \(activity.rawValue)")
        SharedDefaults.shared.set("interval_started", forKey: SharedDefaults.Key.monitoringStatus)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        logger.info("Threshold reached: \(event.rawValue) for \(activity.rawValue)")
        
        guard event.rawValue == "interval_reached" else {
            logger.warning("Unexpected event: \(event.rawValue)")
            return
        }
        
        let defaults = SharedDefaults.shared

        guard
            let data = defaults.data(forKey: SharedDefaults.Key.activeMonitoringSelectionData),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            defaults.set(false, forKey: SharedDefaults.Key.challengePending)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            defaults.set(
                "The monitored app selection payload is invalid.",
                forKey: SharedDefaults.Key.monitoringLastError
            )
            logger.error("Invalid monitored selection")
            return
        }
        
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        defaults.set(true, forKey: SharedDefaults.Key.challengePending)
        defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)
        logger.info(
            "Shield activated for \(selection.applicationTokens.count) apps and \(selection.webDomainTokens.count) web domains"
        )

        postBrainBreakNotification()
    }

    /// The shield itself can't launch Childlock, so the alert plus the Home
    /// fallback are the child's supported paths into the challenge.
    private func postBrainBreakNotification() {
        let alertsEnabled = SharedDefaults.shared.object(forKey: SharedDefaults.Key.challengeAlertsEnabled) as? Bool ?? true
        guard alertsEnabled else {
            logger.info("Skipping brain break notification because challenge alerts are disabled")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Brain break time!"
        content.body = "Tap this alert or open Childlock from Home."
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
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        logger.info("Interval ended: \(activity.rawValue)")
        SharedDefaults.shared.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }
}
