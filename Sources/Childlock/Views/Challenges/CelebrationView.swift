import SwiftUI

public struct CelebrationView: View {
    public init() {}

    private let confettiItems: [(x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double, isCircle: Bool, colorIndex: Int)] = {
        var items: [(CGFloat, CGFloat, CGFloat, Double, Bool, Int)] = []
        let positions: [(CGFloat, CGFloat)] = [
            (0.12, 0.10), (0.85, 0.08), (0.25, 0.22), (0.78, 0.18),
            (0.08, 0.35), (0.92, 0.30), (0.18, 0.55), (0.88, 0.50),
            (0.30, 0.72), (0.72, 0.68), (0.15, 0.82), (0.82, 0.78)
        ]
        for (i, pos) in positions.enumerated() {
            let size: CGFloat = CGFloat(6 + (i % 3) * 2)
            let rotation = Double(i * 30)
            let isCircle = i % 2 == 0
            let colorIndex = i % 3
            items.append((pos.0, pos.1, size, rotation, isCircle, colorIndex))
        }
        return items
    }()

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ChildlockColor.background.ignoresSafeArea()

                // Confetti particles
                ForEach(0..<confettiItems.count, id: \.self) { i in
                    let item = confettiItems[i]
                    confettiShape(item: item)
                        .position(
                            x: geo.size.width * item.x,
                            y: geo.size.height * item.y
                        )
                }

                // Center content
                VStack(spacing: ChildlockSpacing.lg) {
                    Spacer()

                    // Checkmark circle
                    ZStack {
                        Circle()
                            .fill(ChildlockColor.accentSoft)
                            .frame(width: 96, height: 96)
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ChildlockColor.accent)
                    }

                    Text("Nailed it!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(ChildlockColor.textPrimary)

                    Text("Solved in 12 seconds.")
                        .font(ChildlockTypography.body)
                        .foregroundStyle(ChildlockColor.textMuted)

                    Spacer()

                    // Back in 3 pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ChildlockColor.primary)
                            .frame(width: 6, height: 6)
                        Text("Back in 3...")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ChildlockColor.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(ChildlockColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 999))
                    .childlockShadow(ChildlockShadow.sm)
                    .padding(.bottom, ChildlockSpacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func confettiShape(item: (x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double, isCircle: Bool, colorIndex: Int)) -> some View {
        let color = confettiColor(for: item.colorIndex)
        if item.isCircle {
            Circle()
                .fill(color)
                .frame(width: item.size, height: item.size)
                .rotationEffect(.degrees(item.rotation))
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: item.size, height: item.size * 0.6)
                .rotationEffect(.degrees(item.rotation))
        }
    }

    private func confettiColor(for index: Int) -> Color {
        switch index {
        case 0: return ChildlockColor.primary
        case 1: return ChildlockColor.accent
        default: return ChildlockColor.warning
        }
    }
}
