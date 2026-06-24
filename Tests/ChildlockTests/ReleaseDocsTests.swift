import XCTest

final class ReleaseDocsTests: XCTestCase {
    func testAuthDocsMatchProductionSignInModel() throws {
        let appleAuth = try readRepoFile("docs/SUPABASE_APPLE_AUTH.md")
        let googleAuth = try readRepoFile("docs/SUPABASE_GOOGLE_AUTH.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let appReview = try readRepoFile("docs/APP_REVIEW_NOTES.md")

        XCTAssertTrue(appleAuth.contains("Supabase Apple provider: enabled for native iOS sign-in"))
        XCTAssertTrue(appleAuth.contains("Apple Services ID: not needed for the current native iOS flow"))
        XCTAssertFalse(appleAuth.localizedCaseInsensitiveContains("still needs"))
        XCTAssertFalse(appleAuth.localizedCaseInsensitiveContains("not created yet"))

        XCTAssertTrue(googleAuth.contains("native Google Sign-In SDK"))
        XCTAssertTrue(googleAuth.contains("GOOGLE_IOS_CLIENT_ID"))
        XCTAssertTrue(googleAuth.contains("GOOGLE_WEB_CLIENT_ID"))
        XCTAssertTrue(googleAuth.contains("GOOGLE_REVERSED_CLIENT_ID"))
        XCTAssertTrue(googleAuth.contains("Secret location: Supabase dashboard only"))
        XCTAssertTrue(googleAuth.contains("Unsupported provider: missing OAuth secret"))
        XCTAssertTrue(googleAuth.contains("Fix it in Supabase, not Xcode"))
        XCTAssertTrue(googleAuth.contains("TestFlight Proof"))
        XCTAssertTrue(googleAuth.contains("Run this section only for a TestFlight build that includes real"))
        XCTAssertTrue(googleAuth.contains("record Google as N/A in the hardware QA record"))

        for contents in [production, appReview] {
            let normalized = normalizeWhitespace(contents)
            XCTAssertTrue(normalized.contains("Google"))
            XCTAssertTrue(normalized.contains("valid"))
            XCTAssertTrue(normalized.contains("OAuth IDs"))
            XCTAssertTrue(normalized.contains("non-working"))
            XCTAssertTrue(normalized.contains("There is no separate username/password account"))
            XCTAssertFalse(normalized.localizedCaseInsensitiveContains("no-login"))
            XCTAssertFalse(normalized.localizedCaseInsensitiveContains("free trial"))
        }

        let normalizedProduction = normalizeWhitespace(production)
        XCTAssertTrue(normalizedProduction.contains("If the submitted build shows Google sign-in"))
        XCTAssertTrue(normalizedProduction.contains("otherwise, Google should stay hidden and be marked N/A in hardware QA"))
        XCTAssertFalse(normalizedProduction.contains("until the Supabase Apple and Google providers are enabled"))
    }

    func testProductionRunbookKeepsAppSecretsInIgnoredLocalConfig() throws {
        let production = try readRepoFile("docs/PRODUCTION.md")
        let normalized = normalizeWhitespace(production)

        XCTAssertTrue(
            normalized.contains("Fill app-facing production values in `Config/AppSecrets.local.xcconfig`.")
        )
        XCTAssertTrue(
            normalized.contains("The checked-in `Config/AppSecrets.xcconfig` should stay as the safe base config")
        )
        XCTAssertFalse(
            normalized.contains("Fill app-facing production values in `Config/AppSecrets.xcconfig`.")
        )
        XCTAssertTrue(
            normalized.contains("-destination 'generic/platform=iOS' \\ CODE_SIGNING_ALLOWED=NO \\ build")
        )
    }

    func testSupportAndLegalLinksMatchAppStoreMetadata() throws {
        let metadata = try readRepoFile("docs/APP_STORE_CONNECT_METADATA.md")
        let appReview = try readRepoFile("docs/APP_REVIEW_NOTES.md")
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let paywall = try readRepoFile("Sources/Childlock/Views/Paywall/PaywallView.swift")

        let supportURL = "https://kouboulabs.com/childlock/support"
        let privacyURL = "https://kouboulabs.com/childlock/privacy"
        let termsURL = "https://kouboulabs.com/childlock/terms"

        for contents in [metadata, appReview, dashboard] {
            XCTAssertTrue(contents.contains(supportURL))
            XCTAssertTrue(contents.contains(privacyURL))
            XCTAssertTrue(contents.contains(termsURL))
        }

        XCTAssertTrue(dashboard.contains("Help Center"))
        XCTAssertTrue(dashboard.contains("Privacy Policy"))
        XCTAssertTrue(dashboard.contains("Terms of Service"))

        XCTAssertTrue(paywall.contains(privacyURL))
        XCTAssertTrue(paywall.contains(termsURL))
        XCTAssertTrue(paywall.contains("Link(\"Terms\""))
        XCTAssertTrue(paywall.contains("Link(\"Privacy\""))
    }

    func testAppPrivacyLabelsMatchFamilyAppPrivacyPosture() throws {
        let privacyLabels = try readRepoFile("docs/APP_PRIVACY_LABELS.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let metadata = try readRepoFile("docs/APP_STORE_CONNECT_METADATA.md")
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let analyticsService = try readRepoFile("Sources/Childlock/Services/AnalyticsService.swift")
        let dataSync = try readRepoFile("Sources/Childlock/Services/DataSyncService.swift")

        XCTAssertTrue(privacyLabels.contains("Data used to track users across apps and websites owned by other companies:"))
        XCTAssertTrue(privacyLabels.contains("No"))
        XCTAssertTrue(privacyLabels.contains("Contact Info"))
        XCTAssertTrue(privacyLabels.contains("Identifiers"))
        XCTAssertTrue(privacyLabels.contains("Purchases"))
        XCTAssertTrue(privacyLabels.contains("Usage Data"))
        XCTAssertTrue(privacyLabels.contains("Product Interaction"))
        XCTAssertTrue(privacyLabels.contains("Crash Data"))
        XCTAssertTrue(privacyLabels.contains("Raw Screen Time app selection token payloads"))
        XCTAssertTrue(privacyLabels.contains("Child full names in backend sync"))

        XCTAssertTrue(production.contains("docs/APP_PRIVACY_LABELS.md"))
        XCTAssertTrue(metadata.contains("docs/APP_PRIVACY_LABELS.md"))

        XCTAssertTrue(rootView.contains("Keep product analytics aggregate-only for a family app."))
        XCTAssertFalse(rootView.contains("AnalyticsService.identify"))
        XCTAssertFalse(analyticsService.contains("PostHogSDK.shared.identify"))
        XCTAssertFalse(dataSync.contains("monitoredSelectionTokenData"))
    }

    func testLaunchDeviceModelIsConsistentAcrossReviewMaterials() throws {
        let metadata = try readRepoFile("docs/APP_STORE_CONNECT_METADATA.md")
        let appReview = try readRepoFile("docs/APP_REVIEW_NOTES.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let deviceModel = try readRepoFile("docs/DEVICE_MODEL.md")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        for contents in [metadata, appReview, production] {
            let normalized = normalizeWhitespace(contents)
            XCTAssertTrue(normalized.contains("Childlock locks apps on the device where setup is completed."))
            XCTAssertTrue(normalized.contains("For a child iPad"))
            XCTAssertTrue(normalized.contains("install and configure Childlock on the iPad"))
            XCTAssertTrue(normalized.contains("Same-phone parent/child use"))
        }

        XCTAssertTrue(normalizeWhitespace(deviceModel).contains("Do not claim that a parent phone can remotely lock a separate child iPad"))
        XCTAssertTrue(normalizeWhitespace(checklist).contains("Do not claim that a parent-only iPhone install remotely controls a separate child iPad at launch."))
        XCTAssertTrue(normalizeWhitespace(appReview).contains("not presented as a parent-phone remote controller for a separate child iPad in this launch build"))

        for contents in [metadata, appReview, production] {
            XCTAssertFalse(contents.localizedCaseInsensitiveContains("parent phone can remotely lock"))
            XCTAssertFalse(contents.localizedCaseInsensitiveContains("parent-only iPhone install remotely controls a separate child iPad"))
        }
    }

    func testReviewMaterialsMatchContentConsumptionHardwareGate() throws {
        let metadata = try readRepoFile("docs/APP_STORE_CONNECT_METADATA.md")
        let appReview = try readRepoFile("docs/APP_REVIEW_NOTES.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let deviceModel = try readRepoFile("docs/DEVICE_MODEL.md")

        for contents in [metadata, appReview, deviceModel] {
            let normalized = normalizeWhitespace(contents)
            XCTAssertTrue(normalized.contains("selected app/category/site content"))
            XCTAssertFalse(normalized.contains("Open a selected app until the interval threshold is reached."))
            XCTAssertFalse(normalized.contains("Open a selected app and use it until the interval threshold is reached."))
        }

        XCTAssertTrue(
            normalizeWhitespace(metadata).contains(
                "choose the apps, categories, or websites you want to monitor"
            )
        )
        XCTAssertTrue(
            normalizeWhitespace(metadata).contains(
                "Childlock pauses selected content"
            )
        )
        XCTAssertTrue(
            normalizeWhitespace(production).contains(
                "Child starts real selected content and records the start time"
            )
        )
        XCTAssertTrue(
            normalizeWhitespace(production).contains(
                "Threshold shields selected content; record the shield timestamp"
            )
        )
        XCTAssertFalse(production.contains("Threshold shields the selected app."))
        XCTAssertTrue(
            normalizeWhitespace(deviceModel).contains(
                "Confirm the Childlock shield appears after the configured interval."
            )
        )
    }

    func testTestFlightDocsExplainFreshSetupResetForAuthRetesting() throws {
        let production = try readRepoFile("docs/PRODUCTION.md")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        for contents in [production, checklist] {
            let normalized = normalizeWhitespace(contents)
            XCTAssertTrue(normalized.contains("Reset Childlock on this device"))
            XCTAssertTrue(normalized.contains("Sign Out pauses local enforcement and preserves local parent settings for the same signed-in parent account"))
            XCTAssertTrue(normalized.contains("Signing in with a different account starts fresh setup"))
            XCTAssertTrue(normalized.contains("Reset stops local enforcement"))
            XCTAssertTrue(normalized.contains("clears child profiles, app selections, reports, and the parent PIN"))
        }

        XCTAssertTrue(checklist.contains("Parent signs in with Apple"))
        XCTAssertTrue(checklist.contains("If Google OAuth is configured and `Continue with Google` is visible, sign in"))
        XCTAssertTrue(checklist.contains("Confirm the app returns to fresh onboarding with no parent dashboard access."))
        XCTAssertTrue(checklist.contains("If Google OAuth is configured and `Continue with Google` is visible"))
        XCTAssertTrue(checklist.contains("record Google as N/A for this build and keep App Review notes Apple-first"))
        XCTAssertTrue(checklist.contains("start real child-like content"))
        XCTAssertTrue(checklist.contains("Record the content\n    app/activity and start time in the hardware QA record."))
        XCTAssertTrue(checklist.contains("Record the\n    shield timestamp and compare it with the configured interval."))
    }

    func testTestFlightChecklistCapturesLaunchGateEvidence() throws {
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let template = try readRepoFile("docs/HARDWARE_QA_RECORD_TEMPLATE.md")
        let generator = try readRepoFile("scripts/new-hardware-qa-record.sh")
        let readiness = try readRepoFile("scripts/launch-readiness-status.sh")
        let simulatorSeedScript = try readRepoFile("scripts/qa-simulator-seeds.sh")
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let normalizedChecklist = normalizeWhitespace(checklist)
        let normalizedProduction = normalizeWhitespace(production)

        XCTAssertTrue(checklist.contains("## Hardware QA Record"))
        XCTAssertTrue(checklist.contains("| Build number |"))
        XCTAssertTrue(checklist.contains("| Git commit |"))
        XCTAssertTrue(checklist.contains("| Scenario | Same phone / Child iPad / Child iPhone |"))
        XCTAssertTrue(checklist.contains("| Latest simulator QA summary |"))
        XCTAssertTrue(checklist.contains("| Latest simulator QA gallery |"))
        XCTAssertTrue(checklist.contains("| Latest simulator QA contact sheet |"))
        XCTAssertTrue(checklist.contains("Open `gallery.html` for visual review"))
        XCTAssertTrue(checklist.contains("contact-sheet.png"))
        XCTAssertTrue(checklist.contains("| Google OAuth build settings | Configured / Missing or placeholder |"))
        XCTAssertTrue(checklist.contains("| Parent sign-in tested | Apple / Google / N/A |"))
        XCTAssertTrue(checklist.contains("| Content app/activity tested |"))
        XCTAssertTrue(checklist.contains("| Content started at |"))
        XCTAssertTrue(checklist.contains("| Shield appeared at |"))
        XCTAssertTrue(checklist.contains("It pre-fills the build number, date, scenario, git commit"))
        XCTAssertTrue(normalizedChecklist.contains("latest simulator QA gallery and contact-sheet paths"))
        XCTAssertTrue(checklist.contains("| Shield appeared only after threshold | Pass / Fail |"))
        XCTAssertTrue(checklist.contains("| Child manually reopened the now-unshielded content app | Pass / Fail |"))
        XCTAssertTrue(checklist.contains("| Parent dashboard stayed PIN-gated after hand-back | Pass / Fail |"))
        XCTAssertTrue(checklist.contains("| RevenueCat offering loaded monthly and annual packages | Pass / Fail / Not tested |"))
        XCTAssertTrue(checklist.contains("| Purchase activates Childlock Premium entitlement | Pass / Fail / Not tested |"))
        XCTAssertTrue(checklist.contains("| Restore purchases reactivates Premium | Pass / Fail / Not tested |"))
        XCTAssertTrue(checklist.contains("| Premium status persists after app restart | Pass / Fail / Not tested |"))
        XCTAssertTrue(checklist.contains("one purchase and\n  restore pass proving RevenueCat returns monthly/annual packages"))
        XCTAssertTrue(checklist.contains("Complete a sandbox purchase"))
        XCTAssertTrue(checklist.contains("Restore purchases"))
        XCTAssertTrue(checklist.contains("Premium is still active"))
        XCTAssertTrue(checklist.contains("One denied-notification pass proving Home -> Childlock still opens the"))
        XCTAssertTrue(checklist.contains("One second full shield loop on the same device proving monitoring re-arms."))
        XCTAssertTrue(checklist.contains("leaves Childlock to\n   let it auto-lock"))
        XCTAssertTrue(checklist.contains("record Google as N/A"))
        XCTAssertTrue(checklist.contains("confirm the button is hidden"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-onboarding-setup`"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-handback`"))
        XCTAssertTrue(checklist.contains("Continue` stays disabled until Apple's picker"))
        XCTAssertTrue(checklist.contains("disabled action, reason, and `Choose Screen Time items` recovery action"))
        XCTAssertTrue(normalizedChecklist.contains("pinned disabled Continue reason"))
        XCTAssertTrue(normalizedChecklist.contains("disabled Continue reason plus `Choose Screen Time items` action"))
        XCTAssertTrue(checklist.contains("captured 30 screenshots"))
        XCTAssertTrue(checklist.contains("hand-back,\n  more-time request"))
        XCTAssertTrue(checklist.contains("Simulator evidence handoff"))
        XCTAssertTrue(checklist.contains("Do not edit this checklist only to\n  chase a new run ID"))
        XCTAssertTrue(checklist.contains("pre-fills the\n  newest generated simulator summary, gallery, and contact-sheet paths"))
        XCTAssertTrue(normalizedChecklist.contains("A setup seed that falls back to the welcome screen is not a valid pass."))
        XCTAssertTrue(checklist.contains("same-phone/child-iPad TestFlight handoff guidance"))
        XCTAssertTrue(simulatorSeedScript.contains("\"--childlock-qa-seed-onboarding-setup\""))
        XCTAssertTrue(rootView.contains("static let onboardingSetup = \"--childlock-qa-seed-onboarding-setup\""))
        XCTAssertTrue(rootView.contains("seedDebugOnboardingSetupStep()"))
        XCTAssertTrue(rootView.contains("restoreDebugOnboardingSetupSeedIfNeeded()"))
        XCTAssertTrue(checklist.contains("scripts/new-hardware-qa-record.sh same-phone <build-number>"))
        XCTAssertTrue(checklist.contains("docs/HARDWARE_QA_RECORD_TEMPLATE.md"))
        XCTAssertFalse(checklist.contains("20260624-140331"))
        XCTAssertTrue(normalizedChecklist.contains("Hardware QA records above are filled in with no unresolved launch blockers."))
        XCTAssertTrue(normalizedProduction.contains("generate and complete hardware QA records with `scripts/new-hardware-qa-record.sh`"))
        XCTAssertTrue(normalizedProduction.contains("`.build/hardware-qa-records/`"))
        XCTAssertTrue(normalizedProduction.contains("Do not treat a simulator pass or a successful archive upload as proof"))
        XCTAssertTrue(normalizedProduction.contains("Hardware records with `pending-testflight-build`, unfilled device metadata, or unresolved `Pass / Fail` choices are still reported as pending/incomplete"))
        XCTAssertTrue(normalizedProduction.contains("RevenueCat loads monthly and annual packages, sandbox purchase activates `Childlock Pro`, restore purchases reactivates Premium, and Premium remains active after app restart"))
        XCTAssertTrue(checklist.contains("pending TestFlight build"))
        XCTAssertTrue(checklist.contains("incomplete\nchecklist"))

        XCTAssertTrue(template.contains("## Required Shield Loop"))
        XCTAssertTrue(template.contains("| Git commit |"))
        XCTAssertTrue(template.contains("| Latest simulator QA summary |"))
        XCTAssertTrue(template.contains("| Latest simulator QA gallery |"))
        XCTAssertTrue(template.contains("| Latest simulator QA contact sheet |"))
        XCTAssertTrue(template.contains("| Google OAuth build settings | Configured / Missing or placeholder |"))
        XCTAssertTrue(template.contains("| Parent sign-in tested | Apple / Google / N/A |"))
        XCTAssertTrue(template.contains("| Content app/activity tested |"))
        XCTAssertTrue(template.contains("| Content started at |"))
        XCTAssertTrue(template.contains("| Shield appeared at |"))
        XCTAssertTrue(template.contains("Child continuously consumes selected content during the interval"))
        XCTAssertTrue(template.contains("Second full interval shields again"))
        XCTAssertTrue(template.contains("Child manually reopens the now-unshielded content app"))
        XCTAssertTrue(template.contains("| RevenueCat offering loaded monthly and annual packages | Pass / Fail / Not tested |"))
        XCTAssertTrue(template.contains("| Purchase activates Childlock Premium entitlement | Pass / Fail / Not tested |"))
        XCTAssertTrue(template.contains("| Restore purchases reactivates Premium | Pass / Fail / Not tested |"))
        XCTAssertTrue(template.contains("| Premium status persists after app restart | Pass / Fail / Not tested |"))
        XCTAssertTrue(template.contains("RevenueCat purchase and restore QA passes if subscriptions remain attached to this app version"))
        XCTAssertTrue(template.contains("Child solves the challenge and manually reopens the unlocked app"))
        XCTAssertTrue(template.contains("Denied-notification fallback opens the pending challenge from Home"))
        XCTAssertTrue(template.contains("## Same Phone Scenario"))
        XCTAssertTrue(template.contains("parent taps `Make active` for the child before handoff"))
        XCTAssertTrue(template.contains("Child continuously uses selected content until threshold is reached"))
        XCTAssertTrue(template.contains("## Child iPad Scenario"))
        XCTAssertTrue(template.contains("Child continuously uses selected iPad content until threshold is reached"))
        XCTAssertTrue(template.contains("Parent-only iPhone install is not treated as remote iPad control"))
        XCTAssertTrue(template.contains("Google sign-in works in TestFlight if Google OAuth is configured"))

        XCTAssertTrue(generator.contains(".build/hardware-qa-records"))
        XCTAssertTrue(generator.contains("docs/HARDWARE_QA_RECORD_TEMPLATE.md"))
        XCTAssertTrue(generator.contains("google_oauth_build_status"))
        XCTAssertTrue(generator.contains("replace_row \"Google OAuth build settings\" \"$google_oauth_status\""))
        XCTAssertTrue(generator.contains("GOOGLE_REVERSED_CLIENT_ID"))
        XCTAssertTrue(generator.contains("replace_row \"Build number\" \"$build_number\""))
        XCTAssertTrue(generator.contains("replace_row \"Git commit\" \"$git_commit\""))
        XCTAssertTrue(generator.contains("replace_row \"Scenario\" \"$scenario_label\""))
        XCTAssertTrue(generator.contains("replace_row \"Latest simulator QA summary\" \"$latest_simulator_summary\""))
        XCTAssertTrue(generator.contains("replace_row \"Latest simulator QA gallery\" \"$latest_simulator_gallery\""))
        XCTAssertTrue(generator.contains("replace_row \"Latest simulator QA contact sheet\" \"$latest_simulator_contact_sheet\""))
        XCTAssertTrue(generator.contains("same-phone)"))
        XCTAssertTrue(generator.contains("child-ipad)"))
        XCTAssertTrue(readiness.contains("RevenueCat offering loaded monthly and annual packages"))
        XCTAssertTrue(readiness.contains("Purchase activates Childlock Premium entitlement"))
        XCTAssertTrue(readiness.contains("Restore purchases reactivates Premium"))
        XCTAssertTrue(readiness.contains("Premium status persists after app restart"))
        XCTAssertTrue(readiness.contains("incomplete paid-flow QA"))
        XCTAssertTrue(simulatorSeedScript.contains("Git commit: $GIT_COMMIT"))
        XCTAssertTrue(simulatorSeedScript.contains("Git commit $GIT_COMMIT"))
        XCTAssertTrue(simulatorSeedScript.contains("gallery.html"))
        XCTAssertTrue(simulatorSeedScript.contains("CONTACT_SHEET_PATH"))
        XCTAssertTrue(simulatorSeedScript.contains("OUTPUT_DIR_FOR_CONTACT_SHEET"))
        XCTAssertTrue(simulatorSeedScript.contains("contact-sheet.png"))
    }

    func testScreenTimeSelectionTokensStayOutOfBackendSync() throws {
        let dataSync = try readRepoFile("Sources/Childlock/Services/DataSyncService.swift")
        let migration = try readRepoFile("supabase/migrations/20260521000000_initial_childlock_backend.sql")
        let appReview = try readRepoFile("docs/APP_REVIEW_NOTES.md")
        let deviceModel = try readRepoFile("docs/DEVICE_MODEL.md")

        XCTAssertTrue(normalizeWhitespace(appReview).contains("Opaque app selection tokens remain local/on-device."))
        XCTAssertTrue(deviceModel.contains("Do not store or sync raw Screen Time selection token payloads."))

        for forbidden in [
            "monitoredActivitiesData",
            "monitoredSelectionTokenData",
            "selectionTokenData",
            "FamilyActivitySelection",
            "monitored_activities",
            "selection_token",
        ] {
            XCTAssertFalse(
                dataSync.contains(forbidden),
                "DataSyncService must not send raw FamilyControls selection payloads: \(forbidden)"
            )
        }

        for forbidden in [
            "monitored_activities",
            "selection_token",
            "family_activity",
            "screen_time_selection",
        ] {
            XCTAssertFalse(
                migration.localizedCaseInsensitiveContains(forbidden),
                "Backend schema must not store raw Screen Time selection payloads: \(forbidden)"
            )
        }
    }

    func testSupabaseMigrationExplicitlyGrantsAuthenticatedAndServiceRoleAccess() throws {
        let migration = normalizeWhitespace(
            try readRepoFile("supabase/migrations/20260521000000_initial_childlock_backend.sql")
        )
        let tables = """
        public.parent_profiles, public.child_profiles, public.app_settings, \
        public.challenge_sessions, public.challenge_results, public.device_installs, \
        public.subscription_status
        """
        let normalizedTables = normalizeWhitespace(tables)

        XCTAssertTrue(migration.contains("grant usage on schema public to anon, authenticated, service_role;"))
        XCTAssertTrue(migration.contains("grant select, insert, update, delete on \(normalizedTables) to authenticated;"))
        XCTAssertTrue(migration.contains("grant select, insert, update, delete on \(normalizedTables) to service_role;"))

        XCTAssertTrue(migration.contains("create index if not exists challenge_sessions_child_profile_id_idx"))
        XCTAssertTrue(migration.contains("create index if not exists challenge_results_session_id_idx"))
        XCTAssertTrue(migration.contains("create index if not exists challenge_results_child_profile_id_idx"))
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
