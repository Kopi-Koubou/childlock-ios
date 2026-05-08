import SwiftUI

public struct MathChallengeView: View {
    public let challenge: MathChallenge
    public let hintVisible: Bool
    public let onAnswer: (Int) -> Void

    public init(
        challenge: MathChallenge,
        hintVisible: Bool,
        onAnswer: @escaping (Int) -> Void
    ) {
        self.challenge = challenge
        self.hintVisible = hintVisible
        self.onAnswer = onAnswer
    }

    public var body: some View {
        VStack(spacing: ChildlockSpacing.lg) {
            Text(challenge.expression)
                .font(ChildlockTypography.childDisplay)
                .foregroundStyle(ChildlockColor.textPrimary)
                .frame(maxWidth: .infinity)

            LazyVGrid(columns: gridColumns, spacing: ChildlockSpacing.sm) {
                ForEach(challenge.allAnswers, id: \.self) { answer in
                    Button {
                        onAnswer(answer)
                    } label: {
                        Text("\(answer)")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: answerButtonHeight)
                    }
                    .buttonStyle(AnswerButtonStyle())
                    .accessibilityLabel("answer_\(answer)")
                }
            }

            if hintVisible {
                HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color(hex: "7A5A1A"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Try counting up")
                            .font(ChildlockTypography.bodyBold)
                            .foregroundStyle(Color(hex: "7A5A1A"))
                        Text(challenge.hintText)
                            .font(ChildlockTypography.body)
                            .foregroundStyle(Color(hex: "7A5A1A"))
                    }
                }
                .padding(ChildlockSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ChildlockColor.warnSoft)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
            }

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<10, id: \.self) { index in
                    Circle()
                        .fill(index < 1 ? ChildlockColor.primary : ChildlockColor.textFaint.opacity(0.5))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        let count = challenge.allAnswers.count >= 4 ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: ChildlockSpacing.sm), count: count)
    }

    private var answerButtonHeight: CGFloat {
        challenge.allAnswers.count >= 4 ? 70 : 90
    }
}

private struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ChildlockColor.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.card)
                    .fill(ChildlockColor.surface)
                    .childlockShadow(ChildlockShadow.sm)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
