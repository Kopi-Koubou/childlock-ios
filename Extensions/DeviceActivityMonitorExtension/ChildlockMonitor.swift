import DeviceActivity
import FamilyControls
import ManagedSettings
import os

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
        defaults.set(true, forKey: SharedDefaults.Key.challengePending)
        defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)
        
        guard
            let data = defaults.data(forKey: SharedDefaults.Key.activeMonitoringSelectionData),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            defaults.set(
                ScreenTimeError.invalidMonitoredSelection.localizedDescription,
                forKey: SharedDefaults.Key.monitoringLastError
            )
            logger.error("Invalid monitored selection")
            return
        }
        
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        logger.info("Shield activated for \(selection.applicationTokens.count) apps")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        logger.info("Interval ended: \(activity.rawValue)")
        SharedDefaults.shared.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
}
