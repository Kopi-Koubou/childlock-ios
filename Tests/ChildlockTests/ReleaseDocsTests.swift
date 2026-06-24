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

        for contents in [production, appReview] {
            XCTAssertTrue(contents.contains("Apple or Google"))
            XCTAssertTrue(contents.contains("There is no separate username/password account"))
            XCTAssertFalse(contents.localizedCaseInsensitiveContains("no-login"))
            XCTAssertFalse(contents.localizedCaseInsensitiveContains("free trial"))
        }
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

    func testTestFlightDocsExplainFreshSetupResetForAuthRetesting() throws {
        let production = try readRepoFile("docs/PRODUCTION.md")
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")

        for contents in [production, checklist] {
            let normalized = normalizeWhitespace(contents)
            XCTAssertTrue(normalized.contains("Reset Childlock on this device"))
            XCTAssertTrue(normalized.contains("Sign Out pauses local enforcement and preserves local parent settings"))
            XCTAssertTrue(normalized.contains("Reset stops local enforcement"))
            XCTAssertTrue(normalized.contains("clears child profiles, app selections, reports, and the parent PIN"))
        }

        XCTAssertTrue(checklist.contains("Parent signs in with Apple"))
        XCTAssertTrue(checklist.contains("Sign in with Google and complete setup again."))
        XCTAssertTrue(checklist.contains("Confirm the app returns to fresh onboarding with no parent dashboard access."))
    }

    func testTestFlightChecklistCapturesLaunchGateEvidence() throws {
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")
        let production = try readRepoFile("docs/PRODUCTION.md")
        let template = try readRepoFile("docs/HARDWARE_QA_RECORD_TEMPLATE.md")
        let generator = try readRepoFile("scripts/new-hardware-qa-record.sh")
        let normalizedChecklist = normalizeWhitespace(checklist)
        let normalizedProduction = normalizeWhitespace(production)

        XCTAssertTrue(checklist.contains("## Hardware QA Record"))
        XCTAssertTrue(checklist.contains("| Build number |"))
        XCTAssertTrue(checklist.contains("| Git commit |"))
        XCTAssertTrue(checklist.contains("| Scenario | Same phone / Child iPad / Child iPhone |"))
        XCTAssertTrue(checklist.contains("| Latest simulator QA summary |"))
        XCTAssertTrue(checklist.contains("It pre-fills the build number, date, scenario, git commit"))
        XCTAssertTrue(checklist.contains("| Shield appeared only after threshold | Pass / Fail |"))
        XCTAssertTrue(checklist.contains("| Parent dashboard stayed PIN-gated after hand-back | Pass / Fail |"))
        XCTAssertTrue(checklist.contains("One denied-notification pass proving Home -> Childlock still opens the"))
        XCTAssertTrue(checklist.contains("One second full shield loop on the same device proving monitoring re-arms."))
        XCTAssertTrue(checklist.contains("interactive `--childlock-qa-seed-pending-math-challenge`"))
        XCTAssertTrue(checklist.contains("kept the parent\n  dashboard behind the PIN"))
        XCTAssertTrue(checklist.contains("recorded the new\n  Math activity in Recent Activity"))
        XCTAssertTrue(checklist.contains("scripts/new-hardware-qa-record.sh same-phone <build-number>"))
        XCTAssertTrue(checklist.contains("docs/HARDWARE_QA_RECORD_TEMPLATE.md"))
        XCTAssertTrue(normalizedChecklist.contains("Hardware QA records above are filled in with no unresolved launch blockers."))
        XCTAssertTrue(normalizedProduction.contains("fill in the hardware QA records in `docs/QA_TESTFLIGHT_CHECKLIST.md`"))
        XCTAssertTrue(normalizedProduction.contains("Do not treat a simulator pass or a successful archive upload as proof"))

        XCTAssertTrue(template.contains("## Required Shield Loop"))
        XCTAssertTrue(template.contains("| Git commit |"))
        XCTAssertTrue(template.contains("| Latest simulator QA summary |"))
        XCTAssertTrue(template.contains("Second full interval shields again"))
        XCTAssertTrue(template.contains("## Same Phone Scenario"))
        XCTAssertTrue(template.contains("## Child iPad Scenario"))
        XCTAssertTrue(template.contains("Parent-only iPhone install is not treated as remote iPad control"))
        XCTAssertTrue(template.contains("Google sign-in works in TestFlight"))

        XCTAssertTrue(generator.contains(".build/hardware-qa-records"))
        XCTAssertTrue(generator.contains("docs/HARDWARE_QA_RECORD_TEMPLATE.md"))
        XCTAssertTrue(generator.contains("replace_row \"Build number\" \"$build_number\""))
        XCTAssertTrue(generator.contains("replace_row \"Git commit\" \"$git_commit\""))
        XCTAssertTrue(generator.contains("replace_row \"Scenario\" \"$scenario_label\""))
        XCTAssertTrue(generator.contains("replace_row \"Latest simulator QA summary\" \"$latest_simulator_summary\""))
        XCTAssertTrue(generator.contains("same-phone)"))
        XCTAssertTrue(generator.contains("child-ipad)"))
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
