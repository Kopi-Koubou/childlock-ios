import Foundation
import XCTest
@testable import Childlock

@MainActor
final class PINServiceTests: XCTestCase {
    func testPINRoundTripAndSessionExpiry() {
        let store = InMemorySecureStore()
        var now = Date()

        let service = PINService(
            secureStore: store,
            sessionTimeout: 300,
            now: { now }
        )

        XCTAssertTrue(service.setPIN("1234"))
        XCTAssertTrue(service.verify("1234"))
        XCTAssertTrue(service.isSessionUnlocked)

        now = now.addingTimeInterval(299)
        XCTAssertTrue(service.isSessionUnlocked)

        now = now.addingTimeInterval(2)
        XCTAssertFalse(service.isSessionUnlocked)
    }

    func testWrongPINDoesNotUnlockSession() {
        let store = InMemorySecureStore()
        let service = PINService(secureStore: store)

        XCTAssertTrue(service.setPIN("1234"))
        XCTAssertFalse(service.verify("9999"))
        XCTAssertFalse(service.isSessionUnlocked)
    }

    func testLockSessionResetsAccess() {
        let store = InMemorySecureStore()
        let service = PINService(secureStore: store)

        XCTAssertTrue(service.setPIN("5555"))
        XCTAssertTrue(service.verify("5555"))
        XCTAssertTrue(service.isSessionUnlocked)

        service.lockSession()
        XCTAssertFalse(service.isSessionUnlocked)
    }
}
