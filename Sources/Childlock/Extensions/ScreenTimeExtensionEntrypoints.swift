#if os(iOS) && canImport(DeviceActivity) && canImport(ManagedSettings) && canImport(FamilyControls) && canImport(ManagedSettingsUI)
import DeviceActivity
import FamilyControls
import Foundation
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

        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens
        store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)

        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)

        clearLegacyBrainBreakNotification()
    }

    private func clearLegacyBrainBreakNotification() {
        let center = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    public override func intervalDidEnd(for activity: DeviceActivityName) {
        defaults.set("interval_ended", forKey: SharedDefaults.Key.monitoringStatus)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        SharedDefaults.clearShieldBrainBreak(defaults: defaults)
    }
}

public final class ChildlockShieldAction: ShieldActionDelegate {
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let defaults = SharedDefaults.shared
    private let activeActivityName = DeviceActivityName("childlock.active")
    private let thresholdEventName = DeviceActivityEvent.Name("interval_reached")
    private let successDisplayDuration: TimeInterval = 1.0
    private let completionLock = NSLock()
    private var respondedBrainBreakIDs = Set<UUID>()
    private var finishedBrainBreakIDs = Set<UUID>()

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
            submitAnswer(at: 0, completionHandler: completionHandler)
        case .secondaryButtonPressed:
            submitAnswer(at: 1, completionHandler: completionHandler)
        @unknown default:
            completionHandler(.none)
        }
    }

    private func submitAnswer(
        at answerIndex: Int,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        guard var brainBreak = SharedDefaults.shieldBrainBreak(defaults: defaults) else {
            completionHandler(.defer)
            return
        }

        guard brainBreak.phase != .success else {
            completionHandler(.defer)
            return
        }

        let outcome = brainBreak.submit(answerIndex: answerIndex)
        SharedDefaults.saveShieldBrainBreak(brainBreak, defaults: defaults)

        guard outcome == .success else {
            completionHandler(.defer)
            return
        }

        SharedDefaults.appendShieldBrainBreakCompletion(
            ShieldBrainBreakCompletion(state: brainBreak),
            defaults: defaults
        )
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        clearLegacyBrainBreakNotification()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        beginAutomaticReturn(
            for: brainBreak.id,
            completionHandler: completionHandler
        )
    }

    private func beginAutomaticReturn(
        for brainBreakID: UUID,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        ProcessInfo.processInfo.performExpiringActivity(
            withReason: "Dismiss completed Childlock brain break"
        ) { [self] expired in
            if let response = claimResponse(for: brainBreakID, expired: expired) {
                completionHandler(response)
            }

            if expired {
                finishSuccessfulBrainBreak(id: brainBreakID)
                return
            }

            Thread.sleep(forTimeInterval: successDisplayDuration)
            finishSuccessfulBrainBreak(id: brainBreakID)
        }
    }

    private func claimResponse(
        for brainBreakID: UUID,
        expired: Bool
    ) -> ShieldActionResponse? {
        completionLock.lock()
        defer { completionLock.unlock() }

        guard respondedBrainBreakIDs.insert(brainBreakID).inserted else {
            return nil
        }
        return expired ? .none : .defer
    }

    private func finishSuccessfulBrainBreak(id brainBreakID: UUID) {
        completionLock.lock()
        let shouldFinish = finishedBrainBreakIDs.insert(brainBreakID).inserted
        completionLock.unlock()
        guard shouldFinish else { return }

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        SharedDefaults.clearShieldBrainBreak(defaults: defaults)
        rearmMonitoring()
    }

    private func rearmMonitoring() {
        guard
            let data = defaults.data(forKey: SharedDefaults.Key.activeMonitoringSelectionData),
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            defaults.set("The monitored app selection payload is invalid.", forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            return
        }

        let intervalMinutes = max(
            defaults.integer(forKey: SharedDefaults.Key.activeMonitoringIntervalMinutes),
            1
        )
        let rapidTestIntervalSeconds = ChildlockRapidTesting.sanitizedIntervalSeconds(
            defaults.object(forKey: SharedDefaults.Key.activeMonitoringIntervalSeconds) as? Int
        )
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: ChildlockRapidTesting.threshold(
                intervalMinutes: intervalMinutes,
                rapidTestIntervalSeconds: rapidTestIntervalSeconds
            )
        )

        center.stopMonitoring([activeActivityName])
        do {
            try center.startMonitoring(
                activeActivityName,
                during: schedule,
                events: [thresholdEventName: event]
            )
            defaults.removeObject(forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.Key.monitoringLastStartedAt)
            defaults.set("running", forKey: SharedDefaults.Key.monitoringStatus)
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
        }
    }

    private func clearLegacyBrainBreakNotification() {
        let notificationCenter = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
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
        let shieldBackground = UIColor(hex: ChildlockColorHex.shieldBg)
        let shieldForeground = UIColor(hex: ChildlockColorHex.shieldInk)

        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let symbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: isIPad ? 72 : 48,
            weight: .semibold
        )

        guard let brainBreak = SharedDefaults.shieldBrainBreak() else {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: shieldBackground,
                icon: UIImage(
                    systemName: "brain.head.profile",
                    withConfiguration: symbolConfiguration
                ),
                title: ShieldConfiguration.Label(text: "Brain Break", color: shieldForeground),
                subtitle: ShieldConfiguration.Label(
                    text: "One moment…",
                    color: shieldForeground.withAlphaComponent(0.7)
                )
            )
        }

        if brainBreak.phase == .success {
            return ShieldConfiguration(
                backgroundBlurStyle: .systemMaterial,
                backgroundColor: shieldBackground,
                icon: UIImage(
                    systemName: "checkmark.circle.fill",
                    withConfiguration: symbolConfiguration
                ),
                title: ShieldConfiguration.Label(text: "Great job!", color: shieldForeground),
                subtitle: ShieldConfiguration.Label(
                    text: "Going back to your app…",
                    color: shieldForeground.withAlphaComponent(0.7)
                )
            )
        }

        let titleText = isIPad ? brainBreak.prompt : brainBreak.guidanceText
        let subtitleText = isIPad ? brainBreak.guidanceText : brainBreak.prompt

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: shieldBackground,
            icon: UIImage(
                systemName: "brain.head.profile",
                withConfiguration: symbolConfiguration
            ),
            title: ShieldConfiguration.Label(
                text: titleText,
                color: shieldForeground
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: shieldForeground.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: brainBreak.primaryAnswer,
                color: UIColor(hex: ChildlockColorHex.white)
            ),
            primaryButtonBackgroundColor: UIColor(hex: ChildlockColorHex.forestSage),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: brainBreak.secondaryAnswer,
                color: shieldForeground
            )
        )
    }
}
#endif
