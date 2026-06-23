import XCTest
@testable import Childlock

final class ChildlockMonitoringStatusTests: XCTestCase {
    func testRearmableStatuses() {
        let rearmable: Set<ChildlockMonitoringStatus> = [
            .running,
            .intervalStarted,
            .thresholdReached,
            .challengeRequested,
            .moreTimeRequested,
        ]

        for status in ChildlockMonitoringStatus.allCases {
            XCTAssertEqual(
                status.canRearmMonitoring,
                rearmable.contains(status),
                "\(status.rawValue) re-arm behavior changed unexpectedly"
            )
        }
    }

    func testStoredValueParsing() {
        XCTAssertEqual(ChildlockMonitoringStatus(storedValue: "more_time_requested"), .moreTimeRequested)
        XCTAssertNil(ChildlockMonitoringStatus(storedValue: nil))
        XCTAssertNil(ChildlockMonitoringStatus(storedValue: "unknown_status"))
    }
}
