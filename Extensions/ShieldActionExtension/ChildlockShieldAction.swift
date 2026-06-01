import DeviceActivity
import Foundation
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import os

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
            completionHandler(.defer)
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
    }

    private func handleRequestMoreTime() {
        logger.info("User requested more time")

        let defaults = SharedDefaults.shared
        let requestCount = defaults.integer(forKey: SharedDefaults.Key.moreTimeRequestCount)
        defaults.set(requestCount + 1, forKey: SharedDefaults.Key.moreTimeRequestCount)
        defaults.set(Date(), forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
        defaults.set("more_time_requested", forKey: SharedDefaults.Key.monitoringStatus)

        logger.info("More time request recorded (count: \(requestCount + 1))")
    }
}
