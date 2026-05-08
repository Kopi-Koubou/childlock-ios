import XCTest
@testable import Childlock

@MainActor
final class OnboardingViewModelTests: XCTestCase {
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
        await viewModel.requestFamilyAuthorization()

        XCTAssertEqual(viewModel.familyAuthorizationState, .unavailable)
        XCTAssertTrue(viewModel.canContinue)
    }

    func testInitHydratesSelectionFromStore() {
        let selectionStore = InMemorySelectionStore()
        selectionStore.snapshot = FamilyActivitySelectionSnapshot(
            tokenData: Data([0x1, 0x2]),
            displayNames: ["2 app tokens selected"]
        )

        let viewModel = OnboardingViewModel(
            screenTime: TestScreenTimeManager(shouldAuthorize: true),
            selectionStore: selectionStore
        )

        XCTAssertEqual(viewModel.selectedActivityTokenData, Data([0x1, 0x2]))
        XCTAssertEqual(viewModel.selectedMonitoredApps, ["2 app tokens selected"])
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
