import XCTest

final class HandBackCopyTests: XCTestCase {
    func testHandBackKeepsChildInstructionPrimaryAndParentEntryVisible() throws {
        let contents = try readRepoFile("Sources/Childlock/Views/Challenges/HandBackView.swift")

        XCTAssertTrue(contents.contains("Done"))
        XCTAssertFalse(contents.contains("Done!"))
        XCTAssertFalse(contents.contains("All done"))
        XCTAssertFalse(contents.contains("You can go back now."))
        XCTAssertFalse(contents.contains("HandBackStepRow("))
        XCTAssertFalse(contents.contains("Content unlocked"))
        XCTAssertFalse(contents.contains("The shield is cleared and your content can open again."))
        XCTAssertTrue(contents.contains("HandBackReturnCue(iconName: \"arrow.backward\")"))
        XCTAssertFalse(contents.contains("Text(title)"))
        XCTAssertFalse(contents.contains("title: \"Back\""))
        XCTAssertFalse(contents.contains("Back to app"))
        XCTAssertFalse(contents.contains("Go back"))
        XCTAssertFalse(contents.contains("Resume activity"))
        XCTAssertFalse(contents.contains("Open your app."))
        XCTAssertFalse(contents.contains("Swipe up"))
        XCTAssertFalse(contents.contains("Swipe up to resume"))
        XCTAssertFalse(contents.contains("Your video, game, app, or site is unblocked. Use Home or the app switcher to return."))
        XCTAssertFalse(contents.contains("Childlock cannot switch apps automatically on iOS."))
        XCTAssertFalse(contents.contains("Tap here when you are ready for the last step."))
        XCTAssertFalse(contents.contains("UIApplication.shared"))
        XCTAssertFalse(contents.contains("didShowResumeStep"))
        XCTAssertTrue(contents.contains("accessibilityIdentifier(\"handback_resume_guidance\")"))
        XCTAssertTrue(contents.contains("accessibilityLabel(\"Back.\")"))
        XCTAssertTrue(contents.contains("accessibilityHint(\"Use Home or the app switcher.\")"))
        XCTAssertFalse(contents.contains("accessibilityIdentifier(\"handback_steps\")"))
        XCTAssertTrue(contents.contains(".font(.system(size: 48, weight: .bold))"))
        XCTAssertTrue(contents.contains(".frame(width: 96, height: 96)"))
        XCTAssertFalse(contents.contains(".background(ChildlockColor.primarySoft)\n        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))"))
        XCTAssertTrue(contents.contains("private let handBackContentMaxWidth: CGFloat = 560"))
        XCTAssertTrue(contents.contains(".frame(maxWidth: handBackContentMaxWidth)"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("unpaused"))
        XCTAssertTrue(contents.contains("iOS does not let Screen Time apps automatically reopen arbitrary"))
        XCTAssertTrue(contents.contains("Image(systemName: \"lock.fill\")"))
        XCTAssertFalse(contents.contains("Label(\"I'm a parent\", systemImage: \"lock.fill\")"))
        XCTAssertFalse(contents.contains("Label(\"Parent\", systemImage: \"lock.fill\")"))
        XCTAssertTrue(contents.contains("accessibilityIdentifier(\"parent_unlock_entry\")"))
        XCTAssertTrue(contents.contains("accessibilityLabel(\"Parent unlock\")"))
        XCTAssertTrue(contents.contains(".sheet(isPresented: $isParentUnlockPresented)"))
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

        XCTAssertTrue(contents.contains("Before you hand it over"))
        XCTAssertTrue(contents.contains("Lock this app before you pass it to your child."))
        XCTAssertTrue(contents.contains("Brain breaks still open for your child."))
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
        XCTAssertTrue(dashboard.contains("return \"\\(count) planning label\\(count == 1 ? \"\" : \"s\")\""))
        XCTAssertTrue(dashboard.contains("NavigationLink(value: profile.id)"))
        XCTAssertTrue(dashboard.contains("childProfileSettingsView(profileID: profileID)"))
        XCTAssertTrue(dashboard.contains("Label(\"Make active on this device\", systemImage: \"checkmark.circle\")"))
        XCTAssertTrue(dashboard.contains("\"Tap to edit\""))
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
        XCTAssertTrue(dashboard.contains("settingsStatusToggleRow("))

        for contents in [challenge, math] {
            XCTAssertTrue(contents.contains("accessibilityIdentifier(\"answer_\\(answer)\")"))
            XCTAssertTrue(contents.contains("accessibilityLabel(\"Answer \\(answer)\")"))
            XCTAssertFalse(contents.contains("accessibilityLabel(\"answer_"))
        }

        XCTAssertTrue(memory.contains("accessibilityIdentifier(\"memory_card_\\(index)\")"))
        XCTAssertTrue(memory.contains("Memory card \\(position), hidden"))
        XCTAssertFalse(memory.contains("accessibilityLabel(\"memory_card_"))

        XCTAssertTrue(handBack.contains("accessibilityIdentifier(\"handback_resume_guidance\")"))
        XCTAssertTrue(handBack.contains("accessibilityLabel(\"Back.\")"))
        XCTAssertTrue(handBack.contains("accessibilityIdentifier(\"parent_unlock_entry\")"))
        XCTAssertTrue(handBack.contains("accessibilityLabel(\"Parent unlock\")"))
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
        XCTAssertTrue(contents.contains("private var appsSelectionSectionTitle: String"))
        XCTAssertTrue(contents.contains("return \"PLANNING LABELS\""))
        XCTAssertTrue(contents.contains("private var appsTabSubtitle: String"))
        XCTAssertTrue(contents.contains("Choose real Screen Time items before testing enforcement."))
        XCTAssertTrue(contents.contains("Add a child, then choose what this device should protect."))
        XCTAssertTrue(contents.contains("private var appsAssignmentIntroText: String"))
        XCTAssertTrue(contents.contains("Screen Time selection protects real apps, categories, or websites on this device."))
        XCTAssertTrue(contents.contains("Planning labels help setup, but they do not lock content. Enable Screen Time selection to choose real apps, categories, or websites."))
        XCTAssertTrue(contents.contains("private func monitoredSelectionDetailText(for profile: ChildProfile) -> String"))
        XCTAssertTrue(contents.contains("Planning label only. Not locking content yet."))
        XCTAssertTrue(contents.contains("For a separate child iPad, install and configure Childlock on that iPad too."))
        XCTAssertTrue(contents.contains("canCopyActiveScreenTimeSelection"))
        XCTAssertTrue(contents.contains("Choose real apps, categories, or websites with Screen Time before copying this selection."))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("never interrupted"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("app token"))
        XCTAssertFalse(contents.localizedCaseInsensitiveContains("category token"))
    }

    func testMonitoringStatusUsesParentFriendlyLabels() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("status: monitoringStatusLabel"))
        XCTAssertTrue(dashboard.contains("private var monitoringStatus: ChildlockMonitoringStatus?"))
        XCTAssertTrue(dashboard.contains("return \"Needs attention\""))
        XCTAssertTrue(dashboard.contains("return \"Permission needed\""))
        XCTAssertTrue(dashboard.contains("return \"Brain break pending\""))
        XCTAssertFalse(dashboard.contains("monitoringStatusText.capitalized"))
    }

    func testEnforcementSettingsShowOnlyRelevantStartOrStopAction() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("settingsStatusToggleRow("))
        XCTAssertTrue(dashboard.contains("screenTimeEnforcementBinding"))
        XCTAssertTrue(dashboard.contains("parentDashboardLockBinding"))
        XCTAssertTrue(dashboard.contains("Screen Time Enforcement"))
        XCTAssertTrue(dashboard.contains("Parent Dashboard Lock"))
        XCTAssertFalse(dashboard.contains("Start Lock Enforcement"))
        XCTAssertFalse(dashboard.contains("Stop Lock Enforcement"))
        XCTAssertTrue(dashboard.contains("private var hasActiveScreenTimeSelection: Bool"))
        XCTAssertTrue(dashboard.contains("private var canStartScreenTimeEnforcement: Bool"))
        XCTAssertTrue(dashboard.contains("Choose real apps, categories, or websites in Apps before starting enforcement."))
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
        XCTAssertTrue(dashboard.contains("screenTimeEnforcementGuidanceSteps"))
        XCTAssertTrue(dashboard.contains("ForEach(Array(screenTimeEnforcementGuidanceSteps.enumerated())"))
        XCTAssertTrue(dashboard.contains("Lock the parent dashboard or leave Childlock to auto-lock."))
        XCTAssertTrue(dashboard.contains("Hand this device over and start selected content until Brain Break appears."))
        XCTAssertTrue(dashboard.contains("For a child iPad, run these steps on the iPad."))
        XCTAssertTrue(dashboard.contains("Choose the shortest interval for TestFlight."))
        XCTAssertTrue(dashboard.contains("Start enforcement."))
        XCTAssertTrue(dashboard.contains("Locks this device only. For a child iPad, install Childlock on the iPad and follow setup there."))
        XCTAssertTrue(dashboard.contains("Planning labels don't lock."))
        XCTAssertTrue(dashboard.contains("Choose real apps in Apps."))
        XCTAssertTrue(dashboard.contains("Start, then lock dashboard."))
        XCTAssertTrue(dashboard.contains("Child iPad: repeat setup there."))
        XCTAssertTrue(dashboard.contains("Complete the challenge, then confirm monitoring re-arms"))
    }

    func testParentChildDeviceModelIsClearInAppCopy() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(onboarding.contains("Childlock protects this device. Set it up wherever your child watches or plays."))
        XCTAssertTrue(onboarding.contains("heading: \"Shared iPhone\""))
        XCTAssertTrue(onboarding.contains("Set up here. Lock the dashboard, then hand it over."))
        XCTAssertTrue(onboarding.contains("heading: \"Child iPad\""))
        XCTAssertTrue(onboarding.contains("Install Childlock on the iPad and run setup there."))
        XCTAssertTrue(onboarding.contains("heading: \"Parent-only phone\""))
        XCTAssertTrue(onboarding.contains("Good for account checks. It will not lock a separate iPad."))
        XCTAssertTrue(onboarding.contains("Screen Time controls run where setup is completed. Parent settings still stay behind your PIN."))

        XCTAssertTrue(dashboard.contains("Locks this device only. For a child iPad, install Childlock on the iPad and follow setup there."))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("remotely lock"))
    }

    func testOnboardingScreenTimePickerCopyExplainsDoneStep() throws {
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let viewModel = try readRepoFile("Sources/Childlock/ViewModels/OnboardingViewModel.swift")

        XCTAssertTrue(onboarding.contains("TextField(\"Type your child's name\""))
        XCTAssertTrue(viewModel.contains("Type your child's name to continue."))
        XCTAssertFalse(onboarding.contains("TextField(\"Mia\""))
        XCTAssertTrue(onboarding.contains("Choose apps, categories, or websites"))
        XCTAssertTrue(onboarding.contains("Choose at least one app, category, or website."))
        XCTAssertTrue(onboarding.contains("monitoredSelectionCountText"))
        XCTAssertTrue(onboarding.contains("accessibilityLabel(\"Change apps, categories, or websites\")"))
        XCTAssertFalse(onboarding.contains("No Screen Time items selected yet. If Continue stays disabled"))
        XCTAssertTrue(onboarding.contains("innerStepWithPinnedFooter"))
        XCTAssertTrue(onboarding.contains("setupFooter"))
        XCTAssertTrue(onboarding.contains("shouldShowScreenTimePickerFooterAction"))
        XCTAssertTrue(onboarding.contains("setup_footer_choose_screen_time_items"))
        XCTAssertTrue(onboarding.contains("Open Apple's Screen Time picker to choose apps, categories, or websites."))
        XCTAssertTrue(onboarding.contains(".accessibilityHint(viewModel.setupBlockingReason ?? \"Continue to Parent PIN setup.\")"))
        XCTAssertFalse(onboarding.contains("Choose video apps"))
        XCTAssertFalse(onboarding.contains("Choose games"))
        XCTAssertFalse(onboarding.contains("Choose social apps"))
        XCTAssertTrue(viewModel.contains("Choose at least one app, category, or website in the Screen Time picker, then tap Done."))
        XCTAssertTrue(viewModel.contains("public var needsMonitoringSelection: Bool"))
    }

    func testParentDashboardUsesReadableContentWidthOnIPad() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("dashboardContentMaxWidth"))
        XCTAssertTrue(dashboard.contains("dashboardScrollBottomPadding"))
        XCTAssertTrue(dashboard.contains(".padding(.bottom, dashboardScrollBottomPadding)"))
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
