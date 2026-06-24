import XCTest

final class HandBackCopyTests: XCTestCase {
    func testHandBackKeepsChildInstructionPrimaryAndParentEntryVisible() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Challenges/HandBackView.swift")

        XCTAssertTrue(contents.contains("Swipe up or press Home, then reopen your video or app. It's unlocked."))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("unpaused"))
        XCTAssertTrue(contents.contains("iOS does not let Screen Time apps automatically reopen that app."))
        XCTAssertTrue(contents.contains("Label(\"I'm a parent\", systemImage: \"lock.fill\")"))
        XCTAssertTrue(contents.contains("accessibilityIdentifier(\"parent_unlock_entry\")"))
        XCTAssertTrue(contents.contains("accessibilityLabel(\"I'm a parent\")"))
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

    func testHomeHandoffCardLocksParentDashboardBeforeSharedDeviceUse() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(contents.contains("Ready to hand this device over?"))
        XCTAssertTrue(contents.contains("Lock parent controls first. Brain breaks still open for your child"))
        XCTAssertTrue(contents.contains("When a monitored app pauses, the Childlock alert or Home opens the brain break."))
        XCTAssertTrue(contents.contains("handoffLockCard"))
        XCTAssertTrue(contents.contains("appState.lockSettings(pinService: pinService)"))
        XCTAssertTrue(contents.contains("accessibilityIdentifier(\"handoff_lock_parent_dashboard\")"))
        XCTAssertTrue(contents.contains("accessibilityLabel(\"Lock Parent Dashboard before handoff\")"))
    }

    func testChildrenTabMakesLaunchChildLimitAndActiveChildExplicit() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let appState = try readRepoFile("Sources/Childlock/ViewModels/AppState.swift")
        let paywall = try readRepoFile("Sources/Childlock/Views/Paywall/PaywallView.swift")

        XCTAssertTrue(appState.contains("public static let maxChildProfiles = 5"))
        XCTAssertTrue(appState.contains("guard profiles.count < Self.maxChildProfiles else { return nil }"))
        XCTAssertTrue(paywall.contains("comparisonRow(feature: \"Children\", free: \"5 children\", premium: \"5 children\")"))
        XCTAssertTrue(dashboard.contains("canAddChildProfile"))
        XCTAssertTrue(dashboard.contains("Childlock supports up to \\(AppState.maxChildProfiles) child profiles."))
        XCTAssertTrue(dashboard.contains("Choose the active child before handing over a shared device."))
        XCTAssertTrue(dashboard.contains("Text(\"Make active\")"))
        XCTAssertTrue(dashboard.contains("private func makeProfileActive(_ profile: ChildProfile)"))
        XCTAssertTrue(dashboard.contains("appState.setActiveProfile(id: profile.id)"))
        XCTAssertTrue(dashboard.contains("refreshMonitoringIfRunning(for: profile)"))
        XCTAssertTrue(dashboard.contains("accessibilityLabel(\"Make \\(profile.name) active on this device\")"))
    }

    func testInteractiveControlsDoNotExposeInternalIDsAsSpokenLabels() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let challenge = try readRepoFile("Sources/Childlock/Views/Challenges/ChallengeContainerView.swift")
        let math = try readRepoFile("Sources/Childlock/Views/Challenges/MathChallengeView.swift")
        let memory = try readRepoFile("Sources/Childlock/Views/Challenges/MemoryMatchView.swift")
        let handBack = try readRepoFile("Sources/Childlock/Views/Challenges/HandBackView.swift")

        XCTAssertTrue(onboarding.contains("accessibilityIdentifier(\"monitor_\\(app)\")"))
        XCTAssertTrue(onboarding.contains("\"Add \\(app) to monitored apps\""))
        XCTAssertTrue(onboarding.contains("\"Remove \\(app) from monitored apps\""))
        XCTAssertTrue(onboarding.contains(".accessibilityElement(children: .ignore)"))

        XCTAssertTrue(dashboard.contains("accessibilityIdentifier(\"practice_brain_break\")"))
        XCTAssertTrue(dashboard.contains("accessibilityLabel(\"Practice Brain Break\")"))
        XCTAssertTrue(dashboard.contains("accessibilityIdentifier(\"handoff_lock_parent_dashboard\")"))
        XCTAssertTrue(dashboard.contains("accessibilityLabel(\"Lock Parent Dashboard before handoff\")"))
        XCTAssertTrue(dashboard.contains("accessibilityLabel(\"Settings\")"))
        XCTAssertTrue(dashboard.contains("accessibilityIdentifier(\"assign_monitored_\\(appName)\")"))
        XCTAssertTrue(dashboard.contains("\"Add \\(appName) to monitored apps\""))
        XCTAssertTrue(dashboard.contains("\"Remove \\(appName) from monitored apps\""))
        XCTAssertTrue(dashboard.contains("accessibilityValue(binding.wrappedValue ? \"On\" : \"Off\")"))

        for contents in [challenge, math] {
            XCTAssertTrue(contents.contains("accessibilityIdentifier(\"answer_\\(answer)\")"))
            XCTAssertTrue(contents.contains("accessibilityLabel(\"Answer \\(answer)\")"))
            XCTAssertFalse(contents.contains("accessibilityLabel(\"answer_"))
        }

        XCTAssertTrue(memory.contains("accessibilityIdentifier(\"memory_card_\\(index)\")"))
        XCTAssertTrue(memory.contains("Memory card \\(position), hidden"))
        XCTAssertFalse(memory.contains("accessibilityLabel(\"memory_card_"))

        XCTAssertTrue(handBack.contains("accessibilityIdentifier(\"parent_unlock_entry\")"))
        XCTAssertTrue(handBack.contains("accessibilityLabel(\"I'm a parent\")"))
        XCTAssertFalse(handBack.contains("accessibilityLabel(\"parent_unlock_entry\")"))
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

    func testMonitoringStatusUsesParentFriendlyLabels() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("value: monitoringStatusLabel"))
        XCTAssertTrue(dashboard.contains("private var monitoringStatus: ChildlockMonitoringStatus?"))
        XCTAssertTrue(dashboard.contains("return \"Needs attention\""))
        XCTAssertTrue(dashboard.contains("return \"Permission needed\""))
        XCTAssertTrue(dashboard.contains("return \"Brain break pending\""))
        XCTAssertFalse(dashboard.contains("monitoringStatusText.capitalized"))
    }

    func testEnforcementSettingsShowOnlyRelevantStartOrStopAction() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("if shouldShowStartLockEnforcementAction"))
        XCTAssertTrue(dashboard.contains("if shouldShowStopLockEnforcementAction"))
        XCTAssertTrue(dashboard.contains("Start Screen Time Enforcement"))
        XCTAssertTrue(dashboard.contains("Stop Screen Time Enforcement"))
        XCTAssertFalse(dashboard.contains("Start Lock Enforcement"))
        XCTAssertFalse(dashboard.contains("Stop Lock Enforcement"))
        XCTAssertTrue(dashboard.contains("private var shouldShowStartLockEnforcementAction: Bool"))
        XCTAssertTrue(dashboard.contains("private var shouldShowStopLockEnforcementAction: Bool"))
        XCTAssertTrue(dashboard.contains("case .running, .intervalStarted, .thresholdReached, .challengeRequested, .moreTimeRequested:\n            return false"))
        XCTAssertTrue(dashboard.contains("case .notStarted, .intervalEnded, .stopped, .denied, .failed, .none:\n            return true"))
        XCTAssertTrue(dashboard.contains("case .running, .intervalStarted, .thresholdReached, .challengeRequested, .moreTimeRequested:\n            return true"))
        XCTAssertTrue(dashboard.contains("case .notStarted, .intervalEnded, .stopped, .denied, .failed, .none:\n            return false"))
    }

    func testEnforcementSettingsExplainTestFlightHandoffSequence() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("screenTimeEnforcementGuidance"))
        XCTAssertTrue(dashboard.contains("screenTimeEnforcementGuidanceText"))
        XCTAssertTrue(dashboard.contains("Same-phone test: lock the parent dashboard, hand this device over"))
        XCTAssertTrue(dashboard.contains("For child iPad, run these steps on the iPad."))
        XCTAssertTrue(dashboard.contains("For TestFlight: choose the shortest interval, start enforcement, lock the parent dashboard"))
        XCTAssertTrue(dashboard.contains("Planning labels do not lock content."))
        XCTAssertTrue(dashboard.contains("After selection, start enforcement, lock the parent dashboard, then hand this device over."))
        XCTAssertTrue(dashboard.contains("On a child iPad, do this on the iPad."))
        XCTAssertTrue(dashboard.contains("complete the challenge, then confirm monitoring re-arms"))
    }

    func testParentChildDeviceModelIsClearInAppCopy() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(onboarding.contains("Shared iPhone? Set it up here."))
        XCTAssertTrue(onboarding.contains("Child iPad? Install and run setup on the iPad too"))
        XCTAssertTrue(onboarding.contains("a parent-only iPhone install will not lock the iPad at launch"))
        XCTAssertTrue(onboarding.contains("A separate parent-phone remote dashboard is not included at launch."))

        XCTAssertTrue(dashboard.contains("Locks apps on this device only."))
        XCTAssertTrue(dashboard.contains("For a child iPad, install and configure Childlock on the iPad."))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("remotely lock"))
    }

    func testOnboardingScreenTimePickerCopyExplainsDoneStep() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let viewModel = try readRepoFile("Sources/Childlock/ViewModels/OnboardingViewModel.swift")

        XCTAssertTrue(onboarding.contains("TextField(\"Type your child's name\""))
        XCTAssertTrue(viewModel.contains("Type your child's name to continue."))
        XCTAssertFalse(onboarding.contains("TextField(\"Mia\""))
        XCTAssertTrue(onboarding.contains("Choose apps, categories, or websites"))
        XCTAssertTrue(onboarding.contains("Select at least one item in Apple's Screen Time picker, then tap Done."))
        XCTAssertTrue(onboarding.contains("No Screen Time items selected yet. If Continue stays disabled"))
        XCTAssertTrue(onboarding.contains("innerStepWithPinnedFooter"))
        XCTAssertTrue(onboarding.contains("setupFooter"))
        XCTAssertTrue(onboarding.contains(".accessibilityHint(viewModel.setupBlockingReason ?? \"Continue to parent PIN setup.\")"))
        XCTAssertFalse(onboarding.contains("Choose video apps"))
        XCTAssertFalse(onboarding.contains("Choose games"))
        XCTAssertFalse(onboarding.contains("Choose social apps"))
        XCTAssertTrue(viewModel.contains("Choose at least one app, category, or website in the Screen Time picker, then tap Done."))
    }

    func testParentDashboardUsesReadableContentWidthOnIPad() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("dashboardContentMaxWidth"))
        XCTAssertTrue(dashboard.contains("parentLockContentMaxWidth"))
        XCTAssertTrue(dashboard.contains(".frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)"))
        XCTAssertTrue(dashboard.contains(".frame(maxWidth: parentLockContentMaxWidth)"))
    }

    func testOnboardingUsesReadableContentWidthOnIPad() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")

        XCTAssertTrue(onboarding.contains("onboardingContentMaxWidth"))
        XCTAssertTrue(onboarding.contains(".frame(maxWidth: onboardingContentMaxWidth, alignment: .leading)"))
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
