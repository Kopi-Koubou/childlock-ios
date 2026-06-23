import XCTest
@testable import Childlock

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testWelcomeStepRequiresSignupBeforeContinuing() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )

        XCTAssertEqual(viewModel.step, .welcome)
        XCTAssertFalse(viewModel.canContinue)

        viewModel.goNext()
        XCTAssertEqual(viewModel.step, .welcome)

        viewModel.markSignupComplete()
        XCTAssertTrue(viewModel.canContinue)

        viewModel.goNext()
        XCTAssertEqual(viewModel.step, .familySharing)
    }

    func testCompletionFailureKeepsOnboardingOpenAndShowsError() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .pinAndDone
        viewModel.familyAuthorizationState = .authorized
        viewModel.pin = "1234"
        viewModel.pinConfirmation = "1234"

        viewModel.goNext()
        XCTAssertTrue(viewModel.isComplete)

        viewModel.failCompletion("Could not save PIN.")

        XCTAssertFalse(viewModel.isComplete)
        XCTAssertEqual(viewModel.completionErrorText, "Could not save PIN.")
    }

    func testFamilyAuthorizationStepRequiresAuthorizationAttempt() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .familySharing

        XCTAssertFalse(viewModel.canContinue)

        viewModel.familyAuthorizationState = .authorized
        XCTAssertTrue(viewModel.canContinue)
    }

    func testBuildOutputIncludesProfileAndMonitoredApps() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.childName = "Mia"
        viewModel.childAge = 6
        viewModel.selectedAvatar = "owl"
        viewModel.selectedInterval = 20
        viewModel.pin = "1234"
        viewModel.pinConfirmation = "1234"
        viewModel.familyAuthorizationState = .authorized
        viewModel.selectedMonitoredApps = ["YouTube", "Games"]
        viewModel.step = .pinAndDone
        viewModel.goNext() // triggers isFinished

        guard let output = viewModel.buildOutput() else {
            XCTFail("Expected onboarding output")
            return
        }

        XCTAssertEqual(output.profile.name, "Mia")
        XCTAssertEqual(output.profile.age, 6)
        XCTAssertEqual(output.profile.avatarName, "owl")
        XCTAssertEqual(output.profile.intervalMinutes, 20)
        XCTAssertEqual(output.parentPIN, "1234")
        XCTAssertEqual(output.selectedMonitoredApps, ["Games", "YouTube"])
        XCTAssertEqual(output.profile.monitoredAppDisplayNames, ["Games", "YouTube"])
        XCTAssertTrue(output.authorizationGranted)
    }

    func testRequestFamilyAuthorizationUnavailableMode() async {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: false, unavailable: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .familySharing

        await viewModel.requestFamilyAuthorization()

        XCTAssertEqual(viewModel.familyAuthorizationState, .unavailable)
        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(
            viewModel.authorizationStatusText,
            "Screen Time controls are unavailable here. Install Childlock on the child-used iPhone or iPad and try again."
        )
    }

    func testFailedFamilyAuthorizationCannotContinue() async {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: false),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .familySharing

        await viewModel.requestFamilyAuthorization()

        XCTAssertEqual(
            viewModel.familyAuthorizationState,
            .failed("Screen Time access is required before Childlock can pause apps. Please try again.")
        )
        XCTAssertFalse(viewModel.canContinue)
    }

    func testInitHydratesSelectionFromStore() {
        let selectionStore = InMemorySelectionStore()
        selectionStore.snapshot = FamilyActivitySelectionSnapshot(
            tokenData: Data([0x1, 0x2]),
            displayNames: ["2 apps selected"]
        )

        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: selectionStore
        )

        XCTAssertEqual(viewModel.selectedActivityTokenData, Data([0x1, 0x2]))
        XCTAssertEqual(viewModel.selectedMonitoredApps, ["2 apps selected"])
    }

    func testSetupStepExplainsMissingRequiredInput() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .setup

        XCTAssertEqual(viewModel.setupBlockingReason, "Enter your child's name above.")

        viewModel.childName = "Mia"
        XCTAssertEqual(viewModel.setupBlockingReason, "Allow Screen Time access before choosing monitored apps.")

        viewModel.familyAuthorizationState = .authorized
        XCTAssertEqual(viewModel.setupBlockingReason, "Choose at least one monitored app.")

        viewModel.selectedMonitoredApps = ["Games"]
        XCTAssertNil(viewModel.setupBlockingReason)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testAuthorizedSetupRequiresTokenizedScreenTimeSelection() {
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: InMemorySelectionStore()
        )
        viewModel.step = .setup
        viewModel.familyAuthorizationState = .authorized
        viewModel.childName = "Mia"

        #if os(iOS) && canImport(FamilyControls)
        XCTAssertEqual(
            viewModel.setupBlockingReason,
            "Choose at least one app, category, or website in the Screen Time picker, then tap Done."
        )

        viewModel.selectedMonitoredApps = ["Games"]

        XCTAssertEqual(
            viewModel.setupBlockingReason,
            "Choose at least one app, category, or website in the Screen Time picker, then tap Done."
        )
        XCTAssertFalse(viewModel.canContinue)

        viewModel.setTokenizedSelection(
            tokenData: Data([0x1, 0x2]),
            displayNames: ["1 category selected"]
        )

        XCTAssertNil(viewModel.setupBlockingReason)
        XCTAssertTrue(viewModel.canContinue)
        #else
        XCTAssertEqual(viewModel.setupBlockingReason, "Choose at least one monitored app.")

        viewModel.selectedMonitoredApps = ["Games"]

        XCTAssertNil(viewModel.setupBlockingReason)
        XCTAssertTrue(viewModel.canContinue)
        #endif
    }

    func testEmptyTokenizedSelectionDoesNotCountAsSelected() {
        let selectionStore = InMemorySelectionStore()
        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: selectionStore
        )

        viewModel.setTokenizedSelection(tokenData: Data([0x1, 0x2]), displayNames: ["  "])

        XCTAssertNil(viewModel.selectedActivityTokenData)
        XCTAssertTrue(viewModel.selectedMonitoredApps.isEmpty)
        XCTAssertNil(selectionStore.snapshot)
    }
}

private final class InMemorySelectionStore: FamilyActivitySelectionStoring {
    var snapshot: FamilyActivitySelectionSnapshot?

    func load() -> FamilyActivitySelectionSnapshot? {
        snapshot
    }

    func save(_ snapshot: FamilyActivitySelectionSnapshot) {
        self.snapshot = snapshot
    }

    func clear() {
        snapshot = nil
    }
}

@MainActor
private final class TestScreenTimeManager: ScreenTimeManaging {
    var isAuthorized: Bool = false

    private let shouldAuthorize: Bool
    private let unavailable: Bool

    init(shouldAuthorize: Bool, unavailable: Bool = false) {
        self.shouldAuthorize = shouldAuthorize
        self.unavailable = unavailable
    }

    func requestAuthorization() async throws {
        if unavailable {
            throw ScreenTimeError.unavailableOnCurrentPlatform
        }

        if shouldAuthorize {
            isAuthorized = true
            return
        }

        struct AuthorizationFailure: Error {}
        throw AuthorizationFailure()
    }

    func applyShields(for profile: ChildProfile) {
        _ = profile
    }

    func removeShields() {}

    func startMonitoring(profile: ChildProfile) throws {
        _ = profile
    }

    func stopMonitoring(profile: ChildProfile) {
        _ = profile
    }
}
