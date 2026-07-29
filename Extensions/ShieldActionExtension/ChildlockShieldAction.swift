import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import os
import UIKit
import UserNotifications

@available(iOS 17.0, *)
final class ChildlockShieldAction: ShieldActionDelegate {
    private let logger = Logger(subsystem: "com.kopikoubou.childlock.shield-action", category: "ShieldAction")
    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let defaults = SharedDefaults.shared
    private let activeActivityName = DeviceActivityName("childlock.active")
    private let thresholdEventName = DeviceActivityEvent.Name("interval_reached")
    private let successDisplayDuration: TimeInterval = 1.0
    private let completionLock = NSLock()
    private var respondedBrainBreakIDs = Set<UUID>()
    private var finishedBrainBreakIDs = Set<UUID>()

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
            submitAnswer(at: 0, completionHandler: completionHandler)
        case .secondaryButtonPressed:
            submitAnswer(at: 1, completionHandler: completionHandler)
        @unknown default:
            logger.warning("Unknown shield action: \(action.rawValue)")
            completionHandler(.none)
        }
    }

    private func submitAnswer(
        at answerIndex: Int,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        guard var brainBreak = SharedDefaults.shieldBrainBreak(defaults: defaults) else {
            logger.error("Shield answer arrived without an active brain break")
            completionHandler(.defer)
            return
        }

        guard brainBreak.phase != .success else {
            completionHandler(.defer)
            return
        }

        let isCorrect = brainBreak.submit(answerIndex: answerIndex)
        SharedDefaults.saveShieldBrainBreak(brainBreak, defaults: defaults)

        guard isCorrect else {
            logger.info("Shield brain break answer was incorrect")
            completionHandler(.defer)
            return
        }

        logger.info("Shield brain break completed; showing success before automatic return")
        SharedDefaults.appendShieldBrainBreakCompletion(
            ShieldBrainBreakCompletion(state: brainBreak),
            defaults: defaults
        )
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        clearLegacyBrainBreakNotification()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // `.defer` asks the system to redraw the shield from the newly saved
        // success state. An expiring activity is the extension-safe way to
        // request enough execution time to clear ManagedSettings one second
        // later. If iOS cannot grant or later expires that assertion, clear
        // immediately so the child is never stranded on the success shield.
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
                logger.warning("Success display activity expired; clearing shield immediately")
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
            logger.error("Could not re-arm monitoring after shield brain break")
            return
        }

        let intervalMinutes = max(
            defaults.integer(forKey: SharedDefaults.Key.activeMonitoringIntervalMinutes),
            1
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
            threshold: DateComponents(minute: intervalMinutes)
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
            logger.info("Monitoring re-armed after shield brain break")
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            logger.error("Failed to re-arm monitoring: \(error.localizedDescription)")
        }
    }

    private func clearLegacyBrainBreakNotification() {
        let center = UNUserNotificationCenter.current()
        let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
