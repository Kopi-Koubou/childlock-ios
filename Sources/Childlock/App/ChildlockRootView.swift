import SwiftUI

public struct ChildlockRootView: View {
    @State private var appState = AppState.shared
    @State private var onboardingViewModel = OnboardingViewModel()
    @State private var challengeViewModel = ChallengeViewModel()

    public init() {}

    private var challengeBinding: Binding<Bool> {
        Binding(
            get: { challengeViewModel.challenge != nil },
            set: { presented in
                if !presented {
                    challengeViewModel.clearChallenge()
                }
            }
        )
    }

    private var challengeOverlay: some View {
        ChallengeContainerView(viewModel: challengeViewModel)
            .interactiveDismissDisabled(true)
    }

    private var rootContent: some View {
        ZStack {
            ChildlockColor.background.ignoresSafeArea()

            if appState.hasCompletedOnboarding {
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
            // Sync auth state from AuthService
            switch AuthService.shared.state {
            case .signedIn:
                appState.isAuthenticated = true
            case .signedOut, .unknown:
                appState.isAuthenticated = false
            }

            challengeViewModel.onCompletedResult = { result in
                guard let profileID = appState.activeProfileID ?? appState.activeProfile?.id else {
                    return
                }
                appState.recordChallengeResult(result, for: profileID)
            }

            if SharedDefaults.shared.bool(forKey: SharedDefaults.Key.challengePending) {
                triggerPendingChallenge()
            }
        }
    }

    @ViewBuilder
    public var body: some View {
        #if os(iOS)
        rootContent
            .fullScreenCover(isPresented: challengeBinding) {
                challengeOverlay
            }
        #else
        rootContent
            .sheet(isPresented: challengeBinding) {
                challengeOverlay
            }
        #endif
    }

    private func completeOnboardingIfNeeded() {
        guard !appState.hasCompletedOnboarding else { return }
        guard let output = onboardingViewModel.buildOutput() else { return }

        let pinConfigured = PINService.shared.setPIN(output.parentPIN)
        appState.completeOnboarding(with: output.profile, pinConfigured: pinConfigured)
        onboardingViewModel.clearPersistedSelection()

        // Link RevenueCat user if signed in with Apple
        if let appleUserID = AuthService.shared.userID {
            appState.isAuthenticated = true
            Task {
                await SubscriptionService.shared.logIn(appUserID: appleUserID)
            }
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

    private func triggerPendingChallenge() {
        if
            let profileIDString = SharedDefaults.shared.string(forKey: SharedDefaults.Key.activeProfileID),
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
        challengeViewModel.presentChallenge(for: profile)
        appState.activeChallenge = challengeViewModel.challenge

        SharedDefaults.shared.set(true, forKey: SharedDefaults.Key.challengePending)
        SharedDefaults.shared.set(profile.id.uuidString, forKey: SharedDefaults.Key.activeProfileID)
    }
}
