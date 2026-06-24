import XCTest

final class ShieldCopyTests: XCTestCase {
    func testRootPresentsPendingChallengeAfterAuthStateResolves() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let normalizedRootView = rootView
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\t", with: "")

        let expectedAuthStateHandler = """
        .onChange(of: authService.state) { _, _ in
            syncAuthState()
            presentPendingChallengeIfNeeded()
        }
        """
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\t", with: "")

        XCTAssertTrue(normalizedRootView.contains(expectedAuthStateHandler))
    }

    func testPendingChallengeUsesMonitoredProfileBeforeDashboardProfile() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let normalizedRootView = normalizeWhitespace(rootView)

        XCTAssertTrue(normalizedRootView.contains(
            "SharedDefaults.Key.activeMonitoringProfileID) ?? SharedDefaults.shared.string(forKey: SharedDefaults.Key.activeProfileID)"
        ))
        XCTAssertTrue(normalizedRootView.contains("triggerChallenge(for: profile)"))
    }

    func testShieldAndNotificationCopyMatchesPlatformBehavior() throws {
        let files = try [
            "Extensions/ShieldConfigurationExtension/ChildlockShieldConfiguration.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        for contents in files {
            XCTAssertTrue(contents.contains("Brain Break"))
            XCTAssertTrue(contents.contains("Tap Start, then open Childlock from Home."))
            XCTAssertTrue(contents.contains("Start Brain Break"))
            XCTAssertFalse(contents.contains("text: \"Open Childlock\""))
            XCTAssertFalse(contents.contains("This app is paused. Open Childlock to unlock it."))
        }

        let notificationFiles = try [
            "Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift",
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        for contents in notificationFiles {
            XCTAssertFalse(contents.contains("Your child asked for more screen time. Open Childlock to respond."))
        }

        XCTAssertTrue(notificationFiles[0].contains("Open Childlock from Home to unlock it."))
        XCTAssertTrue(notificationFiles[2].contains("Open Childlock from Home to unlock it."))
        XCTAssertTrue(notificationFiles[1].contains("Hand this device to your parent so they can respond in Childlock."))
        XCTAssertTrue(notificationFiles[2].contains("Hand this device to your parent so they can respond in Childlock."))
    }

    func testNotificationSettingsExplainHomeFallbackWhenAlertsAreDenied() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let reviewNotes = try readRepoFile("docs/APP_REVIEW_NOTES.md")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(dashboard.contains("iOS notification permission"))
        XCTAssertTrue(dashboard.contains("The child can still tap Start Brain Break, press Home, and open Childlock to continue."))
        XCTAssertTrue(dashboard.contains("UIApplication.openNotificationSettingsURLString"))
        XCTAssertTrue(reviewNotes.contains("pressing\n  Home and opening Childlock presents the same pending challenge"))
        XCTAssertTrue(checklist.contains("denied-notification"))
    }

    func testChallengeAlertPreferenceIsVisibleToScreenTimeExtension() throws {
        let sharedDefaults = try readRepoFile("Sources/Childlock/Services/SharedDefaults.swift")
        let appState = try readRepoFile("Sources/Childlock/ViewModels/AppState.swift")
        let monitor = try readRepoFile("Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")

        XCTAssertTrue(sharedDefaults.contains("challengeAlertsEnabled"))
        XCTAssertTrue(appState.contains("mirrorNotificationSettingsToSharedDefaults"))
        XCTAssertTrue(appState.contains("settings.challengeAlertNotification"))
        XCTAssertTrue(monitor.contains("SharedDefaults.Key.challengeAlertsEnabled"))
        XCTAssertTrue(extensionEntrypoints.contains("SharedDefaults.Key.challengeAlertsEnabled"))
        XCTAssertTrue(monitor.contains("?? true"))
        XCTAssertTrue(extensionEntrypoints.contains("?? true"))
    }

    func testMonitorOnlyMarksChallengePendingAfterSelectionIsShielded() throws {
        let files = try [
            "Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        for contents in files {
            let decodeRange = try XCTUnwrap(
                contents.range(of: "JSONDecoder().decode(FamilyActivitySelection.self, from: data)")
            )
            let shieldRange = try XCTUnwrap(
                contents.range(of: "store.shield.applications = selection.applicationTokens")
            )
            let pendingRange = try XCTUnwrap(
                contents.range(of: "defaults.set(true, forKey: SharedDefaults.Key.challengePending)")
            )
            let statusRange = try XCTUnwrap(
                contents.range(of: "defaults.set(\"threshold_reached\", forKey: SharedDefaults.Key.monitoringStatus)")
            )

            XCTAssertLessThan(decodeRange.lowerBound, pendingRange.lowerBound)
            XCTAssertLessThan(shieldRange.lowerBound, pendingRange.lowerBound)
            XCTAssertLessThan(pendingRange.lowerBound, statusRange.lowerBound)
            XCTAssertTrue(contents.contains("defaults.set(false, forKey: SharedDefaults.Key.challengePending)"))
            XCTAssertTrue(contents.contains("defaults.set(\"failed\", forKey: SharedDefaults.Key.monitoringStatus)"))
        }
    }

    func testAskParentDoesNotOpenPendingChildChallenge() throws {
        let shieldAction = try readRepoFile("Extensions/ShieldActionExtension/ChildlockShieldAction.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        for contents in [shieldAction, extensionEntrypoints] {
            XCTAssertTrue(contents.contains("defaults.set(false, forKey: SharedDefaults.Key.challengePending)"))
            XCTAssertTrue(contents.contains("defaults.set(\"more_time_requested\", forKey: SharedDefaults.Key.monitoringStatus)"))
        }

        XCTAssertTrue(rootView.contains("guard !hasActiveMoreTimeRequest else { return }"))
        XCTAssertTrue(rootView.contains("SharedDefaults.shared.integer(forKey: SharedDefaults.Key.moreTimeRequestCount) > 0"))
        XCTAssertTrue(dashboard.contains("asked for more time. Enter your PIN to respond."))
        XCTAssertTrue(dashboard.contains("SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)"))
        XCTAssertTrue(dashboard.contains("Button(\"Keep blocked\")"))
        XCTAssertFalse(dashboard.contains("Button(\"Dismiss\")"))
        XCTAssertTrue(dashboard.contains("private func denyMoreTimeRequest()"))
        XCTAssertTrue(dashboard.contains("SharedDefaults.shared.set(\"threshold_reached\", forKey: SharedDefaults.Key.monitoringStatus)"))
        XCTAssertTrue(dashboard.contains("monitoringStatusText = \"threshold_reached\""))

        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")
        XCTAssertTrue(checklist.contains("does not open\n    a pending child challenge before the parent responds"))
        XCTAssertTrue(checklist.contains("`Keep blocked` clears the parent request while keeping the child blocked"))
    }

    func testGrantMoreTimeOnlyClearsRequestAfterMonitoringRestarts() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let grantStart = try XCTUnwrap(dashboard.range(of: "private func grantMoreTime()"))
        let clearStart = try XCTUnwrap(dashboard.range(of: "private func clearMoreTimeRequests()"))
        let grantBlock = String(dashboard[grantStart.lowerBound..<clearStart.lowerBound])

        XCTAssertTrue(grantBlock.contains("try ScreenTimeManager.shared.startMonitoring(profile: profile)"))
        XCTAssertFalse(grantBlock.contains("try? ScreenTimeManager.shared.startMonitoring"))
        XCTAssertTrue(grantBlock.contains("monitoringErrorText = error.localizedDescription"))
        XCTAssertTrue(grantBlock.contains("Monitoring is not ready to grant more time."))

        let restartRange = try XCTUnwrap(grantBlock.range(of: "try ScreenTimeManager.shared.startMonitoring(profile: profile)"))
        let unshieldRange = try XCTUnwrap(grantBlock.range(of: "ScreenTimeManager.shared.removeShields()"))
        let clearRange = try XCTUnwrap(grantBlock.range(of: "clearMoreTimeRequests()"))

        XCTAssertLessThan(restartRange.lowerBound, unshieldRange.lowerBound)
        XCTAssertLessThan(unshieldRange.lowerBound, clearRange.lowerBound)
    }

    func testStartBrainBreakClearsStaleBrainBreakNotification() throws {
        let files = try [
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        for contents in files {
            let primaryRange = try XCTUnwrap(contents.range(of: "case .primaryButtonPressed:"))
            let secondaryRange = try XCTUnwrap(contents.range(of: "case .secondaryButtonPressed:"))
            let primaryBlock = contents[primaryRange.lowerBound..<secondaryRange.lowerBound]
            let startsChallengeAndClearsAlert = primaryBlock.contains("clearBrainBreakNotification()")
                || (primaryBlock.contains("handleStartChallenge()")
                    && contents.contains("private func handleStartChallenge()")
                    && contents.contains("clearBrainBreakNotification()"))

            XCTAssertTrue(startsChallengeAndClearsAlert)
            XCTAssertTrue(contents.contains("let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]"))
            XCTAssertTrue(contents.contains("removePendingNotificationRequests(withIdentifiers: identifiers)"))
            XCTAssertTrue(contents.contains("removeDeliveredNotifications(withIdentifiers: identifiers)"))
        }
    }

    func testDailySummaryToggleSchedulesAndCancelsRealNotifications() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let appState = try readRepoFile("Sources/Childlock/ViewModels/AppState.swift")
        let notificationService = try readRepoFile("Sources/Childlock/Services/NotificationService.swift")

        XCTAssertTrue(dashboard.contains("NotificationService.scheduleDailySummary"))
        XCTAssertTrue(dashboard.contains("NotificationService.cancelDailySummary"))
        XCTAssertTrue(appState.contains("scheduleDailySummaryIfNeeded"))
        XCTAssertTrue(appState.contains("NotificationService.scheduleDailySummary"))
        XCTAssertTrue(appState.contains("NotificationService.cancelDailySummary"))
        XCTAssertTrue(notificationService.contains("cancelDailySummary"))
    }

    func testShieldFlowNotificationsUseStableIdentifiersAndAreCleared() throws {
        let sharedDefaults = try readRepoFile("Sources/Childlock/Services/SharedDefaults.swift")
        let monitor = try readRepoFile("Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift")
        let shieldAction = try readRepoFile("Extensions/ShieldActionExtension/ChildlockShieldAction.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")
        let notificationService = try readRepoFile("Sources/Childlock/Services/NotificationService.swift")
        let challengeViewModel = try readRepoFile("Sources/Childlock/ViewModels/ChallengeViewModel.swift")
        let screenTimeManager = try readRepoFile("Sources/Childlock/Services/ScreenTimeManager.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(sharedDefaults.contains("public static let brainBreak = \"childlock_brain_break\""))
        XCTAssertTrue(sharedDefaults.contains("public static let moreTimeRequest = \"childlock_more_time_request\""))

        for contents in [monitor, extensionEntrypoints] {
            XCTAssertTrue(contents.contains("SharedDefaults.NotificationIdentifier.brainBreak"))
            XCTAssertTrue(contents.contains("removePendingNotificationRequests(withIdentifiers: identifiers)"))
            XCTAssertTrue(contents.contains("removeDeliveredNotifications(withIdentifiers: identifiers)"))
            XCTAssertFalse(contents.contains("brain_break_\\(UUID().uuidString)"))
        }

        for contents in [shieldAction, extensionEntrypoints] {
            XCTAssertTrue(contents.contains("SharedDefaults.NotificationIdentifier.moreTimeRequest"))
            XCTAssertTrue(contents.contains("removePendingNotificationRequests(withIdentifiers: identifiers)"))
            XCTAssertTrue(contents.contains("removeDeliveredNotifications(withIdentifiers: identifiers)"))
            XCTAssertFalse(contents.contains("more_time_\\(UUID().uuidString)"))
        }

        XCTAssertTrue(notificationService.contains("clearBrainBreakAlerts()"))
        XCTAssertTrue(notificationService.contains("clearMoreTimeRequestAlerts()"))
        XCTAssertTrue(notificationService.contains("clearShieldFlowAlerts()"))
        XCTAssertTrue(challengeViewModel.contains("NotificationService.clearBrainBreakAlerts()"))
        XCTAssertTrue(screenTimeManager.contains("NotificationService.clearShieldFlowAlerts()"))
        XCTAssertTrue(dashboard.contains("NotificationService.clearMoreTimeRequestAlerts()"))
    }

    func testSimulatorSeedsCoverMathAndMemoryChallenges() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let memoryMatchView = try readRepoFile("Sources/Childlock/Views/Challenges/MemoryMatchView.swift")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(rootView.contains("--childlock-qa-seed-pending-math-challenge"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-pending-memory-challenge"))
        XCTAssertTrue(rootView.contains("return .math"))
        XCTAssertTrue(rootView.contains("return .memory"))

        XCTAssertTrue(memoryMatchView.contains("#if DEBUG"))
        XCTAssertTrue(memoryMatchView.contains("ProcessInfo.processInfo.arguments.contains(\"--childlock-qa-seed-pending-memory-challenge\")"))
        XCTAssertTrue(memoryMatchView.contains(".shuffled()"))

        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-pending-memory-challenge`"))
        XCTAssertTrue(checklist.contains("memory pairs are deterministic in this Debug seed"))
    }

    func testHardwareChecklistCoversMultiChildShieldProfileRouting() throws {
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(normalizeWhitespace(checklist).contains("If multiple child profiles exist, the pending challenge uses the monitored child's age/profile."))
    }

    func testMonitoringStartAndStopClearStaleShieldState() throws {
        let screenTimeManager = try readRepoFile("Sources/Childlock/Services/ScreenTimeManager.swift")
        let normalizedManager = normalizeWhitespace(screenTimeManager)
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(normalizedManager.contains("clearTransientShieldState() defaults.set(profile.id.uuidString"))
        XCTAssertTrue(normalizedManager.contains("removeShields() clearTransientShieldState()"))

        for key in [
            "challengePending",
            "moreTimeRequestCount",
            "lastMoreTimeRequestDate",
            "dailyLimitReachedAt",
        ] {
            XCTAssertTrue(screenTimeManager.contains("SharedDefaults.Key.\(key)"))
        }

        XCTAssertTrue(checklist.contains("Restarting enforcement clears stale child challenge and Ask Parent state."))
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

    private func normalizeWhitespace(_ contents: String) -> String {
        contents
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
