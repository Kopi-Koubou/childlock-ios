import XCTest

final class HandBackCopyTests: XCTestCase {
    func testHandBackKeepsChildInstructionPrimaryAndParentEntryVisible() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Challenges/HandBackView.swift")

        XCTAssertTrue(contents.contains("Head back to your app. It's unlocked."))
        XCTAssertTrue(contents.contains("Label(\"I'm a parent\", systemImage: \"lock.fill\")"))
        XCTAssertTrue(contents.contains("accessibilityLabel(\"parent_unlock_entry\")"))
        XCTAssertTrue(contents.contains("SecureField(\"Parent PIN\""))
        XCTAssertTrue(contents.contains("Unlock Dashboard"))
        XCTAssertTrue(contents.contains("sanitizeEnteredPIN()"))
        XCTAssertTrue(contents.contains("prefix(4)"))
        XCTAssertTrue(contents.contains("if !enteredPIN.isEmpty {\n                pinErrorText = nil\n            }"))
    }

    func testParentDashboardPINEntryIsBoundedAndClearsAfterFailure() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(contents.contains(".onChange(of: enteredPIN)"))
        XCTAssertTrue(contents.contains("sanitizeEnteredPIN()"))
        XCTAssertTrue(contents.contains("prefix(4)"))
        XCTAssertTrue(contents.contains("pinErrorText = unlocked ? nil : \"Incorrect PIN. Try again.\""))
        XCTAssertTrue(contents.contains("} else {\n            enteredPIN = \"\"\n        }"))
        XCTAssertTrue(contents.contains("if !enteredPIN.isEmpty {\n                pinErrorText = nil\n            }"))
    }

    func testWelcomeCopyAvoidsAbsoluteBehaviorClaims() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")

        XCTAssertTrue(contents.contains("fewer battles"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("no tantrums"))
    }

    func testAppsCopyAvoidsAlwaysAvailableOverpromises() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(contents.contains("Only the apps, categories, or websites you choose are targeted."))
        XCTAssertTrue(contents.contains("Keep calls, messages, and school apps out of the selection"))
        XCTAssertTrue(contents.contains("Screen Time selection protects real apps on this device."))
        XCTAssertTrue(contents.contains("Planning labels help simulator setup, but they do not lock apps until Screen Time access is enabled."))
        XCTAssertTrue(contents.contains("For a separate child iPad, install and configure Childlock on that iPad too."))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("never interrupted"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("app token"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("category token"))
    }

    func testParentChildDeviceModelIsClearInAppCopy() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(onboarding.contains("Shared iPhone? Set it up here."))
        XCTAssertTrue(onboarding.contains("Child iPad? Install and run this setup on the iPad"))
        XCTAssertTrue(onboarding.contains("a parent-only iPhone install will not lock the iPad in v1"))

        XCTAssertTrue(dashboard.contains("Locks apps on this device only."))
        XCTAssertTrue(dashboard.contains("For a child iPad, install and configure Childlock on the iPad."))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("remotely lock"))
    }

    func testParentDashboardUsesReadableContentWidthOnIPad() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("dashboardContentMaxWidth"))
        XCTAssertTrue(dashboard.contains("parentLockContentMaxWidth"))
        XCTAssertTrue(dashboard.contains(".frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)"))
        XCTAssertTrue(dashboard.contains(".frame(maxWidth: parentLockContentMaxWidth)"))
    }

    func testAddChildSheetCopyIsPolished() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("Settings copy from \\(firstChildName) by default, and you can tweak them per child."))
        XCTAssertFalse(dashboard.contains("Settings copy from \\(firstChildName) by default -- you can tweak per child."))
    }

    private func readRepoFile(_ relativePath: String) throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repoRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = repoRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
