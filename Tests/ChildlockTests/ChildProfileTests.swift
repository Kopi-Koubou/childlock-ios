import XCTest
@testable import Childlock

final class ChildProfileTests: XCTestCase {
    func testSetMonitoredSelectionDataPersistsDisplayNames() {
        var profile = ChildProfile(name: "Mia", age: 7, avatarName: "fox", intervalMinutes: 15)
        let tokenData = Data([0x01, 0x02, 0x03])

        profile.setMonitoredSelectionData(
            tokenData,
            displayNames: ["YouTube", "Games", "YouTube", ""]
        )

        XCTAssertEqual(profile.monitoredSelectionTokenData, tokenData)
        XCTAssertEqual(profile.monitoredAppDisplayNames, ["YouTube", "Games"])
    }

    func testMonitoredAppDisplayNamesSupportsLegacyStringArrayPayload() {
        var profile = ChildProfile(name: "Leo", age: 8, avatarName: "owl", intervalMinutes: 10)
        profile.monitoredActivitiesData = try? JSONEncoder().encode(["Netflix", "Games"])

        XCTAssertNil(profile.monitoredSelectionTokenData)
        XCTAssertEqual(profile.monitoredAppDisplayNames, ["Netflix", "Games"])
    }
}

