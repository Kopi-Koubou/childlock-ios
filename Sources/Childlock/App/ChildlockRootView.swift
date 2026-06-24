import SwiftUI

public struct ChildlockRootView: View {
    @State private var appState = AppState.shared
    @State private var authService = AuthService.shared
    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var challengeViewModel = ChallengeViewModel()
    @State private var syncedAuthenticatedUserID: String?
    #if DEBUG
    @State private var didApplyDebugLaunchSeed = false
    #endif
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    private var isChallengePresented: Bool {
        challengeViewModel.challenge != nil
    }

    private var challengeOverlay: some View {
        ChallengeContainerView(viewModel: challengeViewModel) {
            appState.isPINLocked = false
        }
            .interactiveDismissDisabled(true)
    }

    private var canShowDashboard: Bool {
        appState.hasCompletedOnboarding && authService.isSignedIn
    }

    private var rootContent: some View {
        ZStack {
            ChildlockColor.background.ignoresSafeArea()

            if canShowDashboard {
                ParentDashboardView(appState: appState, onTriggerChallenge: { triggerChallenge() })
            } else {
                OnboardingFlowView(viewModel: onboardingViewModel)
                    .onChange(of: onboardingViewModel.isComplete) { _, isComplete in
                        if isComplete {
                            completeOnboardingIfNeeded()
                        }
                    }
            }
        }
        .onAppear {
            #if DEBUG
            applyDebugLaunchSeedIfNeeded()
            #endif

            syncAuthState()

            challengeViewModel.onCompletedResult = { result in
                guard let profileID = appState.activeProfileID ?? appState.activeProfile?.id else {
                    return
                }
                appState.recordChallengeResult(result, for: profileID)
                Task {
                    try? await DataSyncService.shared.sync(appState: appState)
                }
            }

            // Enforcement is not quota-gated: every completed challenge should
            // re-arm monitoring for the next full interval.
            challengeViewModel.shouldRearmAfterCompletion = { true }

            presentPendingChallengeIfNeeded()
        }
        .onChange(of: authService.state) { _, _ in
            syncAuthState()
            presentPendingChallengeIfNeeded()
        }
        .onChange(of: appState.hasCompletedOnboarding) { _, hasCompletedOnboarding in
            if !hasCompletedOnboarding {
                resetOnboardingForFreshSignIn()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // The shield can't open this app directly: the child taps the shield,
                // lands on the home screen, and opens Childlock — so the pending
                // challenge must be picked up on every foreground, not just launch.
                presentPendingChallengeIfNeeded()
            } else {
                lockParentDashboardIfNeeded()
            }
        }
        .onOpenURL { url in
            if authService.handleGoogleRedirectURL(url) {
                return
            }

            Task {
                let didCompleteOAuth = await authService.handleOAuthCallback(url)
                if didCompleteOAuth {
                    syncAuthState()
                    onboardingViewModel.markSignupComplete()
                    if onboardingViewModel.step == .welcome {
                        onboardingViewModel.goNext()
                    }
                }
            }
        }
    }

    private func presentPendingChallengeIfNeeded() {
        guard canShowDashboard else { return }
        guard challengeViewModel.challenge == nil else { return }
        guard !hasActiveMoreTimeRequest else { return }
        guard SharedDefaults.shared.bool(forKey: SharedDefaults.Key.challengePending) else { return }
        triggerPendingChallenge()
    }

    private var hasActiveMoreTimeRequest: Bool {
        SharedDefaults.shared.integer(forKey: SharedDefaults.Key.moreTimeRequestCount) > 0
    }

    private func lockParentDashboardIfNeeded() {
        guard canShowDashboard else { return }
        guard !appState.isPINLocked else { return }
        appState.lockSettings()
    }

    @ViewBuilder
    public var body: some View {
        ZStack {
            if isChallengePresented {
                challengeOverlay
                    .zIndex(1)
            } else {
                rootContent
            }
        }
    }

    private func completeOnboardingIfNeeded() {
        guard !appState.hasCompletedOnboarding else { return }
        guard let authUserID = authService.userID else { return }
        guard let output = onboardingViewModel.buildOutput() else { return }

        guard PINService.shared.setPIN(output.parentPIN) else {
            onboardingViewModel.failCompletion("Could not save your parent PIN. Please try again before handing this device to your child.")
            return
        }

        appState.completeOnboarding(with: output.profile, pinConfigured: true)
        onboardingViewModel.clearPersistedSelection()

        // The monitor extension announces brain breaks via local notification —
        // without this permission the child gets no cue to open Childlock.
        Task {
            _ = await NotificationService.requestPermission()
        }

        appState.isAuthenticated = true
        Task {
            await SubscriptionService.shared.logIn(appUserID: authUserID)
            try? await DataSyncService.shared.sync(appState: appState)
        }

        if output.authorizationGranted {
            do {
                try ScreenTimeManager.shared.startMonitoring(profile: output.profile)
            } catch {
                SharedDefaults.shared.set(
                    "Failed to start monitoring: \(error.localizedDescription)",
                    forKey: SharedDefaults.Key.monitoringLastError
                )
                SharedDefaults.shared.set("failed", forKey: SharedDefaults.Key.monitoringStatus)
            }
        }

        SharedDefaults.shared.set(output.profile.id.uuidString, forKey: SharedDefaults.Key.activeProfileID)
    }

    private func syncAuthState() {
        switch authService.state {
        case .signedIn(let userID):
            appState.isAuthenticated = true
            resumeOnboardingAfterExistingSignInIfNeeded()
            syncServicesForAuthenticatedUserIfNeeded(userID)
        case .signedOut, .unknown:
            appState.isAuthenticated = false
            resetOnboardingForFreshSignIn()
            clearAuthenticatedServiceSessionIfNeeded()
        }
    }

    private func syncServicesForAuthenticatedUserIfNeeded(_ userID: String) {
        guard syncedAuthenticatedUserID != userID else { return }
        syncedAuthenticatedUserID = userID

        // Keep product analytics aggregate-only for a family app. Account-linked
        // state belongs in Supabase and RevenueCat, where it is needed.
        Task {
            await SubscriptionService.shared.logIn(appUserID: userID)
            if appState.hasCompletedOnboarding {
                try? await DataSyncService.shared.sync(appState: appState)
            }
        }
    }

    private func clearAuthenticatedServiceSessionIfNeeded() {
        guard syncedAuthenticatedUserID != nil else { return }
        syncedAuthenticatedUserID = nil

        AnalyticsService.reset()
        Task {
            await SubscriptionService.shared.logOut()
        }
    }

    private func resumeOnboardingAfterExistingSignInIfNeeded() {
        guard !appState.hasCompletedOnboarding else { return }

        onboardingViewModel.markSignupComplete()
        if onboardingViewModel.step == .welcome {
            onboardingViewModel.goNext()
        }
    }

    private func resetOnboardingForFreshSignIn() {
        onboardingViewModel = OnboardingViewModel()

        #if DEBUG
        restoreDebugOnboardingDevicesSeedIfNeeded()
        #endif
    }

    private func triggerPendingChallenge() {
        if
            let profileIDString = SharedDefaults.shared.string(forKey: SharedDefaults.Key.activeMonitoringProfileID)
                ?? SharedDefaults.shared.string(forKey: SharedDefaults.Key.activeProfileID),
            let profileID = UUID(uuidString: profileIDString),
            let profile = appState.profiles.first(where: { $0.id == profileID })
        {
            triggerChallenge(for: profile)
            return
        }

        triggerChallenge()
    }

    private func triggerChallenge(for profile: ChildProfile? = nil) {
        guard let profile = profile ?? appState.activeProfile else { return }

        appState.activeProfileID = profile.id
        #if DEBUG
        challengeViewModel.presentChallenge(for: profile, type: debugForcedChallengeType)
        #else
        challengeViewModel.presentChallenge(for: profile)
        #endif
        appState.activeChallenge = challengeViewModel.challenge

        SharedDefaults.shared.set(true, forKey: SharedDefaults.Key.challengePending)
        SharedDefaults.shared.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeProfileID)
    }

    #if DEBUG
    private enum DebugLaunchArgument {
        static let reset = "--childlock-qa-reset"
        static let onboardingDevices = "--childlock-qa-seed-onboarding-devices"
        static let dashboard = "--childlock-qa-seed-dashboard"
        static let lockedDashboard = "--childlock-qa-seed-locked-dashboard"
        static let pendingChallenge = "--childlock-qa-seed-pending-challenge"
        static let pendingMathChallenge = "--childlock-qa-seed-pending-math-challenge"
        static let pendingMemoryChallenge = "--childlock-qa-seed-pending-memory-challenge"
        static let moreTimeRequest = "--childlock-qa-seed-more-time-request"
        static let childrenTab = "--childlock-qa-seed-children-tab"
        static let appsTab = "--childlock-qa-seed-apps-tab"
        static let settingsTab = "--childlock-qa-seed-settings-tab"
        static let addChildSheet = "--childlock-qa-seed-add-child-sheet"
        static let paywall = "--childlock-qa-seed-paywall"
    }

    private var debugForcedChallengeType: ChallengeType? {
        let arguments = Set(ProcessInfo.processInfo.arguments)
        if arguments.contains(DebugLaunchArgument.pendingMathChallenge) {
            return .math
        }

        if arguments.contains(DebugLaunchArgument.pendingMemoryChallenge) {
            return .memory
        }

        return nil
    }

    private func applyDebugLaunchSeedIfNeeded() {
        guard !didApplyDebugLaunchSeed else { return }
        didApplyDebugLaunchSeed = true

        let arguments = Set(ProcessInfo.processInfo.arguments)
        guard arguments.contains(DebugLaunchArgument.reset)
            || arguments.contains(DebugLaunchArgument.onboardingDevices)
            || arguments.contains(DebugLaunchArgument.dashboard)
            || arguments.contains(DebugLaunchArgument.lockedDashboard)
            || arguments.contains(DebugLaunchArgument.pendingChallenge)
            || arguments.contains(DebugLaunchArgument.pendingMathChallenge)
            || arguments.contains(DebugLaunchArgument.pendingMemoryChallenge)
            || arguments.contains(DebugLaunchArgument.moreTimeRequest)
            || arguments.contains(DebugLaunchArgument.childrenTab)
            || arguments.contains(DebugLaunchArgument.appsTab)
            || arguments.contains(DebugLaunchArgument.settingsTab)
            || arguments.contains(DebugLaunchArgument.addChildSheet)
            || arguments.contains(DebugLaunchArgument.paywall)
        else {
            return
        }

        resetDebugState()

        if arguments.contains(DebugLaunchArgument.onboardingDevices) {
            seedDebugOnboardingDevicesStep()
            return
        }

        if arguments.contains(DebugLaunchArgument.dashboard)
            || arguments.contains(DebugLaunchArgument.lockedDashboard)
            || arguments.contains(DebugLaunchArgument.pendingChallenge)
            || arguments.contains(DebugLaunchArgument.pendingMathChallenge)
            || arguments.contains(DebugLaunchArgument.pendingMemoryChallenge)
            || arguments.contains(DebugLaunchArgument.moreTimeRequest)
            || arguments.contains(DebugLaunchArgument.childrenTab)
            || arguments.contains(DebugLaunchArgument.appsTab)
            || arguments.contains(DebugLaunchArgument.settingsTab)
            || arguments.contains(DebugLaunchArgument.addChildSheet)
            || arguments.contains(DebugLaunchArgument.paywall) {
            seedDebugDashboard(
                locked: arguments.contains(DebugLaunchArgument.lockedDashboard),
                pendingChallenge: arguments.contains(DebugLaunchArgument.pendingChallenge)
                    || arguments.contains(DebugLaunchArgument.pendingMathChallenge)
                    || arguments.contains(DebugLaunchArgument.pendingMemoryChallenge),
                moreTimeRequest: arguments.contains(DebugLaunchArgument.moreTimeRequest),
                tab: arguments.contains(DebugLaunchArgument.addChildSheet) ? .children
                    : arguments.contains(DebugLaunchArgument.paywall) ? .settings
                    : arguments.contains(DebugLaunchArgument.childrenTab) ? .children
                    : arguments.contains(DebugLaunchArgument.appsTab) ? .apps
                    : arguments.contains(DebugLaunchArgument.settingsTab) ? .settings
                    : .home
            )
        }
    }

    private func resetDebugState() {
        appState.resetForTesting()
        authService.signOut()
        PINService.shared.clearPINForDebug()

        SharedDefaults.clearLocalSetupState()
    }

    private func seedDebugOnboardingDevicesStep() {
        authService.debugSignIn()
        appState.isAuthenticated = true
        onboardingViewModel.markSignupComplete()
        onboardingViewModel.familyAuthorizationState = .authorized
        onboardingViewModel.step = .devices
    }

    private func restoreDebugOnboardingDevicesSeedIfNeeded() {
        guard didApplyDebugLaunchSeed else { return }
        guard ProcessInfo.processInfo.arguments.contains(DebugLaunchArgument.onboardingDevices) else { return }

        seedDebugOnboardingDevicesStep()
    }

    private func seedDebugDashboard(
        locked: Bool,
        pendingChallenge: Bool,
        moreTimeRequest: Bool,
        tab: AppState.Tab = .home
    ) {
        let now = Date()
        var profile = ChildProfile(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
            name: "Mia",
            age: 7,
            avatarName: "fox",
            intervalMinutes: 5
        )
        profile.setMonitoredSelectionData(nil, displayNames: ["YouTube", "Games", "Safari"])

        _ = PINService.shared.setPIN("1234")
        authService.debugSignIn()
        appState.completeOnboarding(with: profile, pinConfigured: true)
        appState.isAuthenticated = true
        appState.currentTab = tab

        let firstResult = ChallengeResult(
            type: .math,
            difficultyLevel: 5,
            presentedAt: now.addingTimeInterval(-3_600),
            completedAt: now.addingTimeInterval(-3_570),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 30
        )
        let secondResult = ChallengeResult(
            type: .memory,
            difficultyLevel: 5,
            presentedAt: now.addingTimeInterval(-1_800),
            completedAt: now.addingTimeInterval(-1_760),
            attempts: 1,
            completed: true,
            hintUsed: false,
            solveTimeSeconds: 40
        )
        appState.sessions = [
            ChallengeSession(
                childProfileID: profile.id,
                date: Calendar.current.startOfDay(for: now),
                screenTimeSeconds: 600,
                synced: true,
                results: [firstResult, secondResult]
            )
        ]

        let defaults = SharedDefaults.shared
        defaults.set("running", forKey: SharedDefaults.Key.monitoringStatus)
        defaults.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeProfileID)
        defaults.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeMonitoringProfileID)
        defaults.set(now.timeIntervalSince1970, forKey: SharedDefaults.Key.monitoringLastStartedAt)

        if pendingChallenge {
            defaults.set(true, forKey: SharedDefaults.Key.challengePending)
            defaults.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)
        }

        if moreTimeRequest {
            defaults.set(1, forKey: SharedDefaults.Key.moreTimeRequestCount)
            defaults.set(now, forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
            defaults.set("more_time_requested", forKey: SharedDefaults.Key.monitoringStatus)
        }

        if locked {
            // The seed exists to render the parent gate deterministically in
            // simulator QA. Production locking still goes through PINService.
            appState.isPINLocked = true
            PINService.shared.lockSession()
        }
    }
    #endif
}
