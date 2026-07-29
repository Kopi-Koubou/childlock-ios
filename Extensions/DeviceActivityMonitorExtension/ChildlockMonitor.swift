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
        
        let profileID = defaults
            .string(forKey: SharedDefaults.Key.activeMonitoringProfileID)
            .flatMap(UUID.init(uuidString:))
        let age = max(defaults.integer(forKey: SharedDefaults.Key.activeMonitoringProfileAge), 3)
        let difficulty = max(defaults.integer(forKey: SharedDefaults.Key.activeMonitoringDifficultyLevel), 1)
        let brainBreak = ShieldBrainBreakState.make(
            profileID: profileID,
            age: age,
            difficultyLevel: difficulty
        )
        SharedDefaults.saveShieldBrainBreak(brainBreak, defaults: defaults)

        // Save the question before applying ManagedSettings so the first
        // shield configuration already has both answer buttons available.
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        // The question now lives directly on the system shield. Childlock no
        // longer needs to launch a foreground challenge or ask the child to
        // switch apps again after solving it.
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)
        logger.info(
            "Shield activated for \(selection.applicationTokens.count) apps and \(selection.webDomainTokens.count) web domains"
        )

        clearLegacyBrainBreakNotification()
    }

    private func clearLegacyBrainBreakNotification() {
        let center = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        logger.info("Interval ended: \(activity.rawValue)")
        SharedDefaults.shared.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)
        SharedDefaults.clearShieldBrainBreak()
    }
}
