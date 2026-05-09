import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if os(iOS) && canImport(FamilyControls)
import FamilyControls
#endif

public struct OnboardingFlowView: View {
    @Bindable private var viewModel: OnboardingViewModel
    #if os(iOS) && canImport(FamilyControls)
    @State private var isFamilyActivityPickerPresented = false
    @State private var familyActivitySelection = FamilyActivitySelection()
    #endif

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
                innerStep { setupStep }
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
            // Top bar: back button + step indicator
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

            ScrollView {
                VStack(alignment: .leading, spacing: ChildlockSpacing.lg) {
                    content()
                }
                .padding(.horizontal, ChildlockSpacing.lg)
                .padding(.bottom, ChildlockSpacing.section)
            }
        }
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
            Spacer()

            // Hero illustration
            ZStack {
                RoundedRectangle(cornerRadius: ChildlockRadius.xl)
                    .fill(ChildlockColor.primarySoft)
                    .frame(height: 220)

                // Layered geometric shapes
                ZStack {
                    // Arch shape
                    UnevenRoundedRectangle(
                        topLeadingRadius: 60,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 60
                    )
                    .fill(ChildlockColor.accent.opacity(0.6))
                    .frame(width: 100, height: 130)
                    .offset(y: 20)

                    // Circle
                    Circle()
                        .fill(ChildlockColor.warnSoft)
                        .frame(width: 70, height: 70)
                        .offset(x: 50, y: -30)
                }
            }
            .padding(.horizontal, ChildlockSpacing.lg)

            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Turn screen time into brain time.")
                    .font(ChildlockTypography.display)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Quick brain breaks during your child's screen time. Calmer transitions, real learning, no tantrums.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
            .padding(.horizontal, ChildlockSpacing.lg)

            Spacer()

            VStack(spacing: ChildlockSpacing.sm) {
                #if canImport(AuthenticationServices)
                SignInWithAppleButtonView(
                    onSuccess: { userID, email, fullName in
                        AuthService.shared.handleSignIn(userID: userID, email: email, fullName: fullName)
                        viewModel.goNext()
                    },
                    onError: { _ in
                        // User cancelled or auth failed — stay on welcome
                    }
                )
                #else
                Button {
                    AuthService.shared.handleSignIn(userID: "dev-user", email: nil, fullName: nil)
                    viewModel.goNext()
                } label: {
                    HStack(spacing: ChildlockSpacing.xs) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18, weight: .medium))
                        Text("Continue with Apple")
                    }
                }
                .buttonStyle(ChildlockPrimaryButtonStyle())
                #endif

                Button {
                    viewModel.goNext()
                } label: {
                    Text("Sign in with email")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.primary)
                }

                Text("7-day free trial \u{00B7} then $39.99/year \u{00B7} cancel anytime")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, ChildlockSpacing.lg)
            .padding(.bottom, ChildlockSpacing.lg)
        }
    }

    // MARK: - Family Sharing (Step 2)

    private var familySharingStep: some View {
        Group {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Apple's Family Sharing keeps your child's data private and gives you full control.")
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
                body: "On-device. Only you see your dashboard."
            )

            Text(viewModel.authorizationStatusText)
                .font(ChildlockTypography.caption)
                .foregroundStyle(viewModel.shouldShowAuthorizationHelp ? ChildlockColor.warning : ChildlockColor.textSecondary)

            VStack(spacing: ChildlockSpacing.sm) {
                Button("Set up Family Sharing") {
                    Task {
                        await viewModel.requestFamilyAuthorization()
                    }
                }
                .buttonStyle(ChildlockPrimaryButtonStyle())
                .disabled(viewModel.familyAuthorizationState == .requesting)

                Button {
                    viewModel.goNext()
                } label: {
                    Text("Try a demo first")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.primary)
                }
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

                Text("Family Sharing syncs your settings across every device in your family group.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

            // Visual diagram: parent -> cloud -> children
            VStack(spacing: ChildlockSpacing.md) {
                // Parent device
                HStack {
                    Spacer()
                    deviceRect(label: "Your device", icon: "iphone", highlighted: true)
                    Spacer()
                }

                // Arrow down
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ChildlockColor.primary)

                // Cloud
                HStack {
                    Spacer()
                    VStack(spacing: ChildlockSpacing.xxs) {
                        Image(systemName: "icloud.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(ChildlockColor.primary)
                        Text("Family Sharing")
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.textSecondary)
                    }
                    Spacer()
                }

                // Arrow down
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(ChildlockColor.primary)

                // Child devices
                HStack(spacing: ChildlockSpacing.md) {
                    Spacer()
                    deviceRect(label: "iPad", icon: "ipad", highlighted: false)
                    deviceRect(label: "iPhone", icon: "iphone", highlighted: false)
                    Spacer()
                }
            }
            .childlockCard()

            // Devices found placeholder
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text("Devices found")
                    .font(ChildlockTypography.bodyBold)
                    .foregroundStyle(ChildlockColor.textPrimary)

                HStack(spacing: ChildlockSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ChildlockColor.primary)
                    Text("This device")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textPrimary)
                }
            }
            .childlockCard()
            .frame(maxWidth: .infinity, alignment: .leading)

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

                    TextField("Mia", text: $viewModel.childName)
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
                                .accessibilityLabel("avatar_\(avatarName)")
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

                #if os(iOS) && canImport(FamilyControls)
                VStack(spacing: ChildlockSpacing.xs) {
                    appToggleRow(label: "Video", icon: "play.rectangle.fill") {
                        isFamilyActivityPickerPresented = true
                    }
                    appToggleRow(label: "Games", icon: "gamecontroller.fill") {
                        isFamilyActivityPickerPresented = true
                    }
                    appToggleRow(label: "Social", icon: "person.2.fill") {
                        isFamilyActivityPickerPresented = true
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
                #else
                VStack(spacing: ChildlockSpacing.xs) {
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
                        .accessibilityLabel("monitor_\(app)")
                    }
                }
                #endif
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

            Button("Continue") {
                viewModel.goNext()
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.45)
        }
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

    private func deviceRect(label: String, icon: String, highlighted: Bool) -> some View {
        VStack(spacing: ChildlockSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(highlighted ? ChildlockColor.primary : ChildlockColor.textMuted)

            Text(label)
                .font(ChildlockTypography.caption)
                .foregroundStyle(highlighted ? ChildlockColor.textPrimary : ChildlockColor.textSecondary)
        }
        .frame(width: 80, height: 80)
        .background(
            RoundedRectangle(cornerRadius: ChildlockRadius.sm)
                .fill(highlighted ? ChildlockColor.primarySoft : ChildlockColor.surfaceMuted)
        )
    }

    private func appToggleRow(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(ChildlockColor.primary)
                    .frame(width: 28)

                Text(label)
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ChildlockColor.textMuted)
            }
            .padding(.horizontal, ChildlockSpacing.md)
            .frame(height: 48)
            .background(ChildlockColor.surface)
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .stroke(ChildlockColor.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Number Pad Key

private enum NumberPadKey {
    case digit(Int)
    case backspace
    case blank
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
