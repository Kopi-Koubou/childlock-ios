import SwiftUI

/// Shown after a completed challenge. Keeps the child out of the parent
/// dashboard: the cover only dismisses after a parent enters the PIN.
/// The child returns to their now-unshielded app with the system app-switch
/// gesture, which preserves the activity that was on screen before Childlock.
/// iOS does not let Screen Time apps automatically reopen arbitrary third-party
/// apps or restore media state, so the visible cue stays gesture-first and brief.
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

            Text("Great job!")
                .font(ChildlockTypography.childTitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("Swipe back")
                .font(ChildlockTypography.childBody)
                .foregroundStyle(ChildlockColor.textSecondary)

            HandBackReturnCue(iconName: "arrow.right")
                .accessibilityIdentifier("handback_resume_guidance")
                .accessibilityLabel("Swipe back to your app.")
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 96, height: 96)
            .background(ChildlockColor.primary)
            .clipShape(Circle())
            .childlockShadow(ChildlockShadow.sm)
            .offset(x: reduceMotion ? 0 : (isAnimating ? 12 : -8))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Swipe right along the bottom edge to return to the app you were using.")
    }
}
