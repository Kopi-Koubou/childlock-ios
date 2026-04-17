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
            Text(challenge.instruction)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text(challenge.expression)
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(ChildlockColor.textPrimary)

            LazyVGrid(columns: gridColumns, spacing: ChildlockSpacing.sm) {
                ForEach(challenge.allAnswers, id: \.self) { answer in
                    Button {
                        onAnswer(answer)
                    } label: {
                        Text("\(answer)")
                            .font(ChildlockTypography.subtitle)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 60)
                    }
                    .buttonStyle(AnswerButtonStyle())
                    .accessibilityLabel("answer_\(answer)")
                }
            }

            if hintVisible {
                Text("Hint: \(challenge.hintText)")
                    .font(ChildlockTypography.body)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .padding(ChildlockSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChildlockColor.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.control))
            }
        }
    }

    private var gridColumns: [GridItem] {
        let count = challenge.allAnswers.count >= 4 ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: ChildlockSpacing.sm), count: count)
    }
}

private struct AnswerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(ChildlockColor.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .fill(ChildlockColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ChildlockRadius.control)
                    .stroke(ChildlockColor.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
