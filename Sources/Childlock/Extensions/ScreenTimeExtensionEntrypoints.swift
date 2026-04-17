#if os(iOS) && canImport(DeviceActivity) && canImport(ManagedSettings) && canImport(FamilyControls) && canImport(ManagedSettingsUI)
import DeviceActivity
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import UIKit

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
            return
        }

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
    }

    public override func intervalDidEnd(for activity: DeviceActivityName) {
        defaults.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
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
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
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
            backgroundColor: UIColor(hex: ChildlockColorHex.cream),
            icon: UIImage(systemName: "brain.head.profile"),
            title: ShieldConfiguration.Label(
                text: "Brain Break!",
                color: UIColor(hex: ChildlockColorHex.sunriseOrange)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Solve one quick challenge to keep going.",
                color: UIColor(hex: ChildlockColorHex.charcoal)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Start Challenge",
                color: UIColor(hex: ChildlockColorHex.warmWhite)
            ),
            primaryButtonBackgroundColor: UIColor(hex: ChildlockColorHex.sunriseOrange),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(hex: ChildlockColorHex.charcoal)
            )
        )
    }
}
#endif
