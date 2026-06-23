import XCTest
@testable import Childlock

final class AuthRedirectConfigTests: XCTestCase {
    @MainActor
    func testGoogleOAuthRedirectMatchesRegisteredURLScheme() throws {
        let redirectURL = AuthService.oauthRedirectURL

        XCTAssertEqual(redirectURL.absoluteString, "childlock://login-callback")
        XCTAssertEqual(redirectURL.scheme, "childlock")
        XCTAssertEqual(redirectURL.host, "login-callback")
        XCTAssertEqual(AuthService.googleOAuthScopes, "openid email profile")

        let infoPlist = try readPropertyList("Sources/Childlock/Info.plist")
        let urlTypes = try XCTUnwrap(infoPlist["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = urlTypes
            .flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }

        XCTAssertTrue(schemes.contains("childlock"))

        let setupGuide = try readRepoFile("docs/SUPABASE_GOOGLE_AUTH.md")
        XCTAssertTrue(setupGuide.contains("childlock://login-callback"))
        XCTAssertTrue(setupGuide.contains("https://jkncpveupvozsmbbkvgq.supabase.co/auth/v1/callback"))
    }

    @MainActor
    func testGoogleOAuthFlowUsesSupabaseWebAuthSession() throws {
        let authService = try readRepoFile("Sources/Childlock/Services/AuthService.swift")
        let onboarding = try readRepoFile("Sources/Childlock/Views/Onboarding/OnboardingFlowView.swift")

        XCTAssertTrue(authService.contains("client.auth.signInWithOAuth("))
        XCTAssertTrue(authService.contains("provider: .google"))
        XCTAssertTrue(authService.contains("redirectTo: Self.oauthRedirectURL"))
        XCTAssertTrue(authService.contains("scopes: Self.googleOAuthScopes"))
        XCTAssertTrue(onboarding.contains("Continue with Google"))
        XCTAssertTrue(onboarding.contains("AuthService.shared.handleGoogleSignIn()"))
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

        XCTAssertTrue(dashboard.contains("Sign Out"))
        XCTAssertTrue(dashboard.contains("Confirm Sign Out"))
        XCTAssertTrue(dashboard.contains("Parent settings stay on this device. Sign in again to manage Childlock."))
        XCTAssertTrue(dashboard.contains("AuthService.shared.signOut()"))
        XCTAssertTrue(dashboard.contains("appState.lockSettings(pinService: pinService)"))
        XCTAssertTrue(dashboard.contains("return ChildlockColor.accent"))
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

        XCTAssertTrue(authService.contains("#if DEBUG public func debugSignIn"))
        XCTAssertTrue(rootView.contains("#if DEBUG private enum DebugLaunchArgument"))
        XCTAssertTrue(rootView.contains("--childlock-qa-seed-onboarding-devices"))
        XCTAssertTrue(rootView.contains("seedDebugOnboardingDevicesStep()"))
        XCTAssertTrue(rootView.contains("onboardingViewModel.step = .devices"))
        XCTAssertTrue(rootView.contains("#if DEBUG challengeViewModel.presentChallenge(for: profile, type: debugForcedChallengeType) #else challengeViewModel.presentChallenge(for: profile) #endif"))
        XCTAssertTrue(checklist.contains("Use Debug builds only. These launch arguments are not part of the Release"))
        XCTAssertTrue(checklist.contains("`--childlock-qa-seed-onboarding-devices`"))
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
