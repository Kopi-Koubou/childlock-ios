import SwiftUI

/// Shown after a completed challenge. Keeps the child out of the parent
/// dashboard: the cover only dismisses after a parent enters the PIN.
/// The child presses Home or swipes up, then returns to their now-unshielded
/// app. iOS does not let Screen Time apps automatically reopen arbitrary
/// third-party apps or restore media state, so this screen makes the required
/// hand-back feel like the final resume step rather than a technical caveat.
public struct HandBackView: View {
    private let childName: String?
    private let onParentUnlock: () -> Void
    private let pinService: PINService

    @State private var enteredPIN = ""
    @State private var pinErrorText: String?
    @State private var isParentSectionVisible = false
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

            ZStack {
                Circle()
                    .fill(ChildlockColor.primarySoft)
                    .frame(width: 96, height: 96)
                Image(systemName: "play.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(ChildlockColor.primary)
            }

            Text("All done\(childName.map { ", \($0)" } ?? "")!")
                .font(ChildlockTypography.childTitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            HandBackReturnCue(
                iconName: "arrow.up",
                title: "Swipe up"
            )
            .accessibilityIdentifier("handback_resume_guidance")
            .accessibilityLabel("Swipe up to go back.")
            .padding(.top, ChildlockSpacing.xs)

            Spacer()

            if isParentSectionVisible {
                VStack(spacing: ChildlockSpacing.sm) {
                    SecureField("Parent PIN", text: $enteredPIN)
                        .pinInputBehavior()
                        .font(ChildlockTypography.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, ChildlockSpacing.sm)
                        .frame(height: 44)
                        .background(ChildlockColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))

                    if let pinErrorText {
                        Text(pinErrorText)
                            .font(ChildlockTypography.caption)
                            .foregroundStyle(ChildlockColor.warning)
                    }

                    Button("Unlock Dashboard") {
                        if pinService.verify(enteredPIN) {
                            pinErrorText = nil
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
            } else {
                Button {
                    isParentSectionVisible = true
                } label: {
                    Label("I'm a parent", systemImage: "lock.fill")
                        .font(ChildlockTypography.caption)
                        .foregroundStyle(ChildlockColor.textSecondary)
                        .padding(.horizontal, ChildlockSpacing.md)
                        .frame(height: 40)
                        .background(ChildlockColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))
                        .childlockShadow(ChildlockShadow.sm)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("parent_unlock_entry")
                .accessibilityLabel("I'm a parent")
            }
        }
        .frame(maxWidth: handBackContentMaxWidth)
        .padding(ChildlockSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background.ignoresSafeArea())
        .onChange(of: enteredPIN) { _, _ in
            sanitizeEnteredPIN()
            if !enteredPIN.isEmpty {
                pinErrorText = nil
            }
        }
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
    let title: String

    var body: some View {
        VStack(spacing: ChildlockSpacing.sm) {
            Image(systemName: iconName)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(ChildlockColor.primary)
                .clipShape(Circle())
                .childlockShadow(ChildlockShadow.sm)

            Text(title)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, ChildlockSpacing.lg)
        .padding(.horizontal, ChildlockSpacing.md)
        .frame(maxWidth: .infinity)
        .background(ChildlockColor.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))
        .overlay {
            RoundedRectangle(cornerRadius: ChildlockRadius.control)
                .stroke(ChildlockColor.primary.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
