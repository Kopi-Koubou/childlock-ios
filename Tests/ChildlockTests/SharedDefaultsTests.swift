import XCTest
@testable import Childlock

final class SharedDefaultsTests: XCTestCase {
    func testClearLocalSetupStateRemovesScreenTimeAndSetupKeys() {
        let suiteName = "childlock-shared-defaults-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        SharedDefaults.localSetupStateKeys.forEach { defaults.set("present", forKey: $0) }

        SharedDefaults.clearLocalSetupState(defaults: defaults)

        SharedDefaults.localSetupStateKeys.forEach { key in
            XCTAssertNil(defaults.object(forKey: key), "Expected \(key) to be cleared")
        }

        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.challengePending))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringProfileID))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.activeMonitoringSelectionData))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.familyActivitySelection))
        XCTAssertTrue(SharedDefaults.localSetupStateKeys.contains(SharedDefaults.Key.challengeAlertsEnabled))
    }
}
