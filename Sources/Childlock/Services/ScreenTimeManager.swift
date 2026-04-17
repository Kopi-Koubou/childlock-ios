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
            try await AuthorizationCenter.shared.requestAuthorization(for: .child)
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
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            removeShields()
        }
    }

    public func removeShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
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
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            defaults.set(
                ScreenTimeError.missingMonitoredSelection.localizedDescription,
                forKey: SharedDefaults.Key.monitoringLastError
            )
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw ScreenTimeError.missingMonitoredSelection
        }

        let activityName = activityName(for: profile.id)
        center.stopMonitoring([activityName])

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(minute: max(profile.intervalMinutes, 1))
        )

        do {
            try center.startMonitoring(
                activityName,
                during: schedule,
                events: [DeviceActivityEvent.Name("interval_reached"): event]
            )
        } catch {
            defaults.set(error.localizedDescription, forKey: SharedDefaults.Key.monitoringLastError)
            defaults.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            throw ScreenTimeError.monitoringFailed(error.localizedDescription)
        }

        applyShields(for: profile)
        defaults.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeMonitoringProfileID)
        defaults.set(profile.monitoredSelectionTokenData, forKey: SharedDefaults.Key.activeMonitoringSelectionData)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.Key.monitoringLastStartedAt)
        defaults.removeObject(forKey: SharedDefaults.Key.monitoringLastError)
        defaults.set("running", forKey: SharedDefaults.Key.monitoringStatus)
    }

    public func stopMonitoring(profile: ChildProfile) {
        let activityName = activityName(for: profile.id)
        center.stopMonitoring([activityName])
        removeShields()

        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringProfileID)
        defaults.removeObject(forKey: SharedDefaults.Key.activeMonitoringSelectionData)
        defaults.set("stopped", forKey: SharedDefaults.Key.monitoringStatus)
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

    private func activityName(for profileID: UUID) -> DeviceActivityName {
        DeviceActivityName("childlock.\(profileID.uuidString)")
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

