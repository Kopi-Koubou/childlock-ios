import XCTest
@testable import Childlock

final class AuthRedirectConfigTests: XCTestCase {
    @MainActor
    func testGoogleSignInConfigMatchesRegisteredURLSchemes() throws {
        let redirectURL = AuthService.oauthRedirectURL

        XCTAssertEqual(redirectURL.absoluteString, "childlock://login-callback")
        XCTAssertEqual(redirectURL.scheme, "childlock")
        XCTAssertEqual(redirectURL.host, "login-callback")

        let infoPlist = try readPropertyList("Sources/Childlock/Info.plist")
        XCTAssertEqual(infoPlist["GIDClientID"] as? String, "$(GOOGLE_IOS_CLIENT_ID)")
        XCTAssertEqual(infoPlist["GOOGLE_REVERSED_CLIENT_ID"] as? String, "$(GOOGLE_REVERSED_CLIENT_ID)")

        let urlTypes = try XCTUnwrap(infoPlist["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = urlTypes
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        XCTAssertTrue(schemes.contains("childlock"))
        XCTAssertTrue(schemes.contains("$(GOOGLE_REVERSED_CLIENT_ID)"))

        let setupGuide = try readRepoFile("docs/SUPABASE_GOOGLE_AUTH.md")
        XCTAssertTrue(setupGuide.contains("GOOGLE_IOS_CLIENT_ID"))
        XCTAssertTrue(setupGuide.contains("GOOGLE_REVERSED_CLIENT_ID"))
        XCTAssertTrue(setupGuide.contains("The reversed client ID must match the iOS client ID prefix exactly"))
    }

    @MainActor
    func testGoogleSignInFlowUsesNativeGoogleSDKAndSupabaseIdToken() throws {
        let authService = try readRepoFile("Sources/Childlock/Services/AuthService.swift")
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")

        XCTAssertTrue(authService.contains("import GoogleSignIn"))
        XCTAssertTrue(authService.contains("GIDSignIn.sharedInstance.signIn(withPresenting:"))
        XCTAssertTrue(authService.contains("GIDSignIn.sharedInstance.handle(url)"))
        XCTAssertTrue(authService.contains("client.auth.signInWithIdToken("))
        XCTAssertTrue(authService.contains("provider: .google"))
        XCTAssertTrue(authService.contains("idToken: idToken"))
        XCTAssertTrue(authService.contains("accessToken: result.user.accessToken.tokenString"))
        XCTAssertTrue(rootView.contains("if authService.handleGoogleRedirectURL(url)"))
        XCTAssertTrue(onboarding.contains("Continue with Google"))
        XCTAssertTrue(onboarding.contains("Connecting to Google"))
        XCTAssertTrue(onboarding.contains("GoogleSignInButtonLabel(isInProgress: isGoogleSignInInProgress)"))
        XCTAssertTrue(onboarding.contains("AuthService.shared.handleGoogleSignIn()"))
        XCTAssertTrue(onboarding.contains(".accessibilityElement(children: .ignore)"))
    }

    func testGoogleOAuthSecretsStayOutOfAppConfig() throws {
        let package = try readRepoFile("Package.swift")
        let credentials = try readRepoFile("Config/CREDENTIALS.md")
        let appSecretsExample = try readRepoFile("Config/AppSecrets.xcconfig.example")
        let authService = try readRepoFile("Sources/Childlock/Services/AuthService.swift")

        XCTAssertTrue(package.contains("https://github.com/google/GoogleSignIn-iOS.git"))
        XCTAssertTrue(package.contains(".product(name: \"GoogleSignIn\", package: \"GoogleSignIn-iOS\")"))
        XCTAssertTrue(appSecretsExample.contains("GOOGLE_IOS_CLIENT_ID"))
        XCTAssertTrue(appSecretsExample.contains("GOOGLE_REVERSED_CLIENT_ID"))
        XCTAssertFalse(appSecretsExample.contains("GOOGLE_CLIENT_SECRET"))
        XCTAssertFalse(authService.contains("GOOGLE_CLIENT_SECRET"))
        XCTAssertTrue(credentials.contains("Google iOS client ID and reversed client ID are public app-facing values"))
        XCTAssertTrue(credentials.contains("Google Web client ID and client secret belong only in the Supabase Google auth"))
    }

    @MainActor
    func testOAuthCallbackOnlyAcceptsLoginCallbackDeepLink() {
        XCTAssertTrue(AuthService.isOAuthRedirectURL(URL(string: "childlock://login-callback?code=abc")!))
        XCTAssertTrue(AuthService.isOAuthRedirectURL(URL(string: "childlock://login-callback#access_token=abc")!))

        XCTAssertFalse(AuthService.isOAuthRedirectURL(URL(string: "childlock://settings?code=abc")!))
        XCTAssertFalse(AuthService.isOAuthRedirectURL(URL(string: "https://login-callback?code=abc")!))
    }

    func testAppleSignInNonceFailureIsRecoverable() throws {
        let signInView = try readRepoFile("Sources/Childlock/Views/Onboarding/SignInWithAppleView.swift")

        XCTAssertFalse(signInView.contains("fatalError"))
        XCTAssertTrue(signInView.contains("nonceGenerationFailed"))
        XCTAssertTrue(signInView.contains("Secure sign-in could not be prepared. Please try again."))
    }

    func testParentSettingsExposeConfirmedSignOut() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")

        XCTAssertTrue(dashboard.contains("Sign Out"))
        XCTAssertTrue(dashboard.contains("Confirm Sign Out"))
        XCTAssertTrue(dashboard.contains("Local enforcement pauses. Parent settings stay on this device"))
        XCTAssertTrue(dashboard.contains("profilesToStop.forEach { ScreenTimeManager.shared.stopMonitoring(profile: $0) }"))
        XCTAssertTrue(dashboard.contains("NotificationService.clearShieldFlowAlerts()"))
        XCTAssertTrue(dashboard.contains("AuthService.shared.signOut()"))
        XCTAssertTrue(dashboard.contains("appState.lockSettings(pinService: pinService)"))
        XCTAssertFalse(dashboard.contains("private func signOut() {\n        SharedDefaults.clearLocalSetupState()"))
        XCTAssertFalse(dashboard.contains("private func signOut() {\n        pinService.clearPIN()"))
        XCTAssertTrue(dashboard.contains("return ChildlockColor.accent"))
        XCTAssertTrue(rootView.contains("resetOnboardingForFreshSignIn()"))
        XCTAssertTrue(rootView.contains("case .signedOut, .unknown:"))
    }

    func testParentSettingsExposeConfirmedDeviceResetWithoutMakingSignOutDestructive() throws {
        let dashboard = try readRepoFile("Sources/Childlock/Views/Dashboard/ParentDashboardView.swift")

        XCTAssertTrue(dashboard.contains("Reset Childlock on this device"))
        XCTAssertTrue(dashboard.contains("Confirm Reset"))
        XCTAssertTrue(dashboard.contains("This stops local enforcement, clears child profiles, app selections, reports, and the parent PIN on this device."))
        XCTAssertTrue(dashboard.contains("private func resetLocalSetup()"))
        XCTAssertTrue(dashboard.contains("profilesToStop.forEach { ScreenTimeManager.shared.stopMonitoring(profile: $0) }"))
        XCTAssertTrue(dashboard.contains("SharedDefaults.clearLocalSetupState()"))
        XCTAssertTrue(dashboard.contains("pinService.clearPIN()"))
        XCTAssertTrue(dashboard.contains("appState.resetForFreshSetup()"))
        XCTAssertTrue(dashboard.contains("private func signOut()"))
        XCTAssertTrue(dashboard.contains("Local enforcement pauses. Parent settings stay on this device"))
    }

    func testRootResetsStaleOnboardingStateAfterDeviceReset() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let normalizedRootView = normalizeWhitespace(rootView)

        XCTAssertTrue(rootView.contains(".onChange(of: appState.hasCompletedOnboarding)"))
        XCTAssertTrue(rootView.contains("private func resetOnboardingForFreshSignIn()"))
        XCTAssertTrue(rootView.contains("onboardingViewModel = OnboardingViewModel()"))
        XCTAssertTrue(
            normalizedRootView.contains(
                ".onChange(of: appState.hasCompletedOnboarding) { _, hasCompletedOnboarding in if !hasCompletedOnboarding { resetOnboardingForFreshSignIn() } }"
            )
        )
    }

    func testExistingSignedInSessionResumesOnboardingPastWelcome() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let normalizedRootView = normalizeWhitespace(rootView)

        XCTAssertTrue(rootView.contains("resumeOnboardingAfterExistingSignInIfNeeded()"))
        XCTAssertTrue(rootView.contains("guard !appState.hasCompletedOnboarding else { return }"))
        XCTAssertTrue(rootView.contains("onboardingViewModel.markSignupComplete()"))
        XCTAssertTrue(rootView.contains("if onboardingViewModel.step == .welcome"))
        XCTAssertTrue(rootView.contains("onboardingViewModel.goNext()"))
        XCTAssertTrue(
            normalizedRootView.contains(
                "case .signedIn(let userID): appState.isAuthenticated = true resumeOnboardingAfterExistingSignInIfNeeded() syncServicesForAuthenticatedUserIfNeeded(userID)"
            )
        )
    }

    func testResolvedAuthSessionSyncsProductionSDKUserState() throws {
        let rootView = try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        let analyticsService = try readRepoFile("Sources/Childlock/Services/AnalyticsService.swift")

        XCTAssertTrue(rootView.contains("@State private var syncedAuthenticatedUserID: String?"))
        XCTAssertTrue(rootView.contains("Keep product analytics aggregate-only for a family app."))
        XCTAssertFalse(rootView.contains("AnalyticsService.identify(userID: userID)"))
        XCTAssertFalse(analyticsService.contains("PostHogSDK.shared.identify"))
        XCTAssertTrue(rootView.contains("await SubscriptionService.shared.logIn(appUserID: userID)"))
        XCTAssertTrue(rootView.contains("if appState.hasCompletedOnboarding"))
        XCTAssertTrue(rootView.contains("try? await DataSyncService.shared.sync(appState: appState)"))
        XCTAssertTrue(rootView.contains("AnalyticsService.reset()"))
        XCTAssertTrue(rootView.contains("await SubscriptionService.shared.logOut()"))
    }

    func testProductionSignInDoesNotExposeNoLoginFallbacks() throws {
        let authService = try readRepoFile("Sources/Childlock/Services/AuthService.swift")
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")

        XCTAssertTrue(authService.contains("failSignIn(\"Account setup is unavailable right now. Please try again later.\")"))
        XCTAssertTrue(authService.contains("Google sign in is not available in this build. Please use Sign in with Apple for now."))
        XCTAssertFalse(authService.contains("Add the Google iOS client ID"))
        XCTAssertFalse(authService.contains("URL scheme, then try again"))
        XCTAssertFalse(authService.contains("identity token. Check the Google iOS client"))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("dev-user"))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("try a demo"))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("skip for now"))
        XCTAssertFalse(onboarding.localizedCaseInsensitiveContains("continue without"))
    }

    func testDebugLaunchSeedsStayDebugOnly() throws {
        let authService = normalizeWhitespace(
            try readRepoFile("Sources/Childlock/Services/AuthService.swift")
        )
        let rootView = normalizeWhitespace(
            try readRepoFile("Sources/Childlock/App/ChildlockRootView.swift")
        )
        let checklist = try readRepoFile("docs/QA_TESTFLIGHT_CHECKLIST.md")
        let simulatorQA = try readRepoFile("scripts/qa-simulator-seeds.sh")

        XCTAssertTrue(authService.contains("#if DEBUG public func debugSignIn"))
        XCTAssertTrue(rootView.contains("#if DEBUG private enum DebugLaunchArgument"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-onboarding-devices"))
        XCTAssertTrue(rootView.contains("seedDebugOnboardingDevicesStep()"))
        XCTAssertTrue(rootView.contains("restoreDebugOnboardingDevicesSeedIfNeeded()"))
        XCTAssertTrue(rootView.contains("onboardingViewModel.step = .devices"))
        XCTAssertTrue(rootView.contains("ProcessInfo.processInfo.arguments.contains(DebugLaunchArgument.onboardingDevices)"))
        XCTAssertTrue(rootView.contains("#if DEBUG challengeViewModel.presentChallenge(for: profile, type: debugForcedChallengeType) #else challengeViewModel.presentChallenge(for: profile) #endif"))
        XCTAssertTrue(checklist.contains("Use Debug builds only. These launch arguments are not part of the Release"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-onboarding-devices`"))
        XCTAssertTrue(checklist.contains("scripts/qa-simulator-seeds.sh"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-reset"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-onboarding-devices"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-dashboard"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-locked-dashboard"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-pending-challenge"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-pending-math-challenge"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-pending-memory-challenge"))
        XCTAssertTrue(simulatorQA.contains("--childlock-qa-seed-more-time-request"))
        XCTAssertTrue(simulatorQA.contains(".build/qa-simulator-seeds"))
        XCTAssertTrue(simulatorQA.contains("expected_screenshot_count"))
    }

    private func readPropertyList(_ relativePath: String) throws -> [String: Any] {
        let data = try Data(contentsOf: repoRoot.appendingPathComponent(relativePath))
        let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func readRepoFile(_ relativePath: String) throws -> String {
        try String(contentsOf: repoRoot.appendingPathComponent(relativePath), encoding: .utf8)
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func normalizeWhitespace(_ contents: String) -> String {
        contents
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }
}
