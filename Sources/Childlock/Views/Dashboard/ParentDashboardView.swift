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
        TabView(selection: $appState.currentTab) {
            homeTab
                .tabItem {
                    Label("Home", systemImage: appState.currentTab == .home ? "house.fill" : "house")
                }
                .tag(AppState.Tab.home)

            childrenTab
                .tabItem {
                    Label("Children", systemImage: appState.currentTab == .children ? "person.2.fill" : "person.2")
                }
                .tag(AppState.Tab.children)

            appsTab
                .tabItem {
                    Label("Apps", systemImage: appState.currentTab == .apps ? "app.fill" : "app")
                }
                .tag(AppState.Tab.apps)

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: appState.currentTab == .settings ? "gearshape.fill" : "gearshape")
                }
                .tag(AppState.Tab.settings)
        }
        .tint(ChildlockColor.accent)
        .onAppear {
            monitoringStatusText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringStatus) ?? "not_started"
            monitoringErrorText = SharedDefaults.shared.string(forKey: SharedDefaults.Key.monitoringLastError)
            syncAppsSelectionStateFromActiveProfile()
        }
        .onChange(of: appState.activeProfileID) { _, _ in
            syncAppsSelectionStateFromActiveProfile()
        }
    }

    private var homeTab: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ChildlockSpacing.md) {
                    summaryCard

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
                        childrenOverviewCard
                        recentActivityCard
                    }
                }
                .padding(ChildlockSpacing.lg)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .navigationTitle("Home")
        }
    }

    private var childrenTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child to start personalized challenge tracking."
                        )
                    } else {
                        childrenSelectorCard
                        childrenSummaryCard
                        childrenHistoryCard
                    }

                    Button("Add Child") {
                        addChildDraft = AddChildDraft(intervalMinutes: appState.activeProfile?.intervalMinutes ?? 15)
                        addChildErrorText = nil
                        isAddChildSheetPresented = true
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .accessibilityLabel("add_child_profile")
                }
                .padding(ChildlockSpacing.lg)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .navigationTitle("Children")
            .sheet(isPresented: $isAddChildSheetPresented) {
                addChildSheet
            }
        }
    }

    private var appsTab: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    if appState.profiles.isEmpty {
                        emptyStateCard(
                            title: "No child profiles yet",
                            subtitle: "Add a child profile first, then assign monitored apps."
                        )
                    } else {
                        appsChildSelectorCard
                        appsMonitoredListCard
                        appsAssignmentCard
                    }
                }
                .padding(ChildlockSpacing.lg)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .navigationTitle("Apps")
        }
    }

    private var settingsTab: some View {
        NavigationStack {
            List {
                if appState.isPINLocked {
                    Section("Parent PIN") {
                        SecureField("Enter PIN", text: $enteredPIN)
                            .pinInputBehavior()
                            .font(ChildlockTypography.body)

                        Button("Unlock Settings") {
                            let unlocked = appState.unlockSettings(with: enteredPIN, pinService: pinService)
                            pinErrorText = unlocked ? nil : "Incorrect PIN. Try again."
                            if unlocked {
                                enteredPIN = ""
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ChildlockColor.accent)

                        if let pinErrorText {
                            Text(pinErrorText)
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.warning)
                        }
                    }
                } else {
                    Section("Preferences") {
                        Toggle("Voice prompts (ages 3-5)", isOn: voicePromptBinding)
                        Toggle("Daily summary notification", isOn: dailySummaryBinding)
                        Toggle("Challenge alert notification", isOn: challengeAlertBinding)
                    }

                    Section("Screen Time Enforcement") {
                        Text("Status: \(monitoringStatusText)")
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textSecondary)

                        if let monitoringErrorText {
                            Text(monitoringErrorText)
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.warning)
                        }

                        Button("Start Lock Enforcement") {
                            Task {
                                await startScreenTimeEnforcement()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ChildlockColor.accent)
                        .disabled(appState.activeProfile == nil)

                        Button("Stop Lock Enforcement") {
                            stopScreenTimeEnforcement()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .disabled(appState.activeProfile == nil)
                    }

                    Section {
                        Button("Lock Settings") {
                            appState.lockSettings(pinService: pinService)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(ChildlockColor.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ChildlockColor.background)
            .navigationTitle("Settings")
        }
    }

    private var summaryCard: some View {
        let summary = appState.todaySummary

        return VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            Text("TODAY")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textSecondary)

            Text("\(summary.challengesCompleted) challenges completed")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("Accuracy \(Int(summary.accuracy * 100))% · Screen time \(summary.screenTimeFormatted)")
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)

            Text("Challenge effort \(summary.challengeTimeFormatted) · Avg solve \(summary.averageSolveTimeFormatted)")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .childlockCard()
    }

    private var childrenOverviewCard: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("Children")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            ForEach(appState.profiles) { profile in
                VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                    Text("\(profile.name) · Age \(profile.age)")
                        .font(ChildlockTypography.body.weight(.semibold))
                        .foregroundStyle(ChildlockColor.textPrimary)
                    Text("Break every \(profile.intervalMinutes)m")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                }
                .padding(.vertical, ChildlockSpacing.xs)
            }
        }
        .childlockCard()
    }

    private var childrenSelectorCard: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("Child Selector")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ChildlockSpacing.xs) {
                    ForEach(appState.profiles) { profile in
                        let isSelected = appState.activeProfile?.id == profile.id
                        Button {
                            appState.setActiveProfile(id: profile.id)
                        } label: {
                            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                                Text(profile.name)
                                    .font(ChildlockTypography.body.weight(.semibold))
                                    .foregroundStyle(ChildlockColor.textPrimary)

                                Text("Age \(profile.age) · \(profile.intervalMinutes)m")
                                    .font(ChildlockTypography.caption)
                                    .foregroundStyle(ChildlockColor.textSecondary)
                            }
                            .frame(width: 160, alignment: .leading)
                            .padding(.horizontal, ChildlockSpacing.sm)
                            .padding(.vertical, ChildlockSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                                    .fill(isSelected ? ChildlockColor.accentSoft : ChildlockColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                                    .stroke(isSelected ? ChildlockColor.accent : ChildlockColor.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("select_child_\(profile.name)")
                    }
                }
            }
        }
        .childlockCard()
    }

    private var childrenSummaryCard: some View {
        let selectedProfile = appState.activeProfile ?? appState.profiles.first
        let summary = appState.summary(window: childrenWindow, profileID: selectedProfile?.id)

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            HStack {
                Text("Per-Child Stats")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)
                Spacer()
                Picker("Window", selection: $childrenWindow) {
                    Text(AppState.ActivityWindow.day.title).tag(AppState.ActivityWindow.day)
                    Text(AppState.ActivityWindow.week.title).tag(AppState.ActivityWindow.week)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 170)
            }

            if let selectedProfile {
                Text("\(selectedProfile.name) · \(childrenWindow.title)")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            HStack(spacing: ChildlockSpacing.sm) {
                childrenMetricBlock(title: "Completed", value: "\(summary.challengesCompleted)")
                childrenMetricBlock(title: "Accuracy", value: "\(Int(summary.accuracy * 100))%")
                childrenMetricBlock(title: "Screen", value: summary.screenTimeFormatted)
            }

            Text("Challenge effort \(summary.challengeTimeFormatted) · Avg solve \(summary.averageSolveTimeFormatted)")
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .childlockCard()
    }

    @ViewBuilder
    private var childrenHistoryCard: some View {
        if let selectedProfile = appState.activeProfile ?? appState.profiles.first {
            let activity = appState.recentActivity(
                limit: childrenWindow == .week ? 12 : 6,
                profileID: selectedProfile.id,
                window: childrenWindow
            )

            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Challenge History")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                if activity.isEmpty {
                    Text("No completed challenges yet in this window.")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textSecondary)
                } else {
                    ForEach(activity) { item in
                        HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                            Text(item.result.type.rawValue.capitalized)
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.textPrimary)
                                .padding(.horizontal, ChildlockSpacing.sm)
                                .padding(.vertical, ChildlockSpacing.xxs)
                                .background(ChildlockColor.accentSoft)
                                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))

                            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                                Text(item.result.completed ? "Solved" : "Incomplete")
                                    .font(ChildlockTypography.body.weight(.semibold))
                                    .foregroundStyle(ChildlockColor.textPrimary)

                                let solve = item.result.solveTimeSeconds.map { "\(Int($0.rounded()))s" } ?? "—"
                                Text("Attempts \(item.result.attempts) · Solve \(solve)")
                                    .font(ChildlockTypography.caption)
                                    .foregroundStyle(ChildlockColor.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, ChildlockSpacing.xxs)
                    }
                }
            }
            .childlockCard()
        }
    }

    private var appsChildSelectorCard: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("Active Child")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ChildlockSpacing.xs) {
                    ForEach(appState.profiles) { profile in
                        let isSelected = appState.activeProfile?.id == profile.id
                        Button {
                            appState.setActiveProfile(id: profile.id)
                        } label: {
                            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                                Text(profile.name)
                                    .font(ChildlockTypography.body.weight(.semibold))
                                    .foregroundStyle(ChildlockColor.textPrimary)

                                Text("\(profile.monitoredAppDisplayNames.count) assignments")
                                    .font(ChildlockTypography.caption)
                                    .foregroundStyle(ChildlockColor.textSecondary)
                            }
                            .frame(width: 168, alignment: .leading)
                            .padding(.horizontal, ChildlockSpacing.sm)
                            .padding(.vertical, ChildlockSpacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                                    .fill(isSelected ? ChildlockColor.accentSoft : ChildlockColor.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                                    .stroke(isSelected ? ChildlockColor.accent : ChildlockColor.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("select_apps_child_\(profile.name)")
                    }
                }
            }
        }
        .childlockCard()
    }

    @ViewBuilder
    private var appsMonitoredListCard: some View {
        if let activeProfile = appState.activeProfile {
            let appNames = activeProfile.monitoredAppDisplayNames

            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Monitored Scope")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("\(activeProfile.name) · \(appNames.count) assigned")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)

                if appNames.isEmpty {
                    Text("No monitored apps selected yet.")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        ForEach(appNames, id: \.self) { appName in
                            Text("• \(appName)")
                                .font(ChildlockTypography.body)
                                .foregroundStyle(ChildlockColor.textPrimary)
                        }
                    }
                }
            }
            .childlockCard()
        }
    }

    @ViewBuilder
    private var appsAssignmentCard: some View {
        if appState.activeProfile != nil {
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Assign Monitored Apps")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Changes save to the selected child profile.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)

                #if os(iOS) && canImport(FamilyControls)
                Button("Open Apple App Picker") {
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
                                    .foregroundStyle(fallbackAppSelection.contains(appName) ? ChildlockColor.accent : ChildlockColor.border)
                            }
                            .padding(.horizontal, ChildlockSpacing.sm)
                            .frame(height: 44)
                            .background(ChildlockColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                                    .stroke(ChildlockColor.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("assign_monitored_\(appName)")
                    }
                }
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
            .childlockCard()
        }
    }

    private var addChildSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Child name")
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textSecondary)

                        TextField("E.g. Mia", text: $addChildDraft.name)
                            .font(ChildlockTypography.body)
                            .padding(.horizontal, ChildlockSpacing.sm)
                            .frame(height: 44)
                            .background(ChildlockColor.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                                    .stroke(ChildlockColor.border, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Stepper(value: $addChildDraft.age, in: 3...12) {
                            Text("Age \(addChildDraft.age)")
                                .font(ChildlockTypography.body)
                                .foregroundStyle(ChildlockColor.textPrimary)
                        }

                        Stepper(value: $addChildDraft.intervalMinutes, in: 5...30, step: 5) {
                            Text("Challenge every \(addChildDraft.intervalMinutes) minutes")
                                .font(ChildlockTypography.body)
                                .foregroundStyle(ChildlockColor.textPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        Text("Avatar")
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textSecondary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: ChildlockSpacing.xs), count: 4),
                            spacing: ChildlockSpacing.xs
                        ) {
                            ForEach(AddChildDraft.avatars, id: \.self) { avatar in
                                Button(avatar.capitalized) {
                                    addChildDraft.avatarName = avatar
                                }
                                .buttonStyle(ChildAvatarChoiceButtonStyle(isSelected: addChildDraft.avatarName == avatar))
                                .accessibilityLabel("add_child_avatar_\(avatar)")
                            }
                        }
                    }

                    if let addChildErrorText {
                        Text(addChildErrorText)
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.warning)
                    }

                    Button("Save Child Profile") {
                        saveNewChildProfile()
                    }
                    .buttonStyle(ChildlockPrimaryButtonStyle())
                    .disabled(!addChildDraft.canSave)
                    .opacity(addChildDraft.canSave ? 1 : 0.5)
                }
                .padding(ChildlockSpacing.lg)
            }
            .background(ChildlockColor.background.ignoresSafeArea())
            .navigationTitle("Add Child")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddChildSheetPresented = false
                    }
                }
            }
        }
    }

    private func childrenMetricBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
            Text(title.uppercased())
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textSecondary)

            Text(value)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ChildlockSpacing.sm)
        .padding(.vertical, ChildlockSpacing.sm)
        .background(ChildlockColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: ChildlockRadius.control)
                .stroke(ChildlockColor.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))
    }

    private var recentActivityCard: some View {
        let activity = appState.recentActivity(limit: 4)

        return VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
            Text("Recent Activity")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            if activity.isEmpty {
                Text("Challenges will appear here once your child starts using monitored apps.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            } else {
                ForEach(Array(activity.enumerated()), id: \.element.id) { _, item in
                    HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                        Text(item.avatarName.prefix(1).uppercased())
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(ChildlockColor.accentSoft)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                            Text("\(item.profileName) solved a \(item.result.type.rawValue) challenge")
                                .font(ChildlockTypography.body)
                                .foregroundStyle(ChildlockColor.textPrimary)

                            let solveTimeText = item.result.solveTimeSeconds.map { "Solved in \(Int($0))s" } ?? "Solved"

                            Text("\(solveTimeText) · Attempts \(item.result.attempts)")
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.textSecondary)
                        }
                    }
                    .padding(.vertical, ChildlockSpacing.xs)
                }
            }
        }
        .childlockCard()
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

private struct AddChildDraft {
    static let avatars = [
        "fox", "owl", "bear", "bunny", "cat", "dog",
        "turtle", "penguin", "koala", "lion", "elephant", "panda",
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

private struct ChildAvatarChoiceButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChildlockTypography.caption)
            .foregroundStyle(ChildlockColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .fill(isSelected ? ChildlockColor.accentSoft : ChildlockColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .stroke(isSelected ? ChildlockColor.accent : ChildlockColor.border, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1.0)
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
