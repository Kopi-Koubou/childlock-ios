import Foundation

@MainActor
public protocol ScreenTimeManaging: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func applyShields(for profile: ChildProfile)
    func removeShields()
    func startMonitoring(profile: ChildProfile) throws
    func stopMonitoring(profile: ChildProfile)
}

public enum ScreenTimeError: LocalizedError {
    case unavailableOnCurrentPlatform
    case authorizationRequired
    case authorizationDenied
    case entitlementMissing
    case missingMonitoredSelection
    case invalidMonitoredSelection
    case monitoringFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unavailableOnCurrentPlatform:
            return "Screen Time APIs are unavailable on this platform."
        case .authorizationRequired:
            return "Screen Time authorization is required before monitoring can start."
        case .authorizationDenied:
            return "Screen Time authorization was denied."
        case .entitlementMissing:
            return "Required Family Controls entitlements are missing."
        case .missingMonitoredSelection:
            return "No monitored apps/categories were selected."
        case .invalidMonitoredSelection:
            return "The monitored app selection payload is invalid."
        case .monitoringFailed(let reason):
            return "Failed to start monitoring: \(reason)"
        }
    }
}

#if os(iOS) && canImport(FamilyControls) && canImport(ManagedSettings) && canImport(DeviceActivity)
import DeviceActivity
import FamilyControls
import ManagedSettings

@MainActor
public final class ScreenTimeManager: ScreenTimeManaging {
    public static let shared = ScreenTimeManager()

    public private(set) var isAuthorized = false

    private let store: ManagedSettingsStore
    private let center: DeviceActivityCenter
    private let defaults: UserDefaults
    private let activeActivityName = DeviceActivityName("childlock.active")

    public init(
        store: ManagedSettingsStore = ManagedSettingsStore(),
        center: DeviceActivityCenter = DeviceActivityCenter(),
        defaults: UserDefaults = SharedDefaults.shared
    ) {
        self.store = store
        self.center = center
        self.defaults = defaults
        refreshAuthorizationStatus()
    }

    public func requestAuthorization() async throws {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            refreshAuthorizationStatus()

            guard isAuthorized else {
                defaults.set("denied", forKey: SharedDefaults.Key.monitoringStatus)
                throw ScreenTimeError.authorizationDenied
            }
        } catch {
            if isLikelyEntitlementError(error) {
                defaults.set(
                    ScreenTimeError.entitlementMissing.localizedDescription,
                    forKey: SharedDefaults.Key.monitoringLastError
                )
                defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
                throw ScreenTimeError.entitlementMissing
            }

            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw error
        }
    }

    public func applyShields(for profile: ChildProfile) {
        do {
            let selection = try decodeSelection(for: profile)
            store.shield.applications = selection.applicationTokens
            store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
            store.shield.webDomains = selection.webDomainTokens
            store.shield.webDomainCategories = selection.categoryTokens.isEmpty ? nil : .specific(selection.categoryTokens)
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            removeShields()
        }
    }

    public func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
    }

    public func startMonitoring(profile: ChildProfile) throws {
        refreshAuthorizationStatus()
        guard isAuthorized else {
            defaults.set(
                ScreenTimeError.authorizationRequired.localizedDescription,
                forKey: SharedDefaults.Key.monitoringLastError
            )
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw ScreenTimeError.authorizationRequired
        }

        let selection = try decodeSelection(for: profile)
        guard
            !selection.applicationTokens.isEmpty ||
                !selection.categoryTokens.isEmpty ||
                !selection.webDomainTokens.isEmpty
        else {
            defaults.set(
                ScreenTimeError.missingMonitoredSelection.localizedDescription,
                forKey: SharedDefaults.Key.monitoringLastError
            )
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw ScreenTimeError.missingMonitoredSelection
        }

        // Launch supports one active child per configured device. Reusing one
        // DeviceActivity name prevents old sibling monitors from firing after
        // the parent switches the active child before handoff.
        center.stopMonitoring([activeActivityName])

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(minute: max(profile.intervalMinutes, 1))
        )

        do {
            try center.startMonitoring(
                activeActivityName,
                during: schedule,
                events: [DeviceActivityEvent.Name("interval_reached"): event]
            )
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw ScreenTimeError.monitoringFailed(error.localizedDescription)
        }

        // Shields are applied by the DeviceActivity monitor extension when the
        // usage threshold fires — not here, so the child gets their first
        // interval of normal use before the first brain break.
        clearTransientShieldState()
        defaults.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeMonitoringProfileID)
        defaults.set(profile.monitoredSelectionTokenData, forKey: SharedDefaults.Key.activeMonitoringSelectionData)
        defaults.set(profile.intervalMinutes, forKey: SharedDefaults.Key.activeMonitoringIntervalMinutes)
        defaults.set(profile.age, forKey: SharedDefaults.Key.activeMonitoringProfileAge)
        defaults.set(
            ChallengeEngine.shared.effectiveDifficulty(for: profile),
            forKey: SharedDefaults.Key.activeMonitoringDifficultyLevel
        )
        defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.Key.monitoringLastStartedAt)
        defaults.removeObject(forKey: SharedDefaults.Key.monitoringLastError)
        defaults.set("running", forKey: SharedDefaults.Key.monitoringStatus)
    }

    public func stopMonitoring(profile: ChildProfile) {
        center.stopMonitoring([activeActivityName])
        removeShields()
        clearTransientShieldState()

        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringProfileID)
        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringSelectionData)
        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringIntervalMinutes)
        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringProfileAge)
        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringDifficultyLevel)
        defaults.set("stopped", forKey: SharedDefaults.Key.monitoringStatus)
    }

    private func clearTransientShieldState() {
        defaults.set(false, forKey: SharedDefaults.Key.challengePending)
        defaults.set(0, forKey: SharedDefaults.Key.moreTimeRequestCount)
        defaults.removeObject(forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
        defaults.removeObject(forKey: SharedDefaults.Key.dailyLimitReachedAt)
        SharedDefaults.clearShieldBrainBreak(defaults: defaults)
        NotificationService.clearShieldFlowAlerts()
    }

    private func decodeSelection(for profile: ChildProfile) throws -> FamilyActivitySelection {
        guard
            let data = profile.monitoredSelectionTokenData ?? defaults.data(forKey: SharedDefaults.Key.activeMonitoringSelectionData)
        else {
            throw ScreenTimeError.missingMonitoredSelection
        }

        guard let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            throw ScreenTimeError.invalidMonitoredSelection
        }

        return selection
    }

    private func refreshAuthorizationStatus() {
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    private func isLikelyEntitlementError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let diagnostic = "\(nsError.domain) \(nsError.localizedDescription)".lowercased()
        return diagnostic.contains("entitlement")
            || diagnostic.contains("not permitted")
            || diagnostic.contains("authorization")
    }
}
#else
@MainActor
public final class ScreenTimeManager: ScreenTimeManaging {
    public static let shared = ScreenTimeManager()

    public private(set) var isAuthorized = false

    public init() {}

    public func requestAuthorization() async throws {
        throw ScreenTimeError.unavailableOnCurrentPlatform
    }

    public func applyShields(for profile: ChildProfile) {
        _ = profile
    }

    public func removeShields() {}

    public func startMonitoring(profile: ChildProfile) throws {
        _ = profile
    }

    public func stopMonitoring(profile: ChildProfile) {
        _ = profile
    }
}
#endif

public final class MockScreenTimeManager: ScreenTimeManaging {
    public private(set) var isAuthorized = false
    public private(set) var shieldsApplied = false
    public private(set) var shieldsRemoved = false
    public private(set) var monitoredProfileIDs: [UUID] = []

    public init() {}

    public func requestAuthorization() async throws {
        isAuthorized = true
    }

    public func applyShields(for profile: ChildProfile) {
        shieldsApplied = true
        monitoredProfileIDs.append(profile.id)
    }

    public func removeShields() {
        shieldsRemoved = true
        shieldsApplied = false
    }

    public func startMonitoring(profile: ChildProfile) throws {
        monitoredProfileIDs.append(profile.id)
    }

    public func stopMonitoring(profile: ChildProfile) {
        monitoredProfileIDs.removeAll { $0 == profile.id }
    }
}
