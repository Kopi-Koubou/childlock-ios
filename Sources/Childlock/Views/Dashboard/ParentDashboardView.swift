import SwiftUI
#if os(iOS) && canImport(FamilyControls)
import FamilyControls
#endif
#if os(iOS) && canImport(UIKit)
import UIKit
#endif

public struct ParentDashboardView: View {
    @Bindable private var appState: AppState
    @State private var subscriptionService = SubscriptionService.shared
    @Environment(\.scenePhase) private var scenePhase

    private let onTriggerChallenge: (() -> Void)?
    private let pinService: PINService
    private let fallbackAppChoices = ["YouTube", "Netflix", "Games", "Social Video"]
    private let dashboardContentMaxWidth: CGFloat = 620
    private let dashboardScrollBottomPadding: CGFloat = 96
    private let parentLockContentMaxWidth: CGFloat = 420

    @State private var enteredPIN = ""
    @State private var pinErrorText: String?
    @State private var monitoringStatusText: String = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "not_started"
    @State private var monitoringErrorText: String?
    @State private var childrenWindow: AppState.ActivityWindow = .day
    @State private var isAddChildSheetPresented = false
    @State private var addChildDraft = AddChildDraft()
    @State private var addChildErrorText: String?
    @State private var fallbackAppSelection: Set<String> = []
    @State private var appsStatusText: String?
    @State private var appsErrorText: String?
    @State private var isSignOutConfirmationPresented = false
    @State private var isResetConfirmationPresented = false
    @State private var selectedTab: AppState.Tab = .home
    @State private var moreTimeRequestCount = SharedDefaults.shared.integer(forKey: SharedDefaults.Key.moreTimeRequestCount)
    @State private var notificationAuthorizationStatus: ChildlockNotificationAuthorizationStatus = .unavailable
    @State private var isRequestingNotificationPermission = false
    #if DEBUG
    @State private var didApplyDebugPresentationSeed = false
    @State private var isDebugPaywallPresented = false
    #endif
    #if os(iOS) && canImport(FamilyControls)
    @State private var isAppsFamilyActivityPickerPresented = false
    @State private var isRequestingAppsScreenTimeAccess = false
    @State private var isAppsScreenTimeSelectionAvailable = ScreenTimeManager.shared.isAuthorized
    @State private var appsFamilyActivitySelection = FamilyActivitySelection()
    #endif

    public init(
        appState: AppState,
        onTriggerChallenge: (() -> Void)? = nil,
        pinService: PINService? = nil
    ) {
        self.appState = appState
        self.onTriggerChallenge = onTriggerChallenge
        self.pinService = pinService ?? .shared
    }

    private var hasPremium: Bool {
        subscriptionService.currentTier == .premium
    }

    private var canAddChildProfile: Bool {
        appState.profiles.count < AppState.maxChildProfiles
    }

    public var body: some View {
        Group {
            if appState.isPINLocked {
                parentLockScreen
            } else {
                dashboardTabs
            }
        }
        .onAppear {
            refreshSharedDashboardState()
            refreshNotificationAuthorizationStatus()
            syncAppsSelectionStateFromActiveProfile()
            #if DEBUG
            applyDebugPresentationSeedIfNeeded()
            #endif
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            refreshSharedDashboardState()
            refreshNotificationAuthorizationStatus()
        }
        .onChange(of: appState.activeProfileID) { _, _ in
            syncAppsSelectionStateFromActiveProfile()
        }
        .onChange(of: enteredPIN) { _, _ in
            sanitizeEnteredPIN()
            if !enteredPIN.isEmpty {
                pinErrorText = nil
            }
        }
        #if DEBUG
        .sheet(isPresented: $isDebugPaywallPresented) {
            PaywallView {
                isDebugPaywallPresented = false
            }
        }
        #endif
    }

    #if DEBUG
    private func applyDebugPresentationSeedIfNeeded() {
        guard !didApplyDebugPresentationSeed else { return }
        didApplyDebugPresentationSeed = true

        let arguments = Set(ProcessInfo.processInfo.arguments)
        if arguments.contains("--childlock-qa-seed-add-child-sheet") {
            addChildDraft = AddChildDraft(
                name: "Leo",
                age: 6,
                avatarName: "sage",
                intervalMinutes: appState.activeProfile?.intervalMinutes ?? 15
            )
            addChildErrorText = nil
            isAddChildSheetPresented = true
        }

        if arguments.contains("--childlock-qa-seed-paywall") {
            isDebugPaywallPresented = true
        }
    }
    #endif

    private var dashboardTabs: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                switch appState.currentTab {
                case .home:
                    homeTab
                case .children:
                    childrenTab
                case .apps:
                    appsTab
                case .settings:
                    settingsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            customTabBar
        }
    }

    private var parentLockScreen: some View {
        VStack(spacing: ChildlockSpacing.lg) {
            Spacer()

            VStack(spacing: ChildlockSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ChildlockColor.primarySoft)
                        .frame(width: 96, height: 96)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(ChildlockColor.primary)
                }

                VStack(spacing: ChildlockSpacing.xs) {
                    Text("Parent dashboard locked")
                        .font(ChildlockTypography.title)
                        .foregroundStyle(ChildlockColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(parentLockSubtitle)
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: ChildlockSpacing.sm) {
                SecureField("Parent PIN", text: $enteredPIN)
                    .pinInputBehavior()
                    .font(ChildlockTypography.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ChildlockSpacing.sm)
                    .frame(height: 48)
                    .background(ChildlockColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))

                if let pinErrorText {
                    Text(pinErrorText)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.warning)
                }

                Button("Unlock Dashboard") {
                    unlockParentDashboard()
                }
                .buttonStyle(ChildlockPrimaryButtonStyle())
                .disabled(enteredPIN.count < 4)
                .opacity(enteredPIN.count < 4 ? 0.5 : 1)
            }
            .childlockCard()

            Text("When a monitored app pauses, the Childlock alert or Home opens the brain break.")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(ChildlockSpacing.lg)
        .frame(maxWidth: parentLockContentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background.ignoresSafeArea())
    }

    private var parentLockSubtitle: String {
        if moreTimeRequestCount > 0 {
            return "\(moreTimeRequestProfileName) asked for more time. Enter your PIN to respond."
        }

        return "Enter your PIN to manage children, apps, reports, and settings."
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(tab: .home, icon: "house", label: "Home")
            tabBarButton(tab: .children, icon: "person.2", label: "Children")
            tabBarButton(tab: .apps, icon: "square.grid.2x2", label: "Apps")
            tabBarButton(tab: .settings, icon: "gearshape", label: "Settings")
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(
            VStack(spacing: 0) {
                Rectangle()
                    .fill(ChildlockColor.surfaceMuted)
                    .frame(height: 1)
                ChildlockColor.surface
            }
        )
    }

    private func tabBarButton(tab: AppState.Tab, icon: String, label: String) -> some View {
        Button {
            appState.currentTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: appState.currentTab == tab ? "\(icon).fill" : icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: appState.currentTab == tab ? .semibold : .regular))
            }
            .foregroundStyle(appState.currentTab == tab ? ChildlockColor.primary : ChildlockColor.textMuted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func unlockParentDashboard() {
        let unlocked = appState.unlockSettings(with: enteredPIN, pinService: pinService)
        pinErrorText = unlocked ? nil : "Incorrect PIN. Try again."
        if unlocked {
            enteredPIN = ""
            refreshSharedDashboardState()
        } else {
            enteredPIN = ""
        }
    }

    private func sanitizeEnteredPIN() {
        let sanitized = String(enteredPIN.filter(\.isNumber).prefix(4))
        if enteredPIN != sanitized {
            enteredPIN = sanitized
        }
    }

    private func refreshSharedDashboardState() {
        monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "not_started"
        monitoringErrorText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringLastError)
        moreTimeRequestCount = SharedDefaults.shared.integer(forKey: SharedDefaults.Key.moreTimeRequestCount)
        #if os(iOS) && canImport(FamilyControls)
        isAppsScreenTimeSelectionAvailable = ScreenTimeManager.shared.isAuthorized
        #endif
    }

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    // Custom header
                    homeHeader

                    // Greeting
                    homeGreeting

                    if moreTimeRequestCount > 0 {
                        moreTimeRequestBanner
                    }

                    if !appState.profiles.isEmpty {
                        handoffLockCard
                    }

                    if let onTriggerChallenge {
                        Button("Practice Brain Break", action: onTriggerChallenge)
                            .buttonStyle(ChildlockPrimaryButtonStyle())
                            .accessibilityIdentifier("practice_brain_break")
                            .accessibilityLabel("Practice Brain Break")
                    }

                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No children yet",
                            subtitle: "Complete onboarding to start the challenge loop."
                        )
                    } else {
                        // Your children section
                        yourChildrenSection
                        recentActivityCard
                    }
                }
                .padding(ChildlockSpacing.lg)
                .padding(.bottom, dashboardScrollBottomPadding)
                .frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .alert(
                "Sign out of Childlock?",
                isPresented: $isSignOutConfirmationPresented,
            ) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Local enforcement pauses, and parent settings stay on this device. Sign in again with the same account to restart or manage Childlock.")
            }
        }
    }

    private var homeHeader: some View {
        HStack {
            Text("CHILDLOCK")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundStyle(ChildlockColor.textMuted)

            Spacer()

            Button {
                appState.currentTab = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(ChildlockColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(ChildlockColor.surface)
                    .clipShape(Circle())
                    .childlockShadow(ChildlockShadow.sm)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var homeGreeting: some View {
        let summary = appState.todaySummary
        let firstName = appState.profiles.first?.name

        return VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text(timeBasedGreeting)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(ChildlockColor.textPrimary)

            Text(greetingSubtitle(firstName: firstName, challengesCompleted: summary.challengesCompleted))
                .font(.system(size: 14))
                .foregroundStyle(ChildlockColor.textMuted)
        }
    }

    private var timeBasedGreeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private func greetingSubtitle(firstName: String?, challengesCompleted: Int) -> String {
        guard let firstName else {
            return "Add a child to start the brain break loop."
        }
        if challengesCompleted == 0 {
            return "No brain breaks yet today for \(firstName)."
        }
        return "\(firstName)'s been engaged today — \(challengesCompleted) brain break\(challengesCompleted == 1 ? "" : "s") solved."
    }

    private var handoffLockCard: some View {
        HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ChildlockColor.primary)
                .frame(width: 40, height: 40)
                .background(ChildlockColor.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.sm))

            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text("Ready to hand this device over?")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Tap Lock before handoff. If you leave Childlock, it locks automatically. Brain breaks still open; settings stay behind your PIN.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    appState.lockSettings(pinService: pinService)
                } label: {
                    Label("Lock Parent Dashboard", systemImage: "lock.fill")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, ChildlockSpacing.md)
                .padding(.vertical, 8)
                .background(Capsule().fill(ChildlockColor.primary))
                .buttonStyle(.plain)
                .accessibilityIdentifier("handoff_lock_parent_dashboard")
                .accessibilityLabel("Lock Parent Dashboard before handoff")
            }

            Spacer(minLength: 0)
        }
        .padding(ChildlockSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private var moreTimeRequestBanner: some View {
        let requestDate = SharedDefaults.shared.object(forKey: SharedDefaults.Key.lastMoreTimeRequestDate) as? Date

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            HStack(spacing: ChildlockSpacing.xs) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(ChildlockColor.accent)
                Text("\(moreTimeRequestProfileName) asked for more time")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ChildlockColor.textPrimary)
                Spacer()
                if let requestDate {
                    Text(relativeTimeText(from: requestDate))
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textMuted)
                }
            }

            HStack(spacing: ChildlockSpacing.sm) {
                Button("Give one more block") {
                    grantMoreTime()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, ChildlockSpacing.md)
                .padding(.vertical, 8)
                .background(Capsule().fill(ChildlockColor.primary))
                .buttonStyle(.plain)

                Button("Keep blocked") {
                    denyMoreTimeRequest()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ChildlockColor.textSecondary)
                .buttonStyle(.plain)
            }
        }
        .padding(ChildlockSpacing.md)
        .background(ChildlockColor.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
    }

    private func grantMoreTime() {
        refreshSharedDashboardState()
        guard let profile = monitoringProfile else {
            monitoringStatusText = "failed"
            monitoringErrorText = "No monitored child profile available."
            return
        }

        guard ChildlockMonitoringStatus(storedValue: monitoringStatusText)?.canRearmMonitoring == true else {
            monitoringErrorText = "Monitoring is not ready to grant more time. Restart lock enforcement from Settings."
            return
        }

        // Restarting monitoring resets the usage threshold, so the child gets
        // one full interval before the next brain break.
        do {
            try ScreenTimeManager.shared.startMonitoring(profile: profile)
            ScreenTimeManager.shared.removeShields()
            clearMoreTimeRequests()
            refreshSharedDashboardState()
            monitoringErrorText = nil
        } catch {
            refreshSharedDashboardState()
            monitoringErrorText = error.localizedDescription
        }
    }

    private func clearMoreTimeRequests() {
        SharedDefaults.shared.set(false, forKey: SharedDefaults.Key.challengePending)
        SharedDefaults.shared.set(0, forKey: SharedDefaults.Key.moreTimeRequestCount)
        SharedDefaults.shared.removeObject(forKey: SharedDefaults.Key.lastMoreTimeRequestDate)
        NotificationService.clearMoreTimeRequestAlerts()
        moreTimeRequestCount = 0
    }

    private func denyMoreTimeRequest() {
        clearMoreTimeRequests()
        SharedDefaults.shared.set("threshold_reached", forKey: SharedDefaults.Key.monitoringStatus)
        monitoringStatusText = "threshold_reached"
        monitoringErrorText = nil
    }

    private var yourChildrenSection: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("YOUR CHILDREN")
                .font(ChildlockTypography.label)
                .foregroundStyle(ChildlockColor.textMuted)

            ForEach(appState.profiles) { profile in
                childProfileCard(profile: profile)
            }

            // Add a child button
            Button {
                presentAddChildSheetIfPossible()
            } label: {
                HStack {
                    Image(systemName: canAddChildProfile ? "plus" : "person.crop.circle.badge.checkmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text(canAddChildProfile ? "Add a child" : "Child limit reached")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(ChildlockColor.textMuted)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: ChildlockRadius.card)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .foregroundStyle(ChildlockColor.surfaceMuted)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAddChildProfile)
            .opacity(canAddChildProfile ? 1 : 0.65)
        }
        .sheet(isPresented: $isAddChildSheetPresented) {
            addChildSheet
        }
    }

    private func childProfileCard(profile: ChildProfile) -> some View {
        let summary = appState.summary(window: .day, profileID: profile.id)
        let avatarColorIndex = appState.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0
        let avatarColor = ChildlockAvatarColor.all[avatarColorIndex % ChildlockAvatarColor.all.count]
        let isActive = appState.activeProfile?.id == profile.id

        return HStack(spacing: ChildlockSpacing.sm) {
            // Avatar circle
            Text(String(profile.name.prefix(1)).uppercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(avatarColor)
                .clipShape(Circle())

            // Name + status
            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                HStack(spacing: 4) {
                    Text(profile.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ChildlockColor.textPrimary)
                    Text("· age \(profile.age)")
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textMuted)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(isActive ? ChildlockColor.accent : ChildlockColor.textFaint)
                        .frame(width: 6, height: 6)
                    Text(isActive ? "Active" : "Idle")
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textMuted)
                }
            }

            Spacer()

            // Challenge count
            VStack(alignment: .trailing, spacing: 0) {
                Text("\(summary.challengesCompleted)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ChildlockColor.textPrimary)
                Text("TODAY")
                    .font(ChildlockTypography.label)
                    .foregroundStyle(ChildlockColor.textMuted)
            }
        }
        .padding(ChildlockSpacing.md)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private var recentActivityCard: some View {
        let activity = appState.recentActivity(limit: hasPremium ? 12 : 4)

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            HStack {
                Text("RECENT ACTIVITY")
                    .font(ChildlockTypography.label)
                    .foregroundStyle(ChildlockColor.textMuted)
                Spacer()
                if hasPremium {
                    Text("EXTENDED")
                        .font(ChildlockTypography.label)
                        .foregroundStyle(ChildlockColor.primary)
                }
            }

            VStack(spacing: 0) {
                if activity.isEmpty {
                    Text("Challenges will appear here once your child starts using monitored apps.")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .padding(ChildlockSpacing.md)
                } else {
                    ForEach(Array(activity.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 0) {
                            HStack(alignment: .center, spacing: ChildlockSpacing.sm) {
                                Circle()
                                    .fill(item.result.completed ? ChildlockColor.primary : ChildlockColor.warning)
                                    .frame(width: 6, height: 6)

                                HStack(spacing: 4) {
                                    Text(item.profileName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(ChildlockColor.textPrimary)
                                    Text("· \(item.result.type.rawValue.capitalized)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ChildlockColor.textMuted)
                                }

                                Spacer()

                                let timeText = relativeTimeText(from: item.result.presentedAt)
                                Text(timeText)
                                    .font(.system(size: 12))
                                    .foregroundStyle(ChildlockColor.textMuted)
                            }

                            if let solveTime = item.result.solveTimeSeconds {
                                HStack {
                                    Text("Solved in \(Int(solveTime))s · \(item.result.attempts) attempt\(item.result.attempts == 1 ? "" : "s")")
                                        .font(.system(size: 12))
                                        .foregroundStyle(ChildlockColor.textMuted)
                                    Spacer()
                                }
                                .padding(.leading, 18)
                            }

                            if index < activity.count - 1 {
                                Divider()
                                    .background(ChildlockColor.surfaceMuted)
                                    .padding(.vertical, ChildlockSpacing.xs)
                            }
                        }
                        .padding(.vertical, ChildlockSpacing.xxs)
                    }
                }
            }
            .padding(ChildlockSpacing.md)
            .background(ChildlockColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            .childlockShadow(ChildlockShadow.sm)
        }
    }

    // MARK: - Children Tab

    private var childrenTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                            Text("MANAGE")
                                .font(ChildlockTypography.label)
                                .foregroundStyle(ChildlockColor.textMuted)
                            Text("Children")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(ChildlockColor.textPrimary)
                        }
                        Spacer()
                        Button {
                            presentAddChildSheetIfPossible()
                        } label: {
                            Text(canAddChildProfile ? "+ Add child" : "5 children")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(canAddChildProfile ? ChildlockColor.primaryDeep : ChildlockColor.textMuted)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canAddChildProfile)
                    }

                    Text("Each child has their own age band, interval, apps, and active handoff state.")
                        .font(.system(size: 14))
                        .foregroundStyle(ChildlockColor.textMuted)

                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child to start personalized challenge tracking."
                        )
                    } else {
                        childrenReportControls

                        ForEach(appState.profiles) { profile in
                            childrenTabProfileCard(profile: profile)
                        }
                    }

                    // Child profile info card
                    HStack(spacing: ChildlockSpacing.sm) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ChildlockColor.primaryDeep)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Supports up to 5 children")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ChildlockColor.primaryDeep)
                            Text("Choose the active child before handing over a shared device.")
                                .font(.system(size: 12))
                                .foregroundStyle(ChildlockColor.textMuted)
                        }
                        Spacer()
                    }
                    .padding(ChildlockSpacing.md)
                    .background(ChildlockColor.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
                }
                .padding(ChildlockSpacing.lg)
                .padding(.bottom, dashboardScrollBottomPadding)
                .frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .sheet(isPresented: $isAddChildSheetPresented) {
                addChildSheet
            }
        }
    }

    private func childrenTabProfileCard(profile: ChildProfile) -> some View {
        let reportWindow: AppState.ActivityWindow = hasPremium ? childrenWindow : .day
        let summary = appState.summary(window: reportWindow, profileID: profile.id)
        let avatarColorIndex = appState.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0
        let avatarColor = ChildlockAvatarColor.all[avatarColorIndex % ChildlockAvatarColor.all.count]
        let isActive = appState.activeProfile?.id == profile.id

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            HStack(spacing: ChildlockSpacing.sm) {
                // Avatar
                Text(String(profile.name.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(avatarColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(profile.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ChildlockColor.textPrimary)
                        Text("· age \(profile.age)")
                            .font(.system(size: 12))
                            .foregroundStyle(ChildlockColor.textMuted)
                    }
                    Text("every \(profile.intervalMinutes)min · \(summary.challengesCompleted) solved \(reportWindow.summarySuffix)")
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textMuted)
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(ChildlockTypography.label)
                        .foregroundStyle(ChildlockColor.primaryDeep)
                        .padding(.horizontal, ChildlockSpacing.xs)
                        .padding(.vertical, 6)
                        .background(ChildlockColor.primarySoft)
                        .clipShape(Capsule())
                } else {
                    Button {
                        makeProfileActive(profile)
                    } label: {
                        Text("Make active")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(ChildlockColor.primaryDeep)
                    .padding(.horizontal, ChildlockSpacing.xs)
                    .padding(.vertical, 7)
                    .background(ChildlockColor.surfaceMuted.opacity(0.7))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("make_active_child_\(profile.id.uuidString)")
                    .accessibilityLabel("Make \(profile.name) active on this device")
                }
            }

            if !profile.monitoredAppDisplayNames.isEmpty {
                HStack(spacing: 4) {
                    Circle()
                        .fill(ChildlockColor.primary)
                        .frame(width: 6, height: 6)
                    Text(monitoredSummaryText(for: profile))
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textSecondary)
                }
                .padding(.horizontal, ChildlockSpacing.sm)
                .padding(.vertical, 6)
                .background(ChildlockColor.surfaceMuted.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.pill))
            }
        }
        .padding(ChildlockSpacing.md)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private func makeProfileActive(_ profile: ChildProfile) {
        appState.setActiveProfile(id: profile.id)
        syncAppsSelectionStateFromActiveProfile()
        refreshMonitoringIfRunning(for: profile)
    }

    @ViewBuilder
    private var childrenReportControls: some View {
        if hasPremium {
            Picker("Report window", selection: $childrenWindow) {
                ForEach(AppState.ActivityWindow.allCases) { window in
                    Text(window.title).tag(window)
                }
            }
            .pickerStyle(.segmented)
        } else {
            NavigationLink {
                PaywallNavigationDestination()
            } label: {
                HStack(spacing: ChildlockSpacing.sm) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ChildlockColor.primaryDeep)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's report is included")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ChildlockColor.primaryDeep)
                        Text("Upgrade for week and all-time child reports.")
                            .font(.system(size: 12))
                            .foregroundStyle(ChildlockColor.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ChildlockColor.primaryDeep)
                }
                .padding(ChildlockSpacing.md)
                .background(ChildlockColor.primarySoft)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            }
            .buttonStyle(.plain)
        }
    }

    private func monitoredSummaryText(for profile: ChildProfile) -> String {
        let count = profile.monitoredAppDisplayNames.count
        if profile.monitoredSelectionTokenData == nil {
            return "\(count) planning label\(count == 1 ? "" : "s")"
        }

        return "\(count) monitored selection\(count == 1 ? "" : "s")"
    }

    // MARK: - Apps Tab

    private var appsTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    // Header
                    Text("MANAGE")
                        .font(ChildlockTypography.label)
                        .foregroundStyle(ChildlockColor.textMuted)
                    Text("Apps")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ChildlockColor.textPrimary)
                    Text(appsTabSubtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(ChildlockColor.textMuted)

                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child profile first, then assign monitored apps."
                        )
                    } else {
                        // Monitored section
                        Text(appsSelectionSectionTitle)
                            .font(ChildlockTypography.label)
                            .foregroundStyle(ChildlockColor.textMuted)

                        appsMonitoredCard

                        // App assignment
                        appsAssignmentCard

                        // Always Allowed section
                        Text("ALWAYS ALLOWED")
                            .font(ChildlockTypography.label)
                            .foregroundStyle(ChildlockColor.textMuted)

                        alwaysAllowedCard
                    }
                }
                .padding(ChildlockSpacing.lg)
                .padding(.bottom, dashboardScrollBottomPadding)
                .frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
        }
    }

    @ViewBuilder
    private var appsMonitoredCard: some View {
        if let activeProfile = appState.activeProfile {
            let appNames = activeProfile.monitoredAppDisplayNames

            VStack(spacing: 0) {
                if appNames.isEmpty {
                    HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(ChildlockColor.primary)
                            .frame(width: 40, height: 40)
                            .background(ChildlockColor.primarySoft)
                            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.sm))

                        VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                            Text("No monitored apps selected")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ChildlockColor.textPrimary)
                            Text("Choose real apps, categories, or websites on this device before starting lock enforcement.")
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(ChildlockSpacing.md)
                } else {
                    ForEach(Array(appNames.enumerated()), id: \.element) { index, appName in
                        HStack(spacing: ChildlockSpacing.sm) {
                            monitoredSelectionIcon(for: appName, index: index)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(ChildlockColor.textPrimary)
                                Text(monitoredSelectionDetailText(for: activeProfile))
                                    .font(.system(size: 12))
                                    .foregroundStyle(ChildlockColor.textMuted)
                            }
                            .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            Image(systemName: activeProfile.monitoredSelectionTokenData == nil ? "pencil.and.list.clipboard" : "lock.shield.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(activeProfile.monitoredSelectionTokenData == nil ? ChildlockColor.textFaint : ChildlockColor.primary)
                        }
                        .padding(.horizontal, ChildlockSpacing.md)
                        .padding(.vertical, ChildlockSpacing.sm)

                        if index < appNames.count - 1 {
                            Divider()
                                .background(ChildlockColor.surfaceMuted)
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background(ChildlockColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            .childlockShadow(ChildlockShadow.sm)
        }
    }

    private func monitoredSelectionIcon(for label: String, index: Int) -> some View {
        RoundedRectangle(cornerRadius: ChildlockRadius.sm)
            .fill(appIconColor(for: index))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: monitoredSelectionIconName(for: label))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            )
    }

    private func monitoredSelectionIconName(for label: String) -> String {
        let lowercased = label.lowercased()

        if lowercased.contains("categor") {
            return "square.grid.2x2.fill"
        }

        if lowercased.contains("website") || lowercased.contains("domain") || lowercased.contains("safari") {
            return "globe"
        }

        if lowercased.contains("game") {
            return "gamecontroller.fill"
        }

        if lowercased.contains("video") || lowercased.contains("youtube") || lowercased.contains("netflix") {
            return "play.rectangle.fill"
        }

        return "app.badge.fill"
    }

    private var appsSelectionSectionTitle: String {
        guard let activeProfile = appState.activeProfile else {
            return "MONITORED"
        }

        if !activeProfile.monitoredAppDisplayNames.isEmpty,
           activeProfile.monitoredSelectionTokenData == nil {
            return "PLANNING LABELS"
        }

        return "MONITORED"
    }

    private var appsTabSubtitle: String {
        guard appState.activeProfile != nil else {
            return "Add a child, then choose what this device should protect."
        }

        if hasActiveScreenTimeSelection {
            return "Brain breaks appear during these."
        }

        return "Choose real Screen Time items before testing enforcement."
    }

    private var appsAssignmentIntroText: String {
        if hasActiveScreenTimeSelection {
            return "Screen Time selection protects real apps, categories, or websites on this device."
        }

        return "Planning labels help setup, but they do not lock content. Enable Screen Time selection to choose real apps, categories, or websites."
    }

    private func monitoredSelectionDetailText(for profile: ChildProfile) -> String {
        if profile.monitoredSelectionTokenData == nil {
            return "Planning label only. Not locking content yet."
        }

        return "Brain break every \(profile.intervalMinutes)m on this device"
    }

    private func appIconColor(for index: Int) -> Color {
        let colors: [Color] = [ChildlockColor.primary, ChildlockColor.accent, ChildlockColor.memory]
        return colors[index % colors.count]
    }

    @ViewBuilder
    private var appsAssignmentCard: some View {
        if appState.activeProfile != nil {
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text(appsAssignmentIntroText)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                #if os(iOS) && canImport(FamilyControls)
                if shouldUseAppsFamilyActivityPicker {
                    Button {
                        isAppsFamilyActivityPickerPresented = true
                    } label: {
                        Label("Choose apps, categories, or websites", systemImage: "checklist")
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .familyActivityPicker(
                        isPresented: $isAppsFamilyActivityPickerPresented,
                        selection: $appsFamilyActivitySelection
                    )
                    .onChange(of: appsFamilyActivitySelection) { _, selection in
                        let displayNames = selectionSummaryLabels(for: selection)
                        let tokenData = displayNames.isEmpty ? nil : try? JSONEncoder().encode(selection)
                        updateActiveProfileMonitoredSelection(
                            tokenData: tokenData,
                            displayNames: displayNames
                        )
                    }
                } else {
                    Button {
                        Task { await requestAppsScreenTimeAccess() }
                    } label: {
                        Label(
                            isRequestingAppsScreenTimeAccess ? "Requesting Screen Time..." : "Enable Screen Time selection",
                            systemImage: "lock.shield"
                        )
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .disabled(isRequestingAppsScreenTimeAccess)
                    .opacity(isRequestingAppsScreenTimeAccess ? 0.65 : 1.0)

                    fallbackAppsAssignmentChoices
                }
                #else
                fallbackAppsAssignmentChoices
                #endif

                if let appsStatusText {
                    Text(appsStatusText)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.success)
                }

                if let appsErrorText {
                    Text(appsErrorText)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.warning)
                }

                Button("Copy to all children") {
                    applyActiveSelectionToAllChildren()
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
                .disabled(!canCopyActiveScreenTimeSelection)
                .opacity(canCopyActiveScreenTimeSelection ? 1.0 : 0.5)

                Text("Use this for siblings who share this device. For a separate child iPad, install and configure Childlock on that iPad too.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var fallbackAppsAssignmentChoices: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text("Use labels for planning. Enable Screen Time selection here before locking real apps on this device.")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textMuted)

            ForEach(fallbackAppChoices, id: \.self) { appName in
                Button {
                    toggleFallbackSelection(appName)
                } label: {
                    HStack {
                        Text(appName)
                            .font(ChildlockTypography.body)
                            .foregroundStyle(ChildlockColor.textPrimary)
                        Spacer()
                        Image(systemName: fallbackAppSelection.contains(appName) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(fallbackAppSelection.contains(appName) ? ChildlockColor.accent : ChildlockColor.textFaint)
                    }
                    .padding(.horizontal, ChildlockSpacing.md)
                    .frame(height: 44)
                    .background(ChildlockColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.md))
                    .childlockShadow(ChildlockShadow.sm)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("assign_monitored_\(appName)")
                .accessibilityLabel(
                    fallbackAppSelection.contains(appName)
                        ? "Remove \(appName) from monitored apps"
                        : "Add \(appName) to monitored apps"
                )
            }
        }
    }

    private var shouldUseAppsFamilyActivityPicker: Bool {
        #if os(iOS) && canImport(FamilyControls)
        return isAppsScreenTimeSelectionAvailable || appState.activeProfile?.monitoredSelectionTokenData != nil
        #else
        return false
        #endif
    }

    private var alwaysAllowedCard: some View {
        HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 18))
                .foregroundStyle(ChildlockColor.primary)

            Text("Only the apps, categories, or websites you choose are targeted. Keep calls, messages, and school apps out of the selection when they should stay available.")
                .font(.system(size: 14))
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .padding(ChildlockSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    // Header
                    Text("MANAGE")
                        .font(ChildlockTypography.label)
                        .foregroundStyle(ChildlockColor.textMuted)
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ChildlockColor.textPrimary)

                    if appState.isPINLocked {
                        // PIN Lock section
                        settingsSection(title: "PARENT PIN") {
                            VStack(spacing: ChildlockSpacing.sm) {
                                SecureField("Enter PIN", text: $enteredPIN)
                                    .pinInputBehavior()
                                    .font(ChildlockTypography.body)
                                    .padding(.horizontal, ChildlockSpacing.sm)
                                    .frame(height: 44)
                                    .background(ChildlockColor.surfaceMuted.opacity(0.3))
                                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.sm))

                                Button("Unlock Parent Dashboard") {
                                    unlockParentDashboard()
                                }
                                .buttonStyle(ChildlockPrimaryButtonStyle())

                                if let pinErrorText {
                                    Text(pinErrorText)
                                        .font(ChildlockTypography.caption)
                                        .foregroundStyle(ChildlockColor.warning)
                                }
                            }
                            .padding(ChildlockSpacing.md)
                        }
                    } else {
                        // Account section
                        settingsSection(title: "ACCOUNT") {
                            VStack(spacing: 0) {
                                settingsRow(
                                    title: "Account sync",
                                    value: appState.isAuthenticated ? "On" : "Off",
                                    showChevron: false
                                )

                                Divider().background(ChildlockColor.surfaceMuted)

                                NavigationLink {
                                    PaywallNavigationDestination()
                                } label: {
                                    settingsRowContent(
                                        title: "Childlock Premium",
                                        value: hasPremium ? "Active" : "Upgrade",
                                        showChevron: true,
                                        isUpgrade: !hasPremium
                                    )
                                }
                                .buttonStyle(.plain)

                                Divider().background(ChildlockColor.surfaceMuted)

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isSignOutConfirmationPresented = true
                                    }
                                } label: {
                                    settingsRowContent(
                                        title: "Sign Out",
                                        value: "",
                                        showChevron: false,
                                        isDestructive: true
                                    )
                                }
                                .buttonStyle(.plain)

                                if isSignOutConfirmationPresented {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                                        Text("Local enforcement pauses. Parent settings stay on this device for this account. Signing in with a different account starts fresh setup.")
                                            .font(ChildlockTypography.caption)
                                            .foregroundStyle(ChildlockColor.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        HStack(spacing: ChildlockSpacing.sm) {
                                            Button("Cancel") {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isSignOutConfirmationPresented = false
                                                }
                                            }
                                            .buttonStyle(ChildlockSecondaryButtonStyle())

                                            Button("Confirm Sign Out") {
                                                signOut()
                                            }
                                            .buttonStyle(ChildlockPrimaryButtonStyle())
                                        }
                                    }
                                    .padding(ChildlockSpacing.md)
                                }
                            }
                        }

                        // Reset section
                        settingsSection(title: "RESET") {
                            VStack(spacing: 0) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isResetConfirmationPresented = true
                                    }
                                } label: {
                                    settingsRowContent(
                                        title: "Reset Childlock on this device",
                                        value: "",
                                        showChevron: false,
                                        isDestructive: true
                                    )
                                }
                                .buttonStyle(.plain)

                                if isResetConfirmationPresented {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                                        Text("This stops local enforcement, clears child profiles, app selections, reports, and the parent PIN on this device. Use it before rerunning setup or switching this iPhone or iPad to another child.")
                                            .font(ChildlockTypography.caption)
                                            .foregroundStyle(ChildlockColor.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        HStack(spacing: ChildlockSpacing.sm) {
                                            Button("Cancel") {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    isResetConfirmationPresented = false
                                                }
                                            }
                                            .buttonStyle(ChildlockSecondaryButtonStyle())

                                            Button("Confirm Reset") {
                                                resetLocalSetup()
                                            }
                                            .buttonStyle(ChildlockPrimaryButtonStyle())
                                        }
                                    }
                                    .padding(ChildlockSpacing.md)
                                }
                            }
                        }

                        // Challenges section
                        settingsSection(title: "CHALLENGES") {
                            VStack(spacing: 0) {
                                settingsToggleRow(title: "Voice prompts (ages 3-5)", binding: voicePromptBinding)
                            }
                        }

                        // Security section
                        settingsSection(title: "SECURITY") {
                            VStack(spacing: 0) {
                                settingsRow(title: "Screen Time Enforcement", value: monitoringStatusLabel, showChevron: false)

                                Text("Locks this device only. Child iPad setup happens on the iPad.")
                                    .font(ChildlockTypography.caption)
                                    .foregroundStyle(ChildlockColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, ChildlockSpacing.md)
                                    .padding(.bottom, ChildlockSpacing.sm)

                                screenTimeEnforcementGuidance

                                if let monitoringErrorText {
                                    Text(monitoringErrorText)
                                        .font(ChildlockTypography.caption)
                                        .foregroundStyle(ChildlockColor.warning)
                                        .padding(.horizontal, ChildlockSpacing.md)
                                        .padding(.bottom, ChildlockSpacing.sm)
                                }

                                if shouldShowStartLockEnforcementAction {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    Button {
                                        Task { await startScreenTimeEnforcement() }
                                    } label: {
                                        settingsRowContent(title: "Start Screen Time Enforcement", value: "", showChevron: true)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canStartScreenTimeEnforcement)
                                    .opacity(canStartScreenTimeEnforcement ? 1 : 0.45)
                                }

                                if shouldShowStopLockEnforcementAction {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    Button {
                                        stopScreenTimeEnforcement()
                                    } label: {
                                        settingsRowContent(title: "Stop Screen Time Enforcement", value: "", showChevron: true)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(monitoringProfile == nil)
                                }

                                if shouldShowStopLockEnforcementAction {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    Button {
                                        appState.lockSettings(pinService: pinService)
                                    } label: {
                                        settingsRowContent(title: "Lock Parent Dashboard", value: "", showChevron: true)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Notifications section
                        settingsSection(title: "NOTIFICATIONS") {
                            VStack(spacing: 0) {
                                settingsToggleRow(title: "Daily summary", binding: dailySummaryBinding)
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsToggleRow(title: "Challenge alerts", binding: challengeAlertBinding)
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsRow(
                                    title: "iOS notification permission",
                                    value: notificationAuthorizationLabel,
                                    showChevron: false
                                )

                                notificationSettingsFootnote

                                if !notificationAuthorizationStatus.allowsDelivery {
                                    Divider().background(ChildlockColor.surfaceMuted)

                                    Button {
                                        Task { await requestNotificationPermissionOrOpenSettings() }
                                    } label: {
                                        settingsRowContent(
                                            title: notificationPermissionActionTitle,
                                            value: isRequestingNotificationPermission ? "Waiting..." : "",
                                            showChevron: notificationAuthorizationStatus == .denied
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isRequestingNotificationPermission)
                                }
                            }
                        }

                        // Support section
                        settingsSection(title: "SUPPORT") {
                            VStack(spacing: 0) {
                                settingsLinkRow(title: "Help Center", urlString: "https://kouboulabs.com/childlock/support")
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsLinkRow(title: "Privacy Policy", urlString: "https://kouboulabs.com/childlock/privacy")
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsLinkRow(title: "Terms of Service", urlString: "https://kouboulabs.com/childlock/terms")
                            }
                        }
                    }
                }
                .padding(ChildlockSpacing.lg)
                .padding(.bottom, dashboardScrollBottomPadding)
                .frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
        }
    }

    private var screenTimeEnforcementGuidance: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            ForEach(Array(screenTimeEnforcementGuidanceSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: ChildlockSpacing.xs) {
                    Text("\(index + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(ChildlockColor.primary)
                        .clipShape(Circle())
                        .padding(.top, 1)

                    Text(step)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ChildlockSpacing.md)
        .padding(.bottom, ChildlockSpacing.sm)
    }

    private var screenTimeEnforcementGuidanceSteps: [String] {
        guard appState.activeProfile != nil else {
            return ["Add a child profile before starting a TestFlight shield-loop test."]
        }

        if appState.activeProfile?.monitoredSelectionTokenData == nil {
            return [
                "Choose real apps in Apps.",
                "Planning labels don't lock.",
                "Start, then lock dashboard.",
                "Child iPad: repeat setup there.",
            ]
        }

        switch monitoringStatus {
        case .running, .intervalStarted:
            return [
                "Lock the parent dashboard or leave Childlock to auto-lock.",
                "Hand this device over and start selected content until Brain Break appears.",
                "For a child iPad, run these steps on the iPad.",
            ]
        case .thresholdReached, .challengeRequested:
            return [
                "Brain Break is pending.",
                "Open Childlock from Home or the notification.",
                "Complete the challenge, then confirm monitoring re-arms.",
            ]
        case .moreTimeRequested:
            return [
                "\(moreTimeRequestProfileName) asked for more time.",
                "Enter the parent PIN and respond.",
                "Confirm enforcement re-arms for another full interval.",
            ]
        case .failed, .denied:
            return ["Fix Screen Time access or the app selection before handing the device over."]
        case .notStarted, .intervalEnded, .stopped, .none:
            return [
                "Choose the shortest interval for TestFlight.",
                "Start enforcement.",
                "Lock the parent dashboard or leave Childlock to auto-lock, then hand this device over.",
            ]
        }
    }

    private var hasActiveScreenTimeSelection: Bool {
        guard let activeProfile = appState.activeProfile else {
            return false
        }

        return activeProfile.monitoredSelectionTokenData != nil
            && !activeProfile.monitoredAppDisplayNames.isEmpty
    }

    private var canStartScreenTimeEnforcement: Bool {
        appState.activeProfile != nil && hasActiveScreenTimeSelection
    }

    private var canCopyActiveScreenTimeSelection: Bool {
        appState.profiles.count >= 2 && hasActiveScreenTimeSelection
    }

    private var monitoringProfile: ChildProfile? {
        if
            let profileIDString = SharedDefaults.shared.string(forKey: SharedDefaults.Key.activeMonitoringProfileID),
            let profileID = UUID(uuidString: profileIDString),
            let profile = appState.profiles.first(where: { $0.id == profileID })
        {
            return profile
        }

        return appState.activeProfile
    }

    private var moreTimeRequestProfileName: String {
        monitoringProfile?.name ?? "Your child"
    }

    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text(title)
                .font(ChildlockTypography.label)
                .foregroundStyle(ChildlockColor.textMuted)

            content()
                .background(ChildlockColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
                .childlockShadow(ChildlockShadow.sm)
        }
    }

    private func settingsRow(title: String, value: String, showChevron: Bool, isUpgrade: Bool = false) -> some View {
        settingsRowContent(title: title, value: value, showChevron: showChevron, isUpgrade: isUpgrade)
    }

    @ViewBuilder
    private func settingsLinkRow(title: String, urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                settingsRowContent(title: title, value: "", showChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            settingsRowContent(title: title, value: "", showChevron: true)
        }
    }

    private func settingsRowContent(
        title: String,
        value: String,
        showChevron: Bool,
        isUpgrade: Bool = false,
        isDestructive: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(rowTextColor(isUpgrade: isUpgrade, isDestructive: isDestructive))
            Spacer()
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundStyle(isUpgrade ? ChildlockColor.primaryDeep : ChildlockColor.textMuted)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ChildlockColor.textFaint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ChildlockSpacing.md)
        .padding(.vertical, ChildlockSpacing.sm)
        .contentShape(Rectangle())
    }

    private func rowTextColor(isUpgrade: Bool, isDestructive: Bool) -> Color {
        if isDestructive {
            return ChildlockColor.accent
        }

        if isUpgrade {
            return ChildlockColor.primaryDeep
        }

        return ChildlockColor.textPrimary
    }

    private func signOut() {
        let profilesToStop = appState.profiles
        profilesToStop.forEach { ScreenTimeManager.shared.stopMonitoring(profile: $0) }
        ScreenTimeManager.shared.removeShields()
        NotificationService.clearShieldFlowAlerts()
        AuthService.shared.signOut()
        appState.isAuthenticated = false
        appState.lockSettings(pinService: pinService)
        appState.currentTab = .home
        monitoringStatusText = "stopped"
        monitoringErrorText = nil
        moreTimeRequestCount = 0
        isSignOutConfirmationPresented = false
    }

    private func resetLocalSetup() {
        let profilesToStop = appState.profiles
        profilesToStop.forEach { ScreenTimeManager.shared.stopMonitoring(profile: $0) }
        ScreenTimeManager.shared.removeShields()
        NotificationService.cancelAll()
        SharedDefaults.clearLocalSetupState()
        pinService.clearPIN()
        AuthService.shared.signOut()

        appState.resetForFreshSetup()
        appState.currentTab = .home
        appState.isAuthenticated = false
        isResetConfirmationPresented = false
        isSignOutConfirmationPresented = false
        enteredPIN = ""
        pinErrorText = nil
        monitoringStatusText = "not_started"
        monitoringErrorText = nil
        moreTimeRequestCount = 0
        appsStatusText = nil
        appsErrorText = nil
        fallbackAppSelection = []
    }

    private func settingsToggleRow(title: String, binding: Binding<Bool>) -> some View {
        HStack(spacing: ChildlockSpacing.md) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(ChildlockColor.textPrimary)

            Spacer()

            Toggle(title, isOn: binding)
                .labelsHidden()
                .tint(ChildlockColor.primary)
                .accessibilityLabel(title)
                .accessibilityValue(binding.wrappedValue ? "On" : "Off")
        }
        .padding(.horizontal, ChildlockSpacing.md)
        .padding(.vertical, ChildlockSpacing.sm)
    }

    private var notificationSettingsFootnote: some View {
        Text(notificationGuidanceText)
            .font(ChildlockTypography.caption)
            .foregroundStyle(ChildlockColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ChildlockSpacing.md)
            .padding(.bottom, ChildlockSpacing.sm)
    }

    // MARK: - Add Child Sheet

    private var addChildSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.lg) {
                    // Title & subtitle
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Who else uses screens at home?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(ChildlockColor.textPrimary)

                        let firstChildName = appState.profiles.first?.name ?? "your first child"
                        Text("Each child gets their own age-tuned challenges. Settings copy from \(firstChildName) by default, and you can tweak them per child.")
                            .font(.system(size: 14))
                            .foregroundStyle(ChildlockColor.textMuted)
                    }

                    // Name field
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Name")
                            .font(ChildlockTypography.label)
                            .foregroundStyle(ChildlockColor.textMuted)

                        TextField("E.g. Leo", text: $addChildDraft.name)
                            .font(ChildlockTypography.body)
                            .padding(.horizontal, ChildlockSpacing.md)
                            .frame(height: 48)
                            .background(ChildlockColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.md))
                            .childlockShadow(ChildlockShadow.sm)
                    }

                    // Age selector
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Age")
                            .font(ChildlockTypography.label)
                            .foregroundStyle(ChildlockColor.textMuted)

                        HStack(spacing: ChildlockSpacing.xs) {
                            ForEach(3...12, id: \.self) { age in
                                Button {
                                    addChildDraft.age = age
                                } label: {
                                    Text("\(age)")
                                        .font(.system(size: 14, weight: addChildDraft.age == age ? .bold : .regular))
                                        .foregroundStyle(addChildDraft.age == age ? .white : ChildlockColor.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: ChildlockRadius.sm)
                                                .fill(addChildDraft.age == age ? ChildlockColor.primary : ChildlockColor.surface)
                                        )
                                        .childlockShadow(addChildDraft.age == age ? ChildlockShadow.sm : ShadowStyle(color: .clear, radius: 0, x: 0, y: 0))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Avatar color
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Avatar color")
                            .font(ChildlockTypography.label)
                            .foregroundStyle(ChildlockColor.textMuted)

                        HStack(spacing: ChildlockSpacing.md) {
                            ForEach(Array(ChildlockAvatarColor.all.enumerated()), id: \.offset) { index, color in
                                let avatarNames = ["fox", "rose", "bear", "sage", "lavender", "honey"]
                                let colorName = index < avatarNames.count ? avatarNames[index] : "fox"

                                Button {
                                    addChildDraft.avatarName = colorName
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(addChildDraft.avatarName == colorName ? ChildlockColor.primary : Color.clear, lineWidth: 3)
                                                .padding(-3)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("add_child_avatar_\(colorName)")
                                .accessibilityLabel("\(colorName.capitalized) avatar")
                            }
                        }
                    }

                    if let addChildErrorText {
                        Text(addChildErrorText)
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.warning)
                    }

                    // Save button
                    Button("Add \(addChildDraft.name.isEmpty ? "Child" : addChildDraft.name)") {
                        saveNewChildProfile()
                    }
                    .buttonStyle(ChildlockPrimaryButtonStyle())
                    .disabled(!addChildDraft.canSave)
                    .opacity(addChildDraft.canSave ? 1 : 0.5)

                    // Footer
                    if let firstChild = appState.profiles.first {
                        Text("Apps & interval copied from \(firstChild.name) · adjust anytime in the Apps tab")
                            .font(.system(size: 12))
                            .foregroundStyle(ChildlockColor.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(ChildlockSpacing.lg)
                .frame(maxWidth: dashboardContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddChildSheetPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func relativeTimeText(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let mins = Int(interval / 60)
            return "\(mins)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }

    private func emptyStateCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text(title)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)
            Text(subtitle)
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .childlockCard()
    }

    private var voicePromptBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.voicePromptsEnabled },
            set: { isEnabled in
                var updated = appState.settings
                updated.voicePromptsEnabled = isEnabled
                appState.settings = updated
            }
        )
    }

    private var dailySummaryBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.dailySummaryNotification },
            set: { isEnabled in
                var updated = appState.settings
                updated.dailySummaryNotification = isEnabled
                appState.settings = updated

                if isEnabled {
                    let summary = appState.todaySummary
                    Task {
                        _ = await NotificationService.requestPermission()
                        await MainActor.run {
                            NotificationService.scheduleDailySummary(
                                challengesCompleted: summary.challengesCompleted,
                                accuracy: Int((summary.accuracy * 100).rounded())
                            )
                            refreshNotificationAuthorizationStatus()
                        }
                    }
                } else {
                    NotificationService.cancelDailySummary()
                }
            }
        )
    }

    private var challengeAlertBinding: Binding<Bool> {
        Binding(
            get: { appState.settings.challengeAlertNotification },
            set: { isEnabled in
                var updated = appState.settings
                updated.challengeAlertNotification = isEnabled
                appState.settings = updated
                SharedDefaults.shared.set(isEnabled, forKey: SharedDefaults.Key.challengeAlertsEnabled)

                if isEnabled {
                    Task {
                        _ = await NotificationService.requestPermission()
                        await MainActor.run {
                            refreshNotificationAuthorizationStatus()
                        }
                    }
                }
            }
        )
    }

    private var notificationAuthorizationLabel: String {
        switch notificationAuthorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "On"
        case .denied:
            return "Off"
        case .notDetermined:
            return "Not asked"
        case .unavailable:
            return "Unavailable"
        }
    }

    private var notificationPermissionActionTitle: String {
        notificationAuthorizationStatus == .denied ? "Open Notification Settings" : "Enable Notifications"
    }

    private var notificationGuidanceText: String {
        if notificationAuthorizationStatus == .denied {
            return "Challenge alerts are off. The child can still tap Start Brain Break, press Home, and open Childlock to continue."
        }

        if notificationAuthorizationStatus.allowsDelivery {
            return "Challenge alerts guide the child back from the shield. If an alert is missed, press Home and open Childlock."
        }

        return "Enable alerts so shielded children get a cue back to Childlock. Home to Childlock still works if alerts are skipped."
    }

    private func refreshNotificationAuthorizationStatus() {
        Task {
            let status = await NotificationService.authorizationStatus()
            await MainActor.run {
                notificationAuthorizationStatus = status
            }
        }
    }

    @MainActor
    private func requestNotificationPermissionOrOpenSettings() async {
        isRequestingNotificationPermission = true
        defer { isRequestingNotificationPermission = false }

        if notificationAuthorizationStatus == .denied {
            openAppNotificationSettings()
            return
        }

        _ = await NotificationService.requestPermission()
        notificationAuthorizationStatus = await NotificationService.authorizationStatus()
    }

    private func openAppNotificationSettings() {
        #if os(iOS) && canImport(UIKit)
        let url = URL(string: UIApplication.openNotificationSettingsURLString)
            ?? URL(string: UIApplication.openSettingsURLString)

        if let url {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func presentAddChildSheetIfPossible() {
        guard canAddChildProfile else {
            addChildErrorText = "Childlock supports up to \(AppState.maxChildProfiles) child profiles."
            return
        }

        addChildDraft = AddChildDraft(intervalMinutes: appState.activeProfile?.intervalMinutes ?? 15)
        addChildErrorText = nil
        isAddChildSheetPresented = true
    }

    private func saveNewChildProfile() {
        guard canAddChildProfile else {
            addChildErrorText = "Childlock supports up to \(AppState.maxChildProfiles) child profiles."
            return
        }

        guard
            let newProfile = appState.addProfile(
                name: addChildDraft.name,
                age: addChildDraft.age,
                avatarName: addChildDraft.avatarName,
                intervalMinutes: addChildDraft.intervalMinutes
            )
        else {
            addChildErrorText = "Please enter a child name."
            return
        }

        childrenWindow = .day
        addChildErrorText = nil
        addChildDraft = AddChildDraft(intervalMinutes: newProfile.intervalMinutes)
        isAddChildSheetPresented = false
    }

    private func syncAppsSelectionStateFromActiveProfile() {
        guard let activeProfile = appState.activeProfile else {
            fallbackAppSelection = []
            appsStatusText = nil
            appsErrorText = nil
            #if os(iOS) && canImport(FamilyControls)
            appsFamilyActivitySelection = FamilyActivitySelection()
            #endif
            return
        }

        fallbackAppSelection = Set(activeProfile.monitoredAppDisplayNames)
        appsStatusText = nil
        appsErrorText = nil

        #if os(iOS) && canImport(FamilyControls)
        if
            let tokenData = activeProfile.monitoredSelectionTokenData,
            let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: tokenData)
        {
            appsFamilyActivitySelection = selection
        } else {
            appsFamilyActivitySelection = FamilyActivitySelection()
        }
        #endif
    }

    private func updateActiveProfileMonitoredSelection(tokenData: Data?, displayNames: [String]) {
        guard let activeProfile = appState.activeProfile else {
            appsErrorText = "Select a child profile first."
            appsStatusText = nil
            return
        }

        let didUpdate = appState.setMonitoredSelection(
            for: activeProfile.id,
            tokenData: tokenData,
            displayNames: displayNames
        )

        guard didUpdate else {
            appsErrorText = "Could not update this child's monitored apps."
            appsStatusText = nil
            return
        }

        appsStatusText = "Saved for \(activeProfile.name)."
        appsErrorText = nil

        if let updatedProfile = appState.activeProfile {
            refreshMonitoringIfRunning(for: updatedProfile)
        }
    }

    private func toggleFallbackSelection(_ appName: String) {
        if fallbackAppSelection.contains(appName) {
            fallbackAppSelection.remove(appName)
        } else {
            fallbackAppSelection.insert(appName)
        }

        updateActiveProfileMonitoredSelection(
            tokenData: nil,
            displayNames: fallbackAppSelection.sorted()
        )
    }

    #if os(iOS) && canImport(FamilyControls)
    private func requestAppsScreenTimeAccess() async {
        guard !isRequestingAppsScreenTimeAccess else { return }

        isRequestingAppsScreenTimeAccess = true
        defer { isRequestingAppsScreenTimeAccess = false }

        do {
            try await ScreenTimeManager.shared.requestAuthorization()
            isAppsScreenTimeSelectionAvailable = ScreenTimeManager.shared.isAuthorized
            appsStatusText = "Screen Time access granted. Choose real apps, categories, or websites to monitor."
            appsErrorText = nil
            isAppsFamilyActivityPickerPresented = isAppsScreenTimeSelectionAvailable
        } catch {
            isAppsScreenTimeSelectionAvailable = ScreenTimeManager.shared.isAuthorized
            appsStatusText = nil
            appsErrorText = error.localizedDescription
        }
    }
    #endif

    private func applyActiveSelectionToAllChildren() {
        guard let activeProfile = appState.activeProfile else {
            appsErrorText = "Select a child profile first."
            appsStatusText = nil
            return
        }

        guard hasActiveScreenTimeSelection else {
            appsErrorText = "Choose real apps, categories, or websites with Screen Time before copying this selection."
            appsStatusText = nil
            return
        }

        let updatedChildrenCount = appState.applyActiveProfileMonitoredSelectionToAllChildren()
        if updatedChildrenCount == 0 {
            appsStatusText = nil
            appsErrorText = "No other child profiles available to update."
            return
        }

        appsStatusText = "Copied \(activeProfile.name)'s selection to \(updatedChildrenCount) child profile\(updatedChildrenCount == 1 ? "" : "s")."
        appsErrorText = nil
    }

    private func refreshMonitoringIfRunning(for profile: ChildProfile) {
        guard monitoringStatusText == "running" else {
            return
        }

        do {
            try ScreenTimeManager.shared.startMonitoring(profile: profile)
            monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "running"
            monitoringErrorText = nil
        } catch {
            monitoringStatusText = "failed"
            monitoringErrorText = error.localizedDescription
        }
    }

    private var monitoringStatusLabel: String {
        switch monitoringStatus {
        case .notStarted:
            return "Not started"
        case .running:
            return "Running"
        case .intervalStarted:
            return "Timing app use"
        case .thresholdReached:
            return "Brain break ready"
        case .challengeRequested:
            return "Brain break pending"
        case .moreTimeRequested:
            return "Parent request"
        case .intervalEnded:
            return "Waiting"
        case .stopped:
            return "Stopped"
        case .denied:
            return "Permission needed"
        case .failed:
            return "Needs attention"
        case .none:
            return "Unknown"
        }
    }

    private var monitoringStatus: ChildlockMonitoringStatus? {
        ChildlockMonitoringStatus(storedValue: monitoringStatusText)
    }

    private var shouldShowStartLockEnforcementAction: Bool {
        switch monitoringStatus {
        case .running, .intervalStarted, .thresholdReached, .challengeRequested, .moreTimeRequested:
            return false
        case .notStarted, .intervalEnded, .stopped, .denied, .failed, .none:
            return true
        }
    }

    private var shouldShowStopLockEnforcementAction: Bool {
        switch monitoringStatus {
        case .running, .intervalStarted, .thresholdReached, .challengeRequested, .moreTimeRequested:
            return true
        case .notStarted, .intervalEnded, .stopped, .denied, .failed, .none:
            return false
        }
    }

    #if os(iOS) && canImport(FamilyControls)
    private func selectionSummaryLabels(for selection: FamilyActivitySelection) -> [String] {
        var labels: [String] = []

        let appCount = selection.applicationTokens.count
        if appCount > 0 {
            labels.append("\(appCount) app\(appCount == 1 ? "" : "s") selected")
        }

        let categoryCount = selection.categoryTokens.count
        if categoryCount > 0 {
            labels.append("\(categoryCount) categor\(categoryCount == 1 ? "y" : "ies") selected")
        }

        let domainCount = selection.webDomainTokens.count
        if domainCount > 0 {
            labels.append("\(domainCount) website\(domainCount == 1 ? "" : "s") selected")
        }

        return labels
    }
    #endif

    private func startScreenTimeEnforcement() async {
        guard let profile = appState.activeProfile else {
            monitoringErrorText = "No active child profile available."
            monitoringStatusText = "failed"
            return
        }

        guard hasActiveScreenTimeSelection else {
            monitoringErrorText = "Choose real apps, categories, or websites in Apps before starting enforcement."
            monitoringStatusText = "failed"
            return
        }

        do {
            if !ScreenTimeManager.shared.isAuthorized {
                try await ScreenTimeManager.shared.requestAuthorization()
            }

            try ScreenTimeManager.shared.startMonitoring(profile: profile)
            monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "running"
            monitoringErrorText = nil
        } catch {
            monitoringStatusText = "failed"
            monitoringErrorText = error.localizedDescription
        }
    }

    private func stopScreenTimeEnforcement() {
        guard let profile = monitoringProfile else {
            monitoringErrorText = "No monitored child profile available."
            monitoringStatusText = "failed"
            return
        }

        ScreenTimeManager.shared.stopMonitoring(profile: profile)
        monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "stopped"
        monitoringErrorText = nil
    }
}

private struct PaywallNavigationDestination: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PaywallView {
            dismiss()
        }
        .navigationBarBackButtonHidden(true)
    }
}

private extension AppState.ActivityWindow {
    var summarySuffix: String {
        switch self {
        case .day:
            return "today"
        case .week:
            return "this week"
        case .allTime:
            return "all time"
        }
    }
}

// MARK: - Add Child Draft

private struct AddChildDraft {
    static let avatars = [
        "fox", "rose", "bear", "sage", "lavender", "honey",
    ]

    var name: String = ""
    var age: Int = 7
    var avatarName: String = "fox"
    var intervalMinutes: Int = 15

    init(
        name: String = "",
        age: Int = 7,
        avatarName: String = "fox",
        intervalMinutes: Int = 15
    ) {
        self.name = name
        self.age = age
        self.avatarName = avatarName
        self.intervalMinutes = intervalMinutes
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
