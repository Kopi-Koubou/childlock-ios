import SwiftUI
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
        VStack(alignment: .leading, spacing: ChildlockSpacing.lg) {
            VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                Text(viewModel.progressText)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)

                Text(viewModel.step.title)
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)
            }

            stepContent
                .childlockCard()

            VStack(spacing: ChildlockSpacing.sm) {
                if viewModel.canGoBack {
                    Button("Back") {
                        viewModel.goBack()
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                }

                Button(buttonTitle) {
                    viewModel.goNext()
                }
                .buttonStyle(ChildlockPrimaryButtonStyle())
                .disabled(!viewModel.canContinue)
                .opacity(viewModel.canContinue ? 1 : 0.45)
            }
        }
        .padding(ChildlockSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ChildlockColor.background.ignoresSafeArea())
        .onAppear {
            #if os(iOS) && canImport(FamilyControls)
            familyActivitySelection = viewModel.hydrateFamilyActivitySelection()
            #endif
        }
        .onChange(of: viewModel.step) { _, step in
            #if os(iOS) && canImport(FamilyControls)
            guard step == .appSelection else { return }
            familyActivitySelection = viewModel.hydrateFamilyActivitySelection()
            #endif
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.step {
        case .welcome:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Childlock adds quick brain breaks while kids use selected apps.")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Effort unlocks reward. Kids keep screen time by solving friendly challenges.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

        case .familyAuthorization:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Childlock uses Apple’s Family Sharing controls to monitor selected apps and trigger brain breaks.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textPrimary)

                VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                    Text("• We only monitor app usage intervals")
                    Text("• Child names stay local to your device")
                    Text("• You can change this anytime in Settings")
                }
                .font(ChildlockTypography.caption)
                .foregroundStyle(ChildlockColor.textSecondary)

                Button("Authorize Family Sharing") {
                    Task {
                        await viewModel.requestFamilyAuthorization()
                    }
                }
                .buttonStyle(ChildlockSecondaryButtonStyle())
                .disabled(viewModel.familyAuthorizationState == .requesting)

                Text(viewModel.authorizationStatusText)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(viewModel.shouldShowAuthorizationHelp ? ChildlockColor.warning : ChildlockColor.textSecondary)
            }

        case .childProfile:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                    Text("Child name")
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

                Stepper(value: $viewModel.childAge, in: 3...12) {
                    Text("Age: \(viewModel.childAge)")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textPrimary)
                }

                VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                    Text("Choose avatar")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ChildlockSpacing.xs), count: 4), spacing: ChildlockSpacing.xs) {
                        ForEach(viewModel.avatarChoices, id: \.self) { avatar in
                            Button(avatar.capitalized) {
                                viewModel.selectedAvatar = avatar
                            }
                            .buttonStyle(AvatarChoiceButtonStyle(isSelected: viewModel.selectedAvatar == avatar))
                            .accessibilityLabel("avatar_\(avatar)")
                        }
                    }
                }
            }

        case .appSelection:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Choose apps where brain breaks should appear.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textPrimary)
                #if os(iOS) && canImport(FamilyControls)
                VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                    Button("Open Apple App Picker") {
                        isFamilyActivityPickerPresented = true
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .familyActivityPicker(
                        isPresented: $isFamilyActivityPickerPresented,
                        selection: $familyActivitySelection
                    )

                    Text("Selected Scope")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)

                    if viewModel.selectedMonitoredApps.isEmpty {
                        Text("No apps selected yet.")
                            .font(ChildlockTypography.body)
                            .foregroundStyle(ChildlockColor.textSecondary)
                    } else {
                        VStack(alignment: .leading, spacing: ChildlockSpacing.xs) {
                            ForEach(viewModel.selectedMonitoredApps.sorted(), id: \.self) { summary in
                                Text("• \(summary)")
                                    .font(ChildlockTypography.body)
                                    .foregroundStyle(ChildlockColor.textPrimary)
                            }
                        }
                    }

                    if viewModel.familyAuthorizationState == .authorized, viewModel.selectedActivityTokenData == nil {
                        Text("Use Apple App Picker to select at least one app or category.")
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.warning)
                    }
                }
                .onChange(of: familyActivitySelection) { _, selection in
                    viewModel.updateFamilyActivitySelection(selection)
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
                                        .foregroundStyle(ChildlockColor.accent)
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

                Text("Tip: Skip educational apps that already encourage active learning.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

        case .interval:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Recommended: 15 minutes")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)

                HStack(spacing: ChildlockSpacing.xs) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { interval in
                        Button("\(interval)m") {
                            viewModel.selectedInterval = interval
                        }
                        .buttonStyle(IntervalButtonStyle(isSelected: viewModel.selectedInterval == interval))
                    }
                }

                Text("A challenge appears every \(viewModel.selectedInterval) minutes while monitored apps are active.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

        case .pin:
            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Set a 4-digit PIN")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                SecureField("PIN", text: $viewModel.pin)
                    .pinInputBehavior()
                    .font(ChildlockTypography.body)
                    .padding(.horizontal, ChildlockSpacing.sm)
                    .frame(height: 44)
                    .background(ChildlockColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChildlockRadius.control)
                            .stroke(ChildlockColor.border, lineWidth: 1)
                    )

                SecureField("Confirm PIN", text: $viewModel.pinConfirmation)
                    .pinInputBehavior()
                    .font(ChildlockTypography.body)
                    .padding(.horizontal, ChildlockSpacing.sm)
                    .frame(height: 44)
                    .background(ChildlockColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: ChildlockRadius.control)
                            .stroke(ChildlockColor.border, lineWidth: 1)
                    )

                Text("This protects settings from children.")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }

        case .complete:
            VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                Text("Childlock is now active.")
                    .font(ChildlockTypography.subtitle)
                    .foregroundStyle(ChildlockColor.textPrimary)

                Text("Your child will see their first brain break in \(viewModel.selectedInterval) minutes while using monitored apps.")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
        }
    }

    private var buttonTitle: String {
        switch viewModel.step {
        case .pin:
            return "Finish Setup"
        case .complete:
            return "Go To Dashboard"
        default:
            return "Continue"
        }
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

private struct IntervalButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ChildlockTypography.caption)
            .foregroundStyle(ChildlockColor.textPrimary)
            .frame(minWidth: 48, minHeight: 44)
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

private struct AvatarChoiceButtonStyle: ButtonStyle {
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
