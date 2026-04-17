import SwiftUI

public struct CelebrationView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: ChildlockSpacing.md) {
            Image(systemName: "star.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(ChildlockColor.accent)

            Text("Awesome!")
                .font(ChildlockTypography.title)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("Screen unlocking…")
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ChildlockColor.background)
    }
}
