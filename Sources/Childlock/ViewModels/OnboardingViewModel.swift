import Foundation
import Observation
#if os(iOS) && canImport(FamilyControls)
import FamilyControls
#endif

public struct OnboardingOutput: Equatable {
    public let profile: ChildProfile
    public let parentPIN: String
    public let selectedMonitoredApps: [String]
    public let selectedActivityTokenData: Data?
    public let authorizationGranted: Bool

    public init(
        profile: ChildProfile,
        parentPIN: String,
        selectedMonitoredApps: [String],
        selectedActivityTokenData: Data?,
        authorizationGranted: Bool
    ) {
        self.profile = profile
        self.parentPIN = parentPIN
        self.selectedMonitoredApps = selectedMonitoredApps
        self.selectedActivityTokenData = selectedActivityTokenData
        self.authorizationGranted = authorizationGranted
    }
}

@MainActor
@Observable
public final class OnboardingViewModel {
    public enum Step: Int, CaseIterable {
        case welcome
        case familySharing
        case devices
        case setup
        case pinAndDone

        var title: String {
            switch self {
            case .welcome: return "Turn screen time into brain time."
            case .familySharing: return "Connect Family Sharing"
            case .devices: return "One setup, every device."
            case .setup: return "Tell us about your child"
            case .pinAndDone: return "You're all set"
            }
        }
    }

    public enum FamilyAuthorizationState: Equatable {
        case notRequested
        case requesting
        case authorized
        case unavailable
        case failed(String)
    }

    public let appChoices = ["YouTube", "Netflix", "Games", "Social Video"]
    public let avatarChoices = [
        "fox", "owl", "bear", "bunny", "cat", "dog",
        "turtle", "penguin", "koala", "lion", "elephant", "panda",
    ]

    public var step: Step = .welcome
    public var familyAuthorizationState: FamilyAuthorizationState = .notRequested

    public var childName: String = ""
    public var childAge: Int = 7
    public var selectedAvatar: String = "fox"
    public var selectedMonitoredApps: Set<String> = [] {
        didSet { persistSelectionIfNeeded() }
    }
    public var selectedActivityTokenData: Data? {
        didSet { persistSelectionIfNeeded() }
    }
    public var selectedInterval: Int = 15
    public var pin: String = ""
    public var pinConfirmation: String = ""

    private var isFinished = false
    private let screenTime: ScreenTimeManaging
    private let selectionStore: FamilyActivitySelectionStoring
    private var isHydratingSelection = false

    public init(
        screenTime: ScreenTimeManaging = ScreenTimeManager.shared,
        selectionStore: FamilyActivitySelectionStoring = AppGroupFamilyActivitySelectionStore()
    ) {
        self.screenTime = screenTime
        self.selectionStore = selectionStore
        hydrateSelectionFromStore()
    }

    public var progressText: String {
        "Step \(step.rawValue + 1) of 5"
    }

    public var canGoBack: Bool {
        step.rawValue > 0 && !isFinished
    }

    public var canContinue: Bool {
        switch step {
        case .welcome:
            return true
        case .familySharing:
            switch familyAuthorizationState {
            case .authorized, .unavailable, .failed:
                return true
            case .notRequested, .requesting:
                return false
            }
        case .devices:
            return true
        case .setup:
            let nameValid = !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let ageValid = (3...12).contains(childAge)
            let intervalValid = [5, 10, 15, 20, 30].contains(selectedInterval)

            var appsValid: Bool
            #if os(iOS) && canImport(FamilyControls)
            if familyAuthorizationState == .authorized {
                appsValid = selectedActivityTokenData != nil
            } else {
                appsValid = !selectedMonitoredApps.isEmpty
            }
            #else
            appsValid = !selectedMonitoredApps.isEmpty
            #endif

            return nameValid && ageValid && appsValid && intervalValid
        case .pinAndDone:
            return pin.count == 4 && pinConfirmation == pin
        }
    }

    public var isComplete: Bool {
        isFinished
    }

    public var shouldShowAuthorizationHelp: Bool {
        switch familyAuthorizationState {
        case .failed, .unavailable:
            return true
        case .notRequested, .requesting, .authorized:
            return false
        }
    }

    public var authorizationStatusText: String {
        switch familyAuthorizationState {
        case .notRequested:
            return "Authorizing lets Childlock trigger brain breaks on your child's selected apps."
        case .requesting:
            return "Requesting Family Sharing permission..."
        case .authorized:
            return "Family Sharing permission granted."
        case .unavailable:
            return "Family Controls is unavailable on this platform. Continue in scoped demo mode."
        case .failed(let message):
            return message
        }
    }

    public func goNext() {
        guard canContinue else { return }

        if step == .pinAndDone {
            isFinished = true
            return
        }

        guard let next = Step(rawValue: step.rawValue + 1) else {
            return
        }
        step = next
    }

    public func goBack() {
        guard canGoBack else { return }
        guard let previous = Step(rawValue: step.rawValue - 1) else {
            return
        }
        step = previous
    }

    public func toggleMonitoredApp(_ appName: String) {
        if selectedMonitoredApps.contains(appName) {
            selectedMonitoredApps.remove(appName)
        } else {
            selectedMonitoredApps.insert(appName)
        }

        selectedActivityTokenData = nil
    }

    public func requestFamilyAuthorization() async {
        familyAuthorizationState = .requesting

        do {
            try await screenTime.requestAuthorization()
            familyAuthorizationState = .authorized
        } catch ScreenTimeError.unavailableOnCurrentPlatform {
            familyAuthorizationState = .unavailable
        } catch {
            familyAuthorizationState = .failed("Authorization failed. You can continue and retry in Settings later.")
        }
    }

    public func buildOutput() -> OnboardingOutput? {
        guard isFinished else { return nil }

        var profile = ChildProfile(
            name: childName,
            age: childAge,
            avatarName: selectedAvatar,
            intervalMinutes: selectedInterval,
            difficultyOverride: .auto
        )
        let monitoredApps = selectedMonitoredApps.sorted()
        profile.setMonitoredSelectionData(selectedActivityTokenData, displayNames: monitoredApps)

        return OnboardingOutput(
            profile: profile,
            parentPIN: pin,
            selectedMonitoredApps: monitoredApps,
            selectedActivityTokenData: selectedActivityTokenData,
            authorizationGranted: familyAuthorizationState == .authorized
        )
    }

    public func clearPersistedSelection() {
        selectionStore.clear()
    }

    public func setTokenizedSelection(tokenData: Data?, displayNames: [String]) {
        selectedActivityTokenData = tokenData
        selectedMonitoredApps = Set(displayNames)
    }

    #if os(iOS) && canImport(FamilyControls)
    public func hydrateFamilyActivitySelection() -> FamilyActivitySelection {
        guard
            let selectedActivityTokenData,
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectedActivityTokenData)
        else {
            return FamilyActivitySelection()
        }

        return selection
    }

    public func updateFamilyActivitySelection(_ selection: FamilyActivitySelection) {
        let tokenData = try? JSONEncoder().encode(selection)
        setTokenizedSelection(
            tokenData: tokenData,
            displayNames: Self.selectionSummaryLabels(for: selection)
        )
    }

    private static func selectionSummaryLabels(for selection: FamilyActivitySelection) -> [String] {
        var labels: [String] = []

        let appCount = selection.applicationTokens.count
        if appCount > 0 {
            labels.append("\(appCount) app token\(appCount == 1 ? "" : "s") selected")
        }

        let categoryCount = selection.categoryTokens.count
        if categoryCount > 0 {
            labels.append("\(categoryCount) category token\(categoryCount == 1 ? "" : "s") selected")
        }

        let domainCount = selection.webDomainTokens.count
        if domainCount > 0 {
            labels.append("\(domainCount) web domain token\(domainCount == 1 ? "" : "s") selected")
        }

        return labels
    }
    #endif

    private func hydrateSelectionFromStore() {
        guard let snapshot = selectionStore.load() else {
            return
        }

        isHydratingSelection = true
        selectedMonitoredApps = Set(snapshot.displayNames)
        selectedActivityTokenData = snapshot.tokenData
        isHydratingSelection = false
    }

    private func persistSelectionIfNeeded() {
        guard !isHydratingSelection else {
            return
        }

        if selectedMonitoredApps.isEmpty, selectedActivityTokenData == nil {
            selectionStore.clear()
            return
        }

        selectionStore.save(
            FamilyActivitySelectionSnapshot(
                tokenData: selectedActivityTokenData,
                displayNames: selectedMonitoredApps.sorted()
            )
        )
    }
}
