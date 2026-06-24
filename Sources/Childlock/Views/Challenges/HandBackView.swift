import SwiftUI

/// Shown after a completed challenge. Keeps the child out of the parent
/// dashboard: the cover only dismisses after a parent enters the PIN.
/// The child just presses home or swipes up and returns to their now-unshielded
/// app. iOS does not let Screen Time apps automatically reopen that app.
public struct HandBackView: View {
    private let childName: String?
    private let onParentUnlock: () -> Void
    private let pinService: PINService

    @State private var enteredPIN = ""
    @State private var pinErrorText: String?
    @State private var isParentSectionVisible = false

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

            Text("Swipe up or press Home, then reopen your video or app. It's unlocked.")
                .font(ChildlockTypography.childBody)
                .foregroundStyle(ChildlockColor.textSecondary)
                .multilineTextAlignment(.center)

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
