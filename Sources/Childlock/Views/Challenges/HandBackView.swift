import SwiftUI

/// Shown after a completed challenge. Keeps the child out of the parent
/// dashboard: the cover only dismisses after a parent enters the PIN.
/// The child returns to their now-unshielded app from Home or the app switcher.
/// iOS does not let Screen Time apps automatically reopen arbitrary third-party
/// apps or restore media state, so the visible copy stays icon-first and brief.
public struct HandBackView: View {
    private let childName: String?
    private let onParentUnlock: () -> Void
    private let pinService: PINService

    @State private var enteredPIN = ""
    @State private var pinErrorText: String?
    @State private var isParentUnlockPresented = false
    private let handBackContentMaxWidth: CGFloat = 560

    public init(
        childName: String? = nil,
        pinService: PINService? = nil,
        onParentUnlock: @escaping () -> Void
    ) {
        self.childName = childName
        self.pinService = pinService ?? .shared
        self.onParentUnlock = onParentUnlock
    }

    public var body: some View {
        VStack(spacing: ChildlockSpacing.lg) {
            Spacer()

            Text("Done")
                .font(ChildlockTypography.childTitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            HandBackReturnCue(iconName: "arrow.backward")
                .accessibilityIdentifier("handback_resume_guidance")
                .accessibilityLabel("Back.")
                .padding(.top, ChildlockSpacing.xs)

            Spacer()

            Button {
                isParentUnlockPresented = true
            } label: {
                Image(systemName: "lock.fill")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .frame(width: 44, height: 40)
                    .background(ChildlockColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))
                    .childlockShadow(ChildlockShadow.sm)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("parent_unlock_entry")
            .accessibilityLabel("Parent unlock")
        }
        .frame(maxWidth: handBackContentMaxWidth)
        .padding(ChildlockSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background.ignoresSafeArea())
        .sheet(isPresented: $isParentUnlockPresented) {
            parentUnlockSheet
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: enteredPIN) { _, _ in
            sanitizeEnteredPIN()
            if !enteredPIN.isEmpty {
                pinErrorText = nil
            }
        }
    }

    private var parentUnlockSheet: some View {
        VStack(spacing: ChildlockSpacing.md) {
            Text("Parent PIN")
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            SecureField("Parent PIN", text: $enteredPIN)
                .pinInputBehavior()
                .textFieldStyle(.plain)
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textPrimary)
                .tint(ChildlockColor.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, ChildlockSpacing.sm)
                .frame(height: 48)
                .background(ChildlockColor.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: ChildlockRadius.control)
                        .stroke(ChildlockColor.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))

            if let pinErrorText {
                Text(pinErrorText)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.warning)
            }

            Button("Unlock Dashboard") {
                if pinService.verify(enteredPIN) {
                    pinErrorText = nil
                    isParentUnlockPresented = false
                    onParentUnlock()
                } else {
                    pinErrorText = "Incorrect PIN. Try again."
                    enteredPIN = ""
                }
            }
            .buttonStyle(ChildlockPrimaryButtonStyle())
            .disabled(enteredPIN.count < 4)
            .opacity(enteredPIN.count < 4 ? 0.5 : 1)
        }
        .padding(ChildlockSpacing.lg)
        .frame(maxWidth: handBackContentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background.ignoresSafeArea())
    }

    private func sanitizeEnteredPIN() {
        let sanitized = String(enteredPIN.filter(\.isNumber).prefix(4))
        if enteredPIN != sanitized {
            enteredPIN = sanitized
        }
    }
}

private struct HandBackReturnCue: View {
    let iconName: String

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 96, height: 96)
            .background(ChildlockColor.primary)
            .clipShape(Circle())
            .childlockShadow(ChildlockShadow.sm)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Use Home or the app switcher.")
    }
}
