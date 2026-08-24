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

    func testScreenTimeMonitoringUsesOneActiveChildMonitorPerDevice() throws {
        let screenTime = try readRepoFile("Sources/Childlock/Services/ScreenTimeManager.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")
        let deviceModel = try readRepoFile("docs/DEVICE_MODEL.md")

        XCTAssertTrue(screenTime.contains("requestAuthorization(for: .individual)"))
        XCTAssertFalse(screenTime.contains("requestAuthorization(for: .child)"))
        XCTAssertTrue(screenTime.contains("private let activeActivityName = DeviceActivityName(\"childlock.active\")"))
        XCTAssertTrue(screenTime.contains("one active child per configured device"))
        XCTAssertTrue(screenTime.contains("center.stopMonitoring([activeActivityName])"))
        XCTAssertTrue(screenTime.contains("try center.startMonitoring(\n                activeActivityName,"))
        XCTAssertFalse(screenTime.contains("DeviceActivityName(\"childlock.\\(profileID.uuidString)\")"))

        XCTAssertTrue(dashboard.contains("refreshMonitoringIfRunning(for: profile)"))
        XCTAssertTrue(checklist.contains("Only one active child monitor runs on a configured device at a time."))
        XCTAssertTrue(deviceModel.contains("One active child monitor runs per configured device at a time."))
    }

    func testShieldPresentsQuestionAndTouchFreeSuccessState() throws {
        let files = try [
            "Extensions/ShieldConfigurationExtension/ChildlockShieldConfiguration.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)
        let project = try readRepoFile("Childlock.xcodeproj/project.pbxproj")

        for contents in files {
            XCTAssertTrue(contents.contains("Brain Break"))
            XCTAssertTrue(contents.contains("SharedDefaults.shieldBrainBreak()"))
            XCTAssertTrue(contents.contains("brainBreak.prompt"))
            XCTAssertTrue(contents.contains("brainBreak.primaryAnswer"))
            XCTAssertTrue(contents.contains("brainBreak.secondaryAnswer"))
            XCTAssertTrue(contents.contains("UIDevice.current.userInterfaceIdiom == .pad"))
            XCTAssertTrue(contents.contains("pointSize: isIPad ? 72 : 48"))
            XCTAssertTrue(contents.contains("let titleText = isIPad ? brainBreak.prompt : brainBreak.guidanceText"))
            XCTAssertTrue(contents.contains("let subtitleText = isIPad ? brainBreak.guidanceText : brainBreak.prompt"))
            XCTAssertTrue(contents.contains("Great job!"))
            XCTAssertTrue(contents.contains("Going back to your app…"))
            XCTAssertFalse(contents.contains("text: \"Parent\""))
            XCTAssertFalse(contents.contains("Ask Parent"))
            XCTAssertFalse(contents.contains("text: \"Open Childlock\""))
        }
        XCTAssertTrue(project.contains("SHARED_DEFAULTS_SHIELD_CONFIG_SOURCE"))

        let flowFiles = try [
            "Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift",
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        XCTAssertTrue(flowFiles[0].contains("ShieldBrainBreakState.make("))
        XCTAssertTrue(flowFiles[0].contains("SharedDefaults.saveShieldBrainBreak"))
        XCTAssertFalse(flowFiles[0].contains("Open Childlock to solve."))

        for contents in [flowFiles[1], flowFiles[2]] {
            XCTAssertTrue(contents.contains("submitAnswer(at: 0"))
            XCTAssertTrue(contents.contains("submitAnswer(at: 1"))
            XCTAssertTrue(contents.contains("finishSuccessfulBrainBreak(id: brainBreakID)"))
            XCTAssertTrue(contents.contains("store.shield.applications = nil"))
            XCTAssertTrue(contents.contains("store.shield.webDomains = nil"))
            XCTAssertTrue(contents.contains("rearmMonitoring()"))
            XCTAssertTrue(contents.contains("ProcessInfo.processInfo.performExpiringActivity("))
            XCTAssertTrue(contents.contains("return expired ? .none : .defer"))
            XCTAssertFalse(contents.contains("DispatchQueue.main.asyncAfter"))
            XCTAssertFalse(contents.contains("Brain break ready"))
            XCTAssertFalse(contents.contains("Tap to solve."))
        }
    }

    func testShieldRequiresTwoFreshQuestionsInsteadOfRevealingTheOtherAnswer() throws {
        let sharedDefaults = try readRepoFile("Sources/Childlock/Services/SharedDefaults.swift")
        let actionFiles = try [
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        XCTAssertTrue(sharedDefaults.contains("public static let requiredCorrectAnswers = 2"))
        XCTAssertTrue(sharedDefaults.contains("correctAnswers = 0"))
        XCTAssertTrue(sharedDefaults.contains("replaceQuestion(using: &generator)"))
        XCTAssertTrue(sharedDefaults.contains("excluding: questionKind"))
        XCTAssertTrue(sharedDefaults.contains("case nextQuestion"))

        for contents in actionFiles {
            XCTAssertTrue(contents.contains("let outcome = brainBreak.submit(answerIndex: answerIndex)"))
            XCTAssertTrue(contents.contains("guard outcome == .success else"))
            XCTAssertTrue(contents.contains("completionHandler(.defer)"))
        }
    }

    func testNotificationSettingsExplainShieldChallengesDoNotNeedAlerts() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(dashboard.contains("iOS notification permission"))
        XCTAssertFalse(dashboard.contains("settingsToggleRow(title: \"Challenge alerts\""))
        XCTAssertTrue(dashboard.contains("Shield brain breaks still work"))
        XCTAssertTrue(dashboard.contains("Shield brain breaks work without alerts."))
        XCTAssertTrue(dashboard.contains("debugNotificationAuthorizationStatus"))
        XCTAssertTrue(dashboard.contains("--childlock-qa-seed-settings-notifications-denied"))
        XCTAssertTrue(dashboard.contains("return .denied"))
        XCTAssertTrue(dashboard.contains("scrollToDebugSettingsNotificationSectionIfNeeded"))
        XCTAssertTrue(dashboard.contains("scrollProxy.scrollTo(settingsNotificationsAnchorID, anchor: .center)"))
        XCTAssertTrue(checklist.contains("Settings notification-denied seed shows iOS notification permission as `Off`"))
        XCTAssertTrue(checklist.contains("offers `Open Notification Settings`"))
        XCTAssertTrue(dashboard.contains("UIApplication.openNotificationSettingsURLString"))
        XCTAssertTrue(normalizeWhitespace(checklist).contains("shield brain break still works without notification permission"))
    }

    func testLegacyChallengeAlertPreferenceDoesNotGateShieldBrainBreaks() throws {
        let sharedDefaults = try readRepoFile("Sources/Childlock/Services/SharedDefaults.swift")
        let appState = try readRepoFile("Sources/Childlock/ViewModels/AppState.swift")
        let monitor = try readRepoFile("Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")

        XCTAssertTrue(sharedDefaults.contains("challengeAlertsEnabled"))
        XCTAssertTrue(appState.contains("mirrorNotificationSettingsToSharedDefaults"))
        XCTAssertTrue(appState.contains("settings.challengeAlertNotification"))
        XCTAssertFalse(monitor.contains("SharedDefaults.Key.challengeAlertsEnabled"))
        XCTAssertFalse(extensionEntrypoints.contains("SharedDefaults.Key.challengeAlertsEnabled"))
    }

    func testShieldBrainBreakDoesNotRequireNotificationDelivery() throws {
        let notificationService = try readRepoFile("Sources/Childlock/Services/NotificationService.swift")
        let monitor = try readRepoFile("Extensions/DeviceActivityMonitorExtension/ChildlockMonitor.swift")
        let shieldAction = try readRepoFile("Extensions/ShieldActionExtension/ChildlockShieldAction.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")

        XCTAssertTrue(notificationService.contains("requestAuthorization(options: [.alert, .badge, .sound])"))
        XCTAssertFalse(notificationService.contains("UNAuthorizationOptions = [.alert, .badge, .sound, .timeSensitive]"))
        XCTAssertFalse(notificationService.contains("requestAuthorization(options: [.alert, .badge, .sound, .timeSensitive])"))

        for contents in [monitor, shieldAction, extensionEntrypoints] {
            XCTAssertFalse(contents.contains("content.interruptionLevel = .timeSensitive"))
            XCTAssertFalse(contents.contains("UNMutableNotificationContent()"))
        }
    }

    func testMonitorSavesShieldQuestionBeforeSelectionIsShielded() throws {
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
            let questionRange = try XCTUnwrap(
                contents.range(of: "SharedDefaults.saveShieldBrainBreak(brainBreak, defaults: defaults)")
            )
            let statusRange = try XCTUnwrap(
                contents.range(of: "defaults.set(\"threshold_reached\", forKey: SharedDefaults.Key.monitoringStatus)")
            )

            XCTAssertLessThan(decodeRange.lowerBound, questionRange.lowerBound)
            XCTAssertLessThan(questionRange.lowerBound, shieldRange.lowerBound)
            XCTAssertLessThan(shieldRange.lowerBound, statusRange.lowerBound)
            XCTAssertTrue(contents.contains("defaults.set(false, forKey: SharedDefaults.Key.challengePending)"))
            XCTAssertTrue(contents.contains("defaults.set(\"failed\", forKey: SharedDefaults.Key.monitoringStatus)"))
        }
    }

    func testShieldButtonsOnlySubmitAnswersAndNeverOpenChildlock() throws {
        let shieldAction = try readRepoFile("Extensions/ShieldActionExtension/ChildlockShieldAction.swift")
        let extensionEntrypoints = try readRepoFile("Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift")

        for contents in [shieldAction, extensionEntrypoints] {
            XCTAssertTrue(contents.contains("submitAnswer(at: 0"))
            XCTAssertTrue(contents.contains("submitAnswer(at: 1"))
            XCTAssertTrue(contents.contains("defaults.set(false, forKey: SharedDefaults.Key.challengePending)"))
            XCTAssertFalse(contents.contains("more_time_requested"))
            XCTAssertFalse(contents.contains("postBrainBreakNotification"))
            XCTAssertFalse(contents.contains("UIApplication.shared"))
        }
    }

    func testGrantMoreTimeOnlyClearsRequestAfterMonitoringRestarts() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let grantStart = try XCTUnwrap(dashboard.range(of: "private func grantMoreTime()"))
        let clearStart = try XCTUnwrap(dashboard.range(of: "private func clearMoreTimeRequests()"))
        let grantBlock = String(dashboard[grantStart.lowerBound..<clearStart.lowerBound])

        XCTAssertTrue(grantBlock.contains("guard let profile = monitoringProfile"))
        XCTAssertFalse(grantBlock.contains("guard let profile = appState.activeProfile"))
        XCTAssertTrue(grantBlock.contains("No monitored child profile available."))
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

    func testStartEnforcementStillUsesActiveProfileForHandoffSetup() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let startStart = try XCTUnwrap(dashboard.range(of: "private func startScreenTimeEnforcement()"))
        let stopStart = try XCTUnwrap(dashboard.range(of: "private func stopScreenTimeEnforcement()"))
        let startBlock = String(dashboard[startStart.lowerBound..<stopStart.lowerBound])

        XCTAssertTrue(startBlock.contains("guard let profile = appState.activeProfile"))
        XCTAssertFalse(startBlock.contains("guard let profile = monitoringProfile"))
        XCTAssertTrue(startBlock.contains("No active child profile available."))
        XCTAssertTrue(startBlock.contains("try ScreenTimeManager.shared.startMonitoring(profile: profile)"))
    }

    func testStopEnforcementUsesMonitoredProfileOnSharedDevice() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let stopStart = try XCTUnwrap(dashboard.range(of: "private func stopScreenTimeEnforcement()"))
        let end = try XCTUnwrap(dashboard.range(of: "\n    }\n}", range: stopStart.upperBound..<dashboard.endIndex))
        let stopBlock = String(dashboard[stopStart.lowerBound..<end.upperBound])

        XCTAssertTrue(stopBlock.contains("guard let profile = monitoringProfile"))
        XCTAssertFalse(stopBlock.contains("guard let profile = appState.activeProfile"))
        XCTAssertTrue(stopBlock.contains("No monitored child profile available."))
        XCTAssertTrue(stopBlock.contains("ScreenTimeManager.shared.stopMonitoring(profile: profile)"))
        XCTAssertTrue(dashboard.contains("screenTimeEnforcementBinding"))
        XCTAssertTrue(dashboard.contains("stopScreenTimeEnforcement()"))
    }

    func testCorrectShieldAnswerShowsSuccessThenClearsShield() throws {
        let files = try [
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        for contents in files {
            XCTAssertTrue(contents.contains("brainBreak.submit(answerIndex: answerIndex)"))
            XCTAssertTrue(contents.contains("guard outcome == .success else"))
            XCTAssertTrue(contents.contains("ShieldBrainBreakCompletion(state: brainBreak)"))
            XCTAssertTrue(contents.contains("completionHandler(.defer)"))
            XCTAssertTrue(contents.contains("successDisplayDuration"))
            XCTAssertTrue(contents.contains("ProcessInfo.processInfo.performExpiringActivity("))
            XCTAssertTrue(contents.contains("Thread.sleep(forTimeInterval: successDisplayDuration)"))
            XCTAssertTrue(contents.contains("return expired ? .none : .defer"))
            XCTAssertTrue(contents.contains("finishSuccessfulBrainBreak(id: brainBreakID)"))
            XCTAssertTrue(contents.contains("store.shield.applications = nil"))
            XCTAssertTrue(contents.contains("rearmMonitoring()"))
            XCTAssertTrue(contents.contains("let identifiers = [SharedDefaults.NotificationIdentifier.brainBreak]"))
            XCTAssertTrue(contents.contains("removePendingNotificationRequests(withIdentifiers: identifiers)"))
            XCTAssertTrue(contents.contains("removeDeliveredNotifications(withIdentifiers: identifiers)"))
            XCTAssertFalse(contents.contains("DispatchQueue.main.asyncAfter"))
            XCTAssertFalse(contents.contains("UNNotificationRequest("))
        }
    }

    func testRapidTestingRestartsWhileTimingAndSurvivesEveryRearm() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let sharedDefaults = try readRepoFile("Sources/Childlock/Services/SharedDefaults.swift")
        let screenTime = try readRepoFile("Sources/Childlock/Services/ScreenTimeManager.swift")
        let shieldActions = try [
            "Extensions/ShieldActionExtension/ChildlockShieldAction.swift",
            "Sources/Childlock/Extensions/ScreenTimeExtensionEntrypoints.swift",
        ].map(readRepoFile)

        XCTAssertTrue(dashboard.contains("ChildlockRapidTesting.shouldRestartMonitoring(storedStatus: monitoringStatusText)"))
        XCTAssertTrue(sharedDefaults.contains("storedStatus == \"running\" || storedStatus == \"interval_started\""))
        XCTAssertTrue(screenTime.contains("SharedDefaults.Key.activeMonitoringIntervalSeconds"))

        for contents in shieldActions {
            XCTAssertTrue(contents.contains("SharedDefaults.Key.activeMonitoringIntervalSeconds"))
            XCTAssertTrue(contents.contains("threshold: ChildlockRapidTesting.threshold("))
            XCTAssertTrue(contents.contains("rapidTestIntervalSeconds: rapidTestIntervalSeconds"))
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

    func testLegacyBrainBreakNotificationsAreClearedFromShieldFlow() throws {
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

        for contents in [monitor, shieldAction, extensionEntrypoints] {
            XCTAssertTrue(contents.contains("SharedDefaults.NotificationIdentifier.brainBreak"))
            XCTAssertTrue(contents.contains("removePendingNotificationRequests(withIdentifiers: identifiers)"))
            XCTAssertTrue(contents.contains("removeDeliveredNotifications(withIdentifiers: identifiers)"))
            XCTAssertFalse(contents.contains("brain_break_\\(UUID().uuidString)"))
            XCTAssertFalse(contents.contains("UNNotificationRequest("))
        }

        XCTAssertTrue(notificationService.contains("clearBrainBreakAlerts()"))
        XCTAssertTrue(notificationService.contains("clearMoreTimeRequestAlerts()"))
        XCTAssertTrue(notificationService.contains("clearShieldFlowAlerts()"))
        XCTAssertTrue(challengeViewModel.contains("NotificationService.clearBrainBreakAlerts()"))
        XCTAssertTrue(screenTimeManager.contains("NotificationService.clearShieldFlowAlerts()"))
        XCTAssertTrue(dashboard.contains("NotificationService.clearMoreTimeRequestAlerts()"))
    }

    func testSimulatorSeedsCoverChallengeAndCelebrationScreens() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let challengeViewModel = try readRepoFile("Sources/Childlock/ViewModels/ChallengeViewModel.swift")
        let memoryMatchView = try readRepoFile("Sources/Childlock/Views/Challenges/MemoryMatchView.swift")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(rootView.contains("--childlock-qa-seed-pending-math-challenge"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-pending-memory-challenge"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-celebration"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-locked-more-time-request"))
        XCTAssertTrue(rootView.contains("locked: arguments.contains(DebugLaunchArgument.lockedDashboard)\n                    || arguments.contains(DebugLaunchArgument.lockedMoreTimeRequest)"))
        XCTAssertTrue(rootView.contains("moreTimeRequest: arguments.contains(DebugLaunchArgument.moreTimeRequest)\n                    || arguments.contains(DebugLaunchArgument.lockedMoreTimeRequest)"))
        XCTAssertTrue(rootView.contains("arguments.contains(DebugLaunchArgument.settingsTab)\n                    || arguments.contains(DebugLaunchArgument.settingsNotificationsDenied) ? \"not_started\" : \"running\""))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-settings-notifications-denied"))
        XCTAssertTrue(rootView.contains("return .math"))
        XCTAssertTrue(rootView.contains("return .memory"))
        XCTAssertTrue(rootView.contains("challengeViewModel.debugPresentCelebration(for: profile)"))

        XCTAssertTrue(challengeViewModel.contains("#if DEBUG"))
        XCTAssertTrue(challengeViewModel.contains("public func debugPresentCelebration(for profile: ChildProfile)"))
        XCTAssertTrue(challengeViewModel.contains("state = .completed"))

        XCTAssertTrue(memoryMatchView.contains("#if DEBUG"))
        XCTAssertTrue(memoryMatchView.contains("ProcessInfo.processInfo.arguments.contains(\"--childlock-qa-seed-pending-memory-challenge\")"))
        XCTAssertTrue(memoryMatchView.contains(".shuffled()"))

        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-pending-memory-challenge`"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-celebration`"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-locked-more-time-request`"))
        XCTAssertTrue(checklist.contains("memory pairs are deterministic in this Debug seed"))
        XCTAssertTrue(checklist.contains("Celebration seed shows the animated `Great job!` state with no child action."))
        XCTAssertTrue(checklist.contains("Locked more-time seed keeps the dashboard hidden"))
    }

    func testHardwareChecklistCoversMultiChildShieldProfileRouting() throws {
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        XCTAssertTrue(normalizeWhitespace(checklist).contains("If multiple child profiles exist, the shield question uses the monitored child's age/difficulty."))
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
        XCTAssertTrue(screenTimeManager.contains("SharedDefaults.clearShieldBrainBreak(defaults: defaults)"))

        XCTAssertTrue(checklist.contains("Restarting enforcement clears stale shield-challenge state."))
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
