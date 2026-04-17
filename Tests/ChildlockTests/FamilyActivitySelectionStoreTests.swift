import XCTest
@testable import Childlock

final class FamilyActivitySelectionStoreTests: XCTestCase {
    func testAppGroupSelectionStoreRoundTrip() {
        let suiteName = "childlock.tests.selection.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Expected isolated defaults suite")
            return
        }

        let key = "familyActivitySelection.test"
        let store = AppGroupFamilyActivitySelectionStore(defaults: defaults, key: key)
        let snapshot = FamilyActivitySelectionSnapshot(
            tokenData: Data([0xA, 0xB]),
            displayNames: ["2 app tokens selected", "1 category token selected"]
        )

        store.save(snapshot)
        let loaded = store.load()

        XCTAssertEqual(loaded, snapshot)

        store.clear()
        XCTAssertNil(store.load())
        defaults.removePersistentDomain(forName: suiteName)
    }
}

