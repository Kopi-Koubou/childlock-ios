#if os(iOS) && canImport(DeviceActivity) && canImport(ManagedSettings) && canImport(FamilyControls) && canImport(ManagedSettingsUI)
import DeviceActivity
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import UIKit
import UserNotifications

public final class ChildlockDeviceActivityMonitor: DeviceActivityMonitor {
    private let store = ManagedSettingsStore()
    private let defaults = SharedDefaults.shared

    public override init() {
        super.init()
    }

    public override func intervalDidStart(for activity: DeviceActivityName) {
        defaults.set("interval_started", forKey: SharedDefaults.Key.monitoringStatus)
    }

    public override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        guard event.rawValue == "interval_reached" else {
            return
        }

        guard
            let data = defaults.data(forKey: SharedDefaults.Key.activeMonitoringSelectionData),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            defaults.set(false, forKey: SharedDefaults.Key.challengePending)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            defaults.set(
                ScreenTimeError.invalidMonitoredSelection.localizedDescription,
                forKey: SharedDefaults.Key.monitoringLastError
            )
            return
        }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        defaults.set(true, forKey: SharedDefaults.Key.challengePending)
        defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)

        postBrainBreakNotification()
    }

    private func postBrainBreakNotification() {
        let alertsEnabled = defaults.object(forKey: SharedDefaults.Key.challengeAlertsEnabled) as? Bool ?? true
        guard alertsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Brain break time!"
        content.body = "Tap to solve."
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

        center.add(request)
    }

    public override func intervalDidEnd(for activity: DeviceActivityName) {
        defaults.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }
}

public final class ChildlockShieldAction: ShieldActionDelegate {
    private let defaults = SharedDefaults.shared

    public override init() {
        super.init()
    }

    public override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    public override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handleAction(action, completionHandler: completionHandler)
    }

    public override func handle(
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
        switch action {
        case .primaryButtonPressed:
            defaults.set(true, forKey: SharedDefaults.Key.challengePending)
            defaults.set("challenge_requested", forKey: SharedDefaults.Key.monitoringStatus)
            postBrainBreakNotification()
            completionHandler(.close)
        case .secondaryButtonPressed:
            let requestCount = defaults.integer(forKey: SharedDefaults.Key.moreTimeRequestCount)
            defaults.set(false, forKey: SharedDefaults.Key.challengePending)
            defaults.set(requestCount + 1, forKey: SharedDefaults.Key.moreTimeRequestCount)
            defaults.set(Date(), forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
            defaults.set("more_time_requested", forKey: SharedDefaults.Key.monitoringStatus)
            postMoreTimeNotification()
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    private func postBrainBreakNotification() {
        let alertsEnabled = defaults.object(forKey: SharedDefaults.Key.challengeAlertsEnabled) as? Bool ?? true
        guard alertsEnabled else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Brain break ready"
        content.body = "Tap to solve."
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
        center.add(request)
    }

    private func postMoreTimeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "More time requested"
        content.body = "Give this to your parent."
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

public final class ChildlockShieldConfiguration: ShieldConfigurationDataSource {
    public override init() {
        super.init()
    }

    public override func configuration(shielding application: Application) -> ShieldConfiguration {
        childlockConfiguration
    }

    public override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        childlockConfiguration
    }

    public override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        childlockConfiguration
    }

    public override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        childlockConfiguration
    }

    private var childlockConfiguration: ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(hex: ChildlockColorHex.shieldBg),
            icon: UIImage(systemName: "brain.head.profile"),
            title: ShieldConfiguration.Label(
                text: "Brain Break",
                color: UIColor(hex: ChildlockColorHex.shieldInk)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Tap Start. Then tap the alert.",
                color: UIColor(hex: ChildlockColorHex.shieldInk)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start",
                color: UIColor(hex: ChildlockColorHex.white)
            ),
            primaryButtonBackgroundColor: UIColor(hex: ChildlockColorHex.forestSage),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Parent",
                color: UIColor(hex: ChildlockColorHex.shieldInk)
            )
        )
    }
}
#endif
