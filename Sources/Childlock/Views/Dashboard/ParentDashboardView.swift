import SwiftUI
#if os(iOS) && canImport(FamilyControls)
import FamilyControls
#endif

public struct ParentDashboardView: View {
    @Bindable private var appState: AppState

    private let onTriggerChallenge: (() -> Void)?
    private let pinService: PINService
    private let fallbackAppChoices = ["YouTube", "Netflix", "Games", "Social Video"]

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
    @State private var selectedTab: AppState.Tab = .home
    #if os(iOS) && canImport(FamilyControls)
    @State private var isAppsFamilyActivityPickerPresented = false
    @State private var appsFamilyActivitySelection = FamilyActivitySelection()
    #endif

    public init(
        appState: AppState,
        onTriggerChallenge: (() -> Void)? = nil,
        pinService: PINService = .shared
    ) {
        self.appState = appState
        self.onTriggerChallenge = onTriggerChallenge
        self.pinService = pinService
    }

    public var body: some View {
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
        .onAppear {
            monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "not_started"
            monitoringErrorText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringLastError)
            syncAppsSelectionStateFromActiveProfile()
        }
        .onChange(of: appState.activeProfileID) { _, _ in
            syncAppsSelectionStateFromActiveProfile()
        }
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

    // MARK: - Home Tab

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    // Custom header
                    homeHeader

                    // Greeting
                    homeGreeting

                    if let onTriggerChallenge {
                        Button("Practice Brain Break", action: onTriggerChallenge)
                            .buttonStyle(ChildlockPrimaryButtonStyle())
                            .accessibilityLabel("practice_brain_break")
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
            }
            .background(ChildlockColor.background.ignoresSafeArea())
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
        }
    }

    private var homeGreeting: some View {
        let summary = appState.todaySummary
        let firstName = appState.profiles.first?.name ?? "there"

        return VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text("Good afternoon, Xavier")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("\(firstName)'s been engaged today -- \(summary.challengesCompleted) brain breaks solved.")
                .font(.system(size: 14))
                .foregroundStyle(ChildlockColor.textMuted)
        }
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
                addChildDraft = AddChildDraft(intervalMinutes: appState.activeProfile?.intervalMinutes ?? 15)
                addChildErrorText = nil
                isAddChildSheetPresented = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add a child")
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
        let activity = appState.recentActivity(limit: 4)

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("RECENT ACTIVITY")
                .font(ChildlockTypography.label)
                .foregroundStyle(ChildlockColor.textMuted)

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
                            addChildDraft = AddChildDraft(intervalMinutes: appState.activeProfile?.intervalMinutes ?? 15)
                            addChildErrorText = nil
                            isAddChildSheetPresented = true
                        } label: {
                            Text("+ Add child")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ChildlockColor.primaryDeep)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Each child has their own age band, interval, and apps. Up to 5 on Premium.")
                        .font(.system(size: 14))
                        .foregroundStyle(ChildlockColor.textMuted)

                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child to start personalized challenge tracking."
                        )
                    } else {
                        ForEach(appState.profiles) { profile in
                            childrenTabProfileCard(profile: profile)
                        }
                    }

                    // Premium info card
                    HStack(spacing: ChildlockSpacing.sm) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(ChildlockColor.primaryDeep)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium supports up to 5 children")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(ChildlockColor.primaryDeep)
                            Text("Free plan includes 1 child profile.")
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
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .sheet(isPresented: $isAddChildSheetPresented) {
                addChildSheet
            }
        }
    }

    private func childrenTabProfileCard(profile: ChildProfile) -> some View {
        let summary = appState.summary(window: .day, profileID: profile.id)
        let avatarColorIndex = appState.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0
        let avatarColor = ChildlockAvatarColor.all[avatarColorIndex % ChildlockAvatarColor.all.count]

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
                    Text("every \(profile.intervalMinutes)min · \(summary.challengesCompleted) solved · last active")
                        .font(.system(size: 12))
                        .foregroundStyle(ChildlockColor.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ChildlockColor.textFaint)
            }

            // Device pills
            HStack(spacing: ChildlockSpacing.xs) {
                devicePill(name: "iPad")
                devicePill(name: "iPhone")
            }
        }
        .padding(ChildlockSpacing.md)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private func devicePill(name: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(ChildlockColor.primary)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .padding(.horizontal, ChildlockSpacing.sm)
        .padding(.vertical, 6)
        .background(ChildlockColor.surfaceMuted.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.pill))
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
                    Text("Brain breaks appear during these.")
                        .font(.system(size: 14))
                        .foregroundStyle(ChildlockColor.textMuted)

                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child profile first, then assign monitored apps."
                        )
                    } else {
                        // Monitored section
                        Text("MONITORED")
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
                    HStack {
                        Text("No monitored apps selected yet.")
                            .font(ChildlockTypography.body)
                            .foregroundStyle(ChildlockColor.textSecondary)
                        Spacer()
                    }
                    .padding(ChildlockSpacing.md)
                } else {
                    ForEach(Array(appNames.enumerated()), id: \.element) { index, appName in
                        HStack(spacing: ChildlockSpacing.sm) {
                            // App icon placeholder
                            RoundedRectangle(cornerRadius: ChildlockRadius.sm)
                                .fill(appIconColor(for: index))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.8))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(appName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(ChildlockColor.textPrimary)
                                Text("every \(activeProfile.intervalMinutes)min")
                                    .font(.system(size: 12))
                                    .foregroundStyle(ChildlockColor.textMuted)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ChildlockColor.textFaint)
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

    private func appIconColor(for index: Int) -> Color {
        let colors: [Color] = [ChildlockColor.primary, ChildlockColor.accent, ChildlockColor.memory]
        return colors[index % colors.count]
    }

    @ViewBuilder
    private var appsAssignmentCard: some View {
        if appState.activeProfile != nil {
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                #if os(iOS) && canImport(FamilyControls)
                Button("+ Add apps to monitor") {
                    isAppsFamilyActivityPickerPresented = true
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
                .familyActivityPicker(
                    isPresented: $isAppsFamilyActivityPickerPresented,
                    selection: $appsFamilyActivitySelection
                )
                .onChange(of: appsFamilyActivitySelection) { _, selection in
                    let tokenData = try? JSONEncoder().encode(selection)
                    updateActiveProfileMonitoredSelection(
                        tokenData: tokenData,
                        displayNames: selectionSummaryLabels(for: selection)
                    )
                }
                #else
                VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
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
                        .accessibilityLabel("assign_monitored_\(appName)")
                    }
                }

                Button("+ Add apps to monitor") {
                    // Fallback: just shows the list above
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
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

                Button("Apply Active Child Selection To All Children") {
                    applyActiveSelectionToAllChildren()
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
                .disabled(appState.profiles.count < 2 || appState.activeProfile?.monitoredAppDisplayNames.isEmpty == true)
                .opacity((appState.profiles.count < 2 || appState.activeProfile?.monitoredAppDisplayNames.isEmpty == true) ? 0.5 : 1.0)
            }
        }
    }

    private var alwaysAllowedCard: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("These apps are never interrupted by brain breaks.")
                .font(.system(size: 14))
                .foregroundStyle(ChildlockColor.textSecondary)

            // Pill tags
            FlowLayout(spacing: ChildlockSpacing.xs) {
                alwaysAllowedPill("Phone")
                alwaysAllowedPill("Messages")
                alwaysAllowedPill("Khan Academy Kids")
                alwaysAllowedPill("Kindle")
            }
        }
        .padding(ChildlockSpacing.md)
        .background(ChildlockColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
        .childlockShadow(ChildlockShadow.sm)
    }

    private func alwaysAllowedPill(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 13))
            .foregroundStyle(ChildlockColor.textSecondary)
            .padding(.horizontal, ChildlockSpacing.sm)
            .padding(.vertical, 6)
            .background(ChildlockColor.surfaceMuted.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.pill))
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

                                Button("Unlock Settings") {
                                    let unlocked = appState.unlockSettings(with: enteredPIN, pinService: pinService)
                                    pinErrorText = unlocked ? nil : "Incorrect PIN. Try again."
                                    if unlocked {
                                        enteredPIN = ""
                                    }
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
                            settingsRow(title: "Subscription", value: "Free", showChevron: true, isUpgrade: true)
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
                                settingsRow(title: "Screen Time Enforcement", value: monitoringStatusText.capitalized, showChevron: false)

                                if let monitoringErrorText {
                                    Text(monitoringErrorText)
                                        .font(ChildlockTypography.caption)
                                        .foregroundStyle(ChildlockColor.warning)
                                        .padding(.horizontal, ChildlockSpacing.md)
                                        .padding(.bottom, ChildlockSpacing.sm)
                                }

                                Divider().background(ChildlockColor.surfaceMuted)

                                Button {
                                    Task { await startScreenTimeEnforcement() }
                                } label: {
                                    settingsRowContent(title: "Start Lock Enforcement", value: "", showChevron: true)
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.activeProfile == nil)

                                Divider().background(ChildlockColor.surfaceMuted)

                                Button {
                                    stopScreenTimeEnforcement()
                                } label: {
                                    settingsRowContent(title: "Stop Lock Enforcement", value: "", showChevron: true)
                                }
                                .buttonStyle(.plain)
                                .disabled(appState.activeProfile == nil)

                                Divider().background(ChildlockColor.surfaceMuted)

                                Button {
                                    appState.lockSettings(pinService: pinService)
                                } label: {
                                    settingsRowContent(title: "Lock Settings", value: "", showChevron: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Notifications section
                        settingsSection(title: "NOTIFICATIONS") {
                            VStack(spacing: 0) {
                                settingsToggleRow(title: "Daily summary", binding: dailySummaryBinding)
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsToggleRow(title: "Challenge alerts", binding: challengeAlertBinding)
                            }
                        }

                        // Support section
                        settingsSection(title: "SUPPORT") {
                            VStack(spacing: 0) {
                                settingsRow(title: "Help Center", value: "", showChevron: true)
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsRow(title: "Privacy Policy", value: "", showChevron: true)
                                Divider().background(ChildlockColor.surfaceMuted)
                                settingsRow(title: "Terms of Service", value: "", showChevron: true)
                            }
                        }
                    }
                }
                .padding(ChildlockSpacing.lg)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
        }
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

    private func settingsRowContent(title: String, value: String, showChevron: Bool, isUpgrade: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(isUpgrade ? ChildlockColor.primaryDeep : ChildlockColor.textPrimary)
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
        .padding(.horizontal, ChildlockSpacing.md)
        .padding(.vertical, ChildlockSpacing.sm)
    }

    private func settingsToggleRow(title: String, binding: Binding<Bool>) -> some View {
        Toggle(isOn: binding) {
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(ChildlockColor.textPrimary)
        }
        .tint(ChildlockColor.primary)
        .padding(.horizontal, ChildlockSpacing.md)
        .padding(.vertical, ChildlockSpacing.sm)
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
                        Text("Each child gets their own age-tuned challenges. Settings copy from \(firstChildName) by default -- you can tweak per child.")
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
                                .accessibilityLabel("add_child_avatar_\(colorName)")
                            }
                        }
                    }

                    // Apple ID section
                    HStack(spacing: ChildlockSpacing.sm) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                            .foregroundStyle(ChildlockColor.textPrimary)
                            .frame(width: 40, height: 40)
                            .background(ChildlockColor.surfaceMuted.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.sm))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple ID")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(ChildlockColor.textPrimary)
                            Text("child@icloud.com")
                                .font(.system(size: 12))
                                .foregroundStyle(ChildlockColor.textMuted)
                        }

                        Spacer()

                        Button("Change") {}
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(ChildlockColor.primaryDeep)
                            .buttonStyle(.plain)
                    }
                    .padding(ChildlockSpacing.md)
                    .background(ChildlockColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
                    .childlockShadow(ChildlockShadow.sm)

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
                        Text("Apps & interval copied from \(firstChild.name) · edit on next screen")
                            .font(.system(size: 12))
                            .foregroundStyle(ChildlockColor.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(ChildlockSpacing.lg)
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
            }
        )
    }

    private func saveNewChildProfile() {
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

    private func applyActiveSelectionToAllChildren() {
        guard let activeProfile = appState.activeProfile else {
            appsErrorText = "Select a child profile first."
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

    #if os(iOS) && canImport(FamilyControls)
    private func selectionSummaryLabels(for selection: FamilyActivitySelection) -> [String] {
        var labels: [String] = []

        let appCount = selection.applicationTokens.count
        if appCount > 0 {
            labels.append("\(appCount) app token\(appCount == 1 ? "" : "s") selected")
        }

        let categoryCount = selection.categoryTokens.count
        if categoryCount > 0 {
            labels.append("\(categoryCount) category token\(categoryCount == 1 ? "" : "s") selected")
        }

        let domainCount = selection.webDomainTokens.count
        if domainCount > 0 {
            labels.append("\(domainCount) web domain token\(domainCount == 1 ? "" : "s") selected")
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
        guard let profile = appState.activeProfile else {
            monitoringErrorText = "No active child profile available."
            monitoringStatusText = "failed"
            return
        }

        ScreenTimeManager.shared.stopMonitoring(profile: profile)
        monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "stopped"
        monitoringErrorText = nil
    }
}

// MARK: - Flow Layout (for pill tags)

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
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

private extension View {
    @ViewBuilder
    func pinInputBehavior() -> some View {
        #if os(iOS)
        keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
        #else
        self
        #endif
    }
}
