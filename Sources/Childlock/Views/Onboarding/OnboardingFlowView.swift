import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if os(iOS) && canImport(FamilyControls)
import FamilyControls
#endif

public struct OnboardingFlowView: View {
    @Bindable private var viewModel: OnboardingViewModel
    @State private var signInErrorText: String?
    @State private var isGoogleSignInInProgress = false
    #if os(iOS) && canImport(FamilyControls)
    @State private var isFamilyActivityPickerPresented = false
    @State private var familyActivitySelection = FamilyActivitySelection()
    #endif

    private let onboardingContentMaxWidth: CGFloat = 620

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            switch viewModel.step {
            case .welcome:
                welcomeStep
            case .familySharing:
                innerStep { familySharingStep }
            case .devices:
                innerStep { devicesStep }
            case .setup:
                innerStepWithPinnedFooter {
                    setupStep
                } footer: {
                    setupFooter
                }
            case .pinAndDone:
                innerStep { pinAndDoneStep }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background.ignoresSafeArea())
        .onAppear {
            #if os(iOS) && canImport(FamilyControls)
            familyActivitySelection = viewModel.hydrateFamilyActivitySelection()
            #endif
        }
        .onChange(of: viewModel.step) { _, step in
            #if os(iOS) && canImport(FamilyControls)
            guard step == .setup else { return }
            familyActivitySelection = viewModel.hydrateFamilyActivitySelection()
            #endif
        }
    }

    // MARK: - Inner Step Wrapper (with indicator + back + scroll)

    private func innerStep<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            stepTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.lg) {
                    content()
                }
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.bottom, ChildlockSpacing.section)
                .frame(maxWidth: onboardingContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func innerStepWithPinnedFooter<Content: View, Footer: View>(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(spacing: 0) {
            stepTopBar

            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.lg) {
                    content()
                }
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.bottom, ChildlockSpacing.lg)
                .frame(maxWidth: onboardingContentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }

            footer()
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.top, ChildlockSpacing.sm)
                .padding(.bottom, ChildlockSpacing.lg)
                .frame(maxWidth: onboardingContentMaxWidth)
                .frame(maxWidth: .infinity)
                .background(ChildlockColor.background)
        }
    }

    private var stepTopBar: some View {
        HStack {
            if viewModel.canGoBack {
                Button {
                    viewModel.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(ChildlockColor.textPrimary)
                }
            } else {
                Color.clear.frame(width: 24, height: 24)
            }

            Spacer()
            stepIndicator
            Spacer()
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, ChildlockSpacing.lg)
        .padding(.top, ChildlockSpacing.sm)
        .padding(.bottom, ChildlockSpacing.md)
    }

    // MARK: - Step Indicator Dots

    private var stepIndicator: some View {
        HStack(spacing: ChildlockSpacing.xxs) {
            ForEach(OnboardingViewModel.Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= viewModel.step.rawValue ? ChildlockColor.primary : ChildlockColor.textFaint)
                    .frame(width: s == viewModel.step ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.step)
            }
        }
    }

    // MARK: - Welcome (Step 1)

    private var welcomeStep: some View {
        VStack(spacing: ChildlockSpacing.lg) {
            // Hero illustration: a friendly character, not abstract geometry
            ZStack {
                RoundedRectangle(cornerRadius: ChildlockRadius.xl)
                    .fill(ChildlockColor.primarySoft)
                    .frame(height: 220)

                ZStack {
                    // Body
                    UnevenRoundedRectangle(
                        topLeadingRadius: 60,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 60
                    )
                    .fill(ChildlockColor.accent.opacity(0.7))
                    .frame(width: 110, height: 120)
                    .offset(y: 36)

                    // Head
                    Circle()
                        .fill(ChildlockColor.warnSoft)
                        .frame(width: 84, height: 84)
                        .offset(y: -36)

                    // Eyes
                    HStack(spacing: 18) {
                        Circle().fill(ChildlockColor.primaryDeep).frame(width: 9, height: 9)
                        Circle().fill(ChildlockColor.primaryDeep).frame(width: 9, height: 9)
                    }
                    .offset(y: -42)

                    // Smile
                    Circle()
                        .trim(from: 0.08, to: 0.42)
                        .stroke(ChildlockColor.primaryDeep, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 30, height: 30)
                        .offset(y: -26)

                    // Spark above the head
                    Image(systemName: "sparkle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(ChildlockColor.primary)
                        .offset(x: 52, y: -74)
                }
            }
            .padding(.horizontal, ChildlockSpacing.lg)

            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Turn screen time into brain time.")
                    .font(ChildlockTypography.display)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Quick brain breaks during your child's screen time. Calmer transitions, quick learning, fewer battles.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)

                HStack(spacing: ChildlockSpacing.xs) {
                    Image(systemName: "iphone")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(ChildlockColor.primary)
                    Text("Set up Childlock on the device your child uses.")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                }
                .padding(ChildlockSpacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ChildlockColor.primarySoft.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.sm))
            }
            .padding(.horizontal, ChildlockSpacing.lg)

            VStack(spacing: ChildlockSpacing.sm) {
                #if canImport(AuthenticationServices)
                SignInWithAppleButtonView(
                    onSuccess: { userID, email, fullName, identityToken, rawNonce in
                        Task {
                            let didSignIn = await AuthService.shared.handleSignIn(
                                userID: userID,
                                email: email,
                                fullName: fullName,
                                identityToken: identityToken,
                                rawNonce: rawNonce
                            )
                            if didSignIn {
                                signInErrorText = nil
                                viewModel.markSignupComplete()
                                viewModel.goNext()
                            } else {
                                signInErrorText = AuthService.shared.lastErrorMessage
                            }
                        }
                    },
                    onError: { error in
                        signInErrorText = error.localizedDescription
                    }
                )
                #else
                Text("Apple sign in is unavailable on this device.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                #endif

                if shouldShowGoogleSignIn {
                    Button {
                        signInWithGoogle()
                    } label: {
                        GoogleSignInButtonLabel(isInProgress: isGoogleSignInInProgress)
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .disabled(isGoogleSignInInProgress)
                    .opacity(isGoogleSignInInProgress ? 0.7 : 1.0)
                }

                if let signInErrorText {
                    Text(signInErrorText)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.warning)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Free to start \u{00B7} no credit card needed")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, ChildlockSpacing.lg)
            .padding(.bottom, ChildlockSpacing.lg)
        }
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var shouldShowGoogleSignIn: Bool {
        BackendConfig.current.isSupabaseConfigured && BackendConfig.current.isGoogleSignInConfigured
    }

    private func signInWithGoogle() {
        guard shouldShowGoogleSignIn else {
            signInErrorText = "Google sign in is not available in this build. Please use Sign in with Apple for now."
            return
        }

        isGoogleSignInInProgress = true
        signInErrorText = nil

        Task {
            let didSignIn = await AuthService.shared.handleGoogleSignIn()
            isGoogleSignInInProgress = false

            if didSignIn {
                viewModel.markSignupComplete()
                viewModel.goNext()
            } else {
                signInErrorText = AuthService.shared.lastErrorMessage
            }
        }
    }

    // MARK: - Family Sharing (Step 2)

    private var familySharingStep: some View {
        Group {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Apple's Screen Time controls let Childlock pause selected apps on this device — your child's device.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            // Info cards 1-3
            infoCard(
                number: 1,
                heading: "What it does",
                body: "Triggers a brain break in selected apps at your interval."
            )
            infoCard(
                number: 2,
                heading: "What it doesn't do",
                body: "Never sees app contents, messages, or browsing history."
            )
            infoCard(
                number: 3,
                heading: "Where data lives",
                body: "Challenge progress syncs to your private Childlock account. Apple never shares which apps your child uses with us."
            )

            Text(viewModel.authorizationStatusText)
                .font(ChildlockTypography.caption)
                .foregroundStyle(viewModel.shouldShowAuthorizationHelp ? ChildlockColor.warning : ChildlockColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: ChildlockSpacing.sm) {
                Button(screenTimeAccessButtonTitle) {
                    Task {
                        await viewModel.requestFamilyAuthorization()
                    }
                }
                .buttonStyle(ChildlockPrimaryButtonStyle())
                .disabled(viewModel.familyAuthorizationState == .requesting)
            }

            if viewModel.canContinue, viewModel.familyAuthorizationState != .notRequested {
                Button("Continue") {
                    viewModel.goNext()
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
            }
        }
    }

    // MARK: - Devices (Step 3)

    private var devicesStep: some View {
        Group {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Childlock protects the device your child actually uses. Shared iPhone? Set it up here. Child iPad? Install and run setup on the iPad too; a parent-only iPhone install will not lock the iPad at launch.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            // How it works on this device
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                deviceStepRow(
                    icon: "iphone",
                    heading: "Shared phone is supported",
                    body: "Set up this phone, keep the dashboard behind your PIN, and hand it back after each challenge."
                )
                deviceStepRow(
                    icon: "ipad",
                    heading: "Child iPad needs its own setup",
                    body: "Run setup on the iPad so Apple's Screen Time controls can pause apps there."
                )
                deviceStepRow(
                    icon: "lock.shield",
                    heading: "Parent settings stay protected",
                    body: "Your child can solve puzzles, but they cannot change monitoring without the PIN."
                )
            }
            .childlockCard()
            .frame(maxWidth: .infinity, alignment: .leading)

            // Multi-device honesty
            HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(ChildlockColor.primary)
                Text("For launch, Childlock locks apps on the device where setup is completed. A separate parent-phone remote dashboard is not included at launch.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
            .padding(ChildlockSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ChildlockColor.primarySoft.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.md))

            Button("Continue") {
                viewModel.goNext()
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
        }
    }

    // MARK: - Setup (Step 4 - combined profile + apps + interval)

    private var setupStep: some View {
        Group {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Three quick things. You can edit anything later.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            // Section 1: Profile
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Profile")
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)

                // Name field
                VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                    Text("Name")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)

                    TextField("Type your child's name", text: $viewModel.childName)
                        .font(ChildlockTypography.body)
                        .padding(.horizontal, ChildlockSpacing.sm)
                        .frame(height: 44)
                        .background(ChildlockColor.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: ChildlockRadius.control)
                                .stroke(ChildlockColor.border, lineWidth: 1)
                        )
                }

                // Age stepper
                HStack {
                    Text("Age")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textPrimary)

                    Spacer()

                    HStack(spacing: ChildlockSpacing.md) {
                        Button {
                            if viewModel.childAge > 3 {
                                viewModel.childAge -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(viewModel.childAge > 3 ? ChildlockColor.primary : ChildlockColor.textFaint)
                        }
                        .disabled(viewModel.childAge <= 3)

                        Text("\(viewModel.childAge)")
                            .font(ChildlockTypography.subtitle)
                            .foregroundStyle(ChildlockColor.textPrimary)
                            .frame(minWidth: 32)
                            .multilineTextAlignment(.center)

                        Button {
                            if viewModel.childAge < 12 {
                                viewModel.childAge += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(viewModel.childAge < 12 ? ChildlockColor.primary : ChildlockColor.textFaint)
                        }
                        .disabled(viewModel.childAge >= 12)
                    }
                }

                // Avatar color circles
                VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                    Text("Avatar")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)

                    HStack(spacing: ChildlockSpacing.sm) {
                        ForEach(ChildlockAvatarColor.all.indices, id: \.self) { index in
                            let color = ChildlockAvatarColor.all[index]
                            let avatarName = avatarNameForIndex(index)

                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            viewModel.selectedAvatar == avatarName ? ChildlockColor.primaryDeep : Color.clear,
                                            lineWidth: 2.5
                                        )
                                        .frame(width: 42, height: 42)
                                )
                                .onTapGesture {
                                    viewModel.selectedAvatar = avatarName
                                }
                                .accessibilityIdentifier("avatar_\(avatarName)")
                                .accessibilityLabel("\(avatarName.capitalized) avatar")
                        }
                    }
                }
            }
            .childlockCard()

            // Section 2: Apps to monitor
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Apps to monitor")
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)

                if shouldUseFamilyActivityPicker {
                    #if os(iOS) && canImport(FamilyControls)
                    VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                        if viewModel.selectedMonitoredApps.isEmpty {
                            HStack(alignment: .top, spacing: ChildlockSpacing.xs) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ChildlockColor.primary)
                                Text("No Screen Time items selected yet. Use the button below to choose real apps, categories, or websites.")
                                    .font(ChildlockTypography.caption)
                                    .foregroundStyle(ChildlockColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            Button {
                                isFamilyActivityPickerPresented = true
                            } label: {
                                Label("Change apps, categories, or websites", systemImage: "checklist")
                            }
                            .buttonStyle(ChildlockSecondaryButtonStyle())

                            Text("Selection saved from Apple's Screen Time picker.")
                                .font(ChildlockTypography.caption)
                                .foregroundStyle(ChildlockColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .familyActivityPicker(
                        isPresented: $isFamilyActivityPickerPresented,
                        selection: $familyActivitySelection
                    )
                    .onChange(of: familyActivitySelection) { _, selection in
                        viewModel.updateFamilyActivitySelection(selection)
                    }

                    if !viewModel.selectedMonitoredApps.isEmpty {
                        VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                            ForEach(viewModel.selectedMonitoredApps.sorted(), id: \.self) { summary in
                                HStack(spacing: ChildlockSpacing.xs) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(ChildlockColor.primary)
                                    Text(summary)
                                        .font(ChildlockTypography.caption)
                                        .foregroundStyle(ChildlockColor.textSecondary)
                                }
                            }
                        }
                    }
                    #endif
                } else {
                    fallbackAppChoices
                }
            }
            .childlockCard()

            // Section 3: Brain break interval
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Brain break every")
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)

                HStack(spacing: ChildlockSpacing.xs) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { interval in
                        Button {
                            viewModel.selectedInterval = interval
                        } label: {
                            Text("\(interval)m")
                                .font(ChildlockTypography.bodyBold)
                                .foregroundStyle(
                                    viewModel.selectedInterval == interval ? .white : ChildlockColor.textPrimary
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    Capsule()
                                        .fill(viewModel.selectedInterval == interval ? ChildlockColor.primary : ChildlockColor.surfaceMuted)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("A challenge appears every \(viewModel.selectedInterval) minutes while monitored apps are active.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
            .childlockCard()

        }
    }

    private var setupFooter: some View {
        VStack(spacing: ChildlockSpacing.sm) {
            if let blockingReason = viewModel.setupBlockingReason {
                HStack(alignment: .top, spacing: ChildlockSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ChildlockColor.warning)

                    Text(blockingReason)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, ChildlockSpacing.sm)
                .padding(.vertical, ChildlockSpacing.xs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ChildlockColor.warning.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control, style: .continuous))
            }

            if shouldShowScreenTimePickerFooterAction {
                Button {
                    #if os(iOS) && canImport(FamilyControls)
                    isFamilyActivityPickerPresented = true
                    #endif
                } label: {
                    Label("Choose apps, categories, or websites", systemImage: "checklist")
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
                .accessibilityIdentifier("setup_footer_choose_screen_time_items")
                .accessibilityHint("Open Apple's Screen Time picker to choose apps, categories, or websites.")
            }

            Button("Continue") {
                viewModel.goNext()
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.45)
            .accessibilityHint(viewModel.setupBlockingReason ?? "Continue to parent PIN setup.")
        }
    }

    private var shouldShowScreenTimePickerFooterAction: Bool {
        #if os(iOS) && canImport(FamilyControls)
        return shouldUseFamilyActivityPicker && viewModel.needsMonitoringSelection
        #else
        return false
        #endif
    }

    // MARK: - PIN + Done (Step 5)

    private var pinAndDoneStep: some View {
        Group {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)
            }

            // Summary card
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                summaryRow(icon: "person.fill", text: "\(viewModel.childName), age \(viewModel.childAge)")
                summaryRow(icon: "app.badge.fill", text: appSummaryText)
                summaryRow(icon: "timer", text: "Every \(viewModel.selectedInterval) minutes")
            }
            .childlockCard()

            // PIN section
            VStack(spacing: ChildlockSpacing.md) {
                Text("Last step \u{00B7} parent PIN")
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)

                // PIN dots
                HStack(spacing: ChildlockSpacing.md) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(pinDigitEntered(at: index) ? ChildlockColor.primary : ChildlockColor.surfaceMuted)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Circle()
                                    .stroke(ChildlockColor.primary.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                if !viewModel.pin.isEmpty && viewModel.pin.count == 4 && viewModel.pinConfirmation.isEmpty {
                    Text("Confirm your PIN")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                }

                if viewModel.pin.count == 4 && !viewModel.pinConfirmation.isEmpty && viewModel.pinConfirmation != viewModel.pin && viewModel.pinConfirmation.count == 4 {
                    Text("PINs don't match. Try again.")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.warning)
                }

                if let completionErrorText = viewModel.completionErrorText {
                    Text(completionErrorText)
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.warning)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Number pad
                numberPad
            }

            Button(viewModel.canContinue ? "Go To Dashboard" : "Set PIN to continue") {
                viewModel.goNext()
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.45)
        }
    }

    // MARK: - Number Pad

    private var numberPad: some View {
        let keys: [[NumberPadKey]] = [
            [.digit(1), .digit(2), .digit(3)],
            [.digit(4), .digit(5), .digit(6)],
            [.digit(7), .digit(8), .digit(9)],
            [.blank, .digit(0), .backspace],
        ]

        return VStack(spacing: ChildlockSpacing.xs) {
            ForEach(0..<keys.count, id: \.self) { row in
                HStack(spacing: ChildlockSpacing.xs) {
                    ForEach(0..<keys[row].count, id: \.self) { col in
                        numberPadButton(keys[row][col])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func numberPadButton(_ key: NumberPadKey) -> some View {
        switch key {
        case .digit(let d):
            Button {
                appendPinDigit("\(d)")
            } label: {
                Text("\(d)")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: ChildlockRadius.control)
                            .fill(ChildlockColor.surface)
                    )
            }
            .buttonStyle(.plain)

        case .backspace:
            Button {
                deletePinDigit()
            } label: {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ChildlockColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.plain)

        case .blank:
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
    }

    // MARK: - PIN Helpers

    private var currentPinTarget: String {
        viewModel.pin.count < 4 ? viewModel.pin : viewModel.pinConfirmation
    }

    private var isConfirmingPin: Bool {
        viewModel.pin.count == 4
    }

    private func pinDigitEntered(at index: Int) -> Bool {
        let target = isConfirmingPin ? viewModel.pinConfirmation : viewModel.pin
        return index < target.count
    }

    private func appendPinDigit(_ digit: String) {
        if viewModel.pin.count < 4 {
            viewModel.pin += digit
        } else if viewModel.pinConfirmation.count < 4 {
            viewModel.pinConfirmation += digit
        }
    }

    private func deletePinDigit() {
        if isConfirmingPin {
            if !viewModel.pinConfirmation.isEmpty {
                viewModel.pinConfirmation.removeLast()
            }
        } else {
            if !viewModel.pin.isEmpty {
                viewModel.pin.removeLast()
            }
        }
    }

    // MARK: - Helpers

    private var appSummaryText: String {
        let count = viewModel.selectedMonitoredApps.count
        if count == 0 {
            return "No apps selected"
        }
        return "\(count) app\(count == 1 ? "" : "s") monitored"
    }

    private var shouldUseFamilyActivityPicker: Bool {
        #if os(iOS) && canImport(FamilyControls)
        return viewModel.familyAuthorizationState == .authorized
        #else
        return false
        #endif
    }

    private var fallbackAppChoices: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
            if viewModel.familyAuthorizationState != .notRequested,
               viewModel.familyAuthorizationState != .authorized {
                Text("Screen Time access is required before these labels can lock real apps.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            ForEach(viewModel.appChoices, id: \.self) { app in
                Button {
                    viewModel.toggleMonitoredApp(app)
                } label: {
                    HStack {
                        Text(app)
                            .font(ChildlockTypography.body)
                        Spacer()
                        if viewModel.selectedMonitoredApps.contains(app) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ChildlockColor.primary)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(ChildlockColor.border)
                        }
                    }
                    .foregroundStyle(ChildlockColor.textPrimary)
                    .padding(.horizontal, ChildlockSpacing.md)
                    .frame(height: 48)
                    .background(ChildlockColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChildlockRadius.control)
                            .stroke(ChildlockColor.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("monitor_\(app)")
                .accessibilityLabel(
                    viewModel.selectedMonitoredApps.contains(app)
                        ? "Remove \(app) from monitored apps"
                        : "Add \(app) to monitored apps"
                )
            }
        }
    }

    private var screenTimeAccessButtonTitle: String {
        switch viewModel.familyAuthorizationState {
        case .failed, .unavailable:
            return "Try Screen Time Access Again"
        case .requesting:
            return "Requesting Screen Time..."
        case .notRequested, .authorized:
            return "Allow Screen Time Access"
        }
    }

    private func avatarNameForIndex(_ index: Int) -> String {
        let names = ["fox", "owl", "bear", "bunny", "cat", "dog"]
        guard index < names.count else { return "fox" }
        return names[index]
    }

    // MARK: - Reusable Components

    private func infoCard(number: Int, heading: String, body: String) -> some View {
        HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
            Text("\(number)")
                .font(ChildlockTypography.bodyBold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(ChildlockColor.primary))

            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                Text(heading)
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)
                Text(body)
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
        }
        .childlockCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryRow(icon: String, text: String) -> some View {
        HStack(spacing: ChildlockSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(ChildlockColor.primary)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(ChildlockColor.textSecondary)

            Text(text)
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textPrimary)
        }
    }

    private func deviceStepRow(icon: String, heading: String, body: String) -> some View {
        HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(ChildlockColor.primary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: ChildlockSpacing.xxs) {
                Text(heading)
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)
                Text(body)
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
        }
    }

}

private struct GoogleSignInButtonLabel: View {
    let isInProgress: Bool

    var body: some View {
        HStack(spacing: ChildlockSpacing.sm) {
            ZStack {
                Circle()
                    .fill(ChildlockColor.surface)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(ChildlockColor.border, lineWidth: 1)
                    )

                Text("G")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: "4285F4"))
            }
            .accessibilityHidden(true)

            Text(isInProgress ? "Connecting..." : "Continue with Google")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isInProgress ? "Connecting to Google" : "Continue with Google")
    }
}

// MARK: - Number Pad Key

private enum NumberPadKey {
    case digit(Int)
    case backspace
    case blank
}
