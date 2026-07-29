import SwiftUI

public struct CelebrationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isCelebrating = false

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
                        .scaleEffect(isCelebrating ? 1 : 0.1)
                        .opacity(isCelebrating ? 1 : 0)
                        .rotationEffect(.degrees(isCelebrating ? item.rotation : item.rotation - 50))
                        .position(
                            x: geo.size.width * item.x,
                            y: geo.size.height * item.y
                        )
                        .animation(
                            reduceMotion
                                ? nil
                                : .spring(response: 0.48, dampingFraction: 0.68)
                                    .delay(Double(i) * 0.025),
                            value: isCelebrating
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
                    .scaleEffect(isCelebrating ? 1 : 0.55)
                    .opacity(isCelebrating ? 1 : 0)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.62),
                        value: isCelebrating
                    )

                    Text("Great job!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(ChildlockColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .offset(y: isCelebrating ? 0 : 10)
                        .opacity(isCelebrating ? 1 : 0)
                        .animation(
                            reduceMotion ? nil : .easeOut(duration: 0.3).delay(0.16),
                            value: isCelebrating
                        )

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Correct. Great job.")
        .onAppear {
            isCelebrating = true
        }
    }

    @ViewBuilder
    private func confettiShape(item: (x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double, isCircle: Bool, colorIndex: Int)) -> some View {
        let color = confettiColor(for: item.colorIndex)
        if item.isCircle {
            Circle()
                .fill(color)
                .frame(width: item.size, height: item.size)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: item.size, height: item.size * 0.6)
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
