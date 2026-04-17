import SwiftUI

public struct ChallengeContainerView: View {
    @Bindable private var viewModel: ChallengeViewModel

    public init(viewModel: ChallengeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            ChildlockColor.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
                Text("Brain Break!")
                    .font(ChildlockTypography.title)
                    .foregroundStyle(ChildlockColor.textPrimary)

                if viewModel.state == .completed {
                    CelebrationView()
                } else if let mathChallenge = viewModel.challenge as? MathChallenge {
                    MathChallengeView(
                        challenge: mathChallenge,
                        hintVisible: viewModel.hintVisible,
                        onAnswer: viewModel.submitMathAnswer
                    )
                } else if let patternChallenge = viewModel.challenge as? PatternChallenge {
                    MultipleChoiceTextChallengeView(
                        instruction: patternChallenge.instruction,
                        prompt: patternChallenge.sequence.joined(separator: "  ") + "  ?",
                        answers: patternChallenge.allAnswers,
                        hint: viewModel.hintVisible ? patternChallenge.hintText : nil,
                        onSelect: viewModel.submitPatternAnswer
                    )
                } else if let puzzleChallenge = viewModel.challenge as? PuzzleChallenge {
                    MultipleChoiceTextChallengeView(
                        instruction: puzzleChallenge.instruction,
                        prompt: puzzleChallenge.prompt,
                        answers: puzzleChallenge.allAnswers,
                        hint: viewModel.hintVisible ? puzzleChallenge.hintText : nil,
                        onSelect: viewModel.submitPuzzleAnswer
                    )
                } else if let memoryChallenge = viewModel.challenge as? MemoryChallenge {
                    MemoryChallengeSummaryView(
                        challenge: memoryChallenge,
                        onComplete: viewModel.submitMemoryCompletion
                    )
                } else {
                    VStack(alignment: .leading, spacing: ChildlockSpacing.sm) {
                        Text("Challenge loading")
                            .font(ChildlockTypography.subtitle)
                            .foregroundStyle(ChildlockColor.textPrimary)
                        Text("Please wait a moment.")
                            .font(ChildlockTypography.body)
                            .foregroundStyle(ChildlockColor.textSecondary)
                    }
                    .childlockCard()
                }

                if let feedbackText = viewModel.feedbackText,
                   viewModel.state == .incorrect || viewModel.state == .correct {
                    Text(feedbackText)
                        .font(ChildlockTypography.body)
                        .foregroundStyle(viewModel.state == .correct ? ChildlockColor.success : ChildlockColor.warning)
                        .padding(.horizontal, ChildlockSpacing.xs)
                }
            }
            .padding(ChildlockSpacing.lg)
        }
    }
}

private struct MultipleChoiceTextChallengeView: View {
    let instruction: String
    let prompt: String
    let answers: [String]
    let hint: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
            Text(instruction)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text(prompt)
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)

            VStack(spacing: ChildlockSpacing.xs) {
                ForEach(answers, id: \.self) { answer in
                    Button(answer) {
                        onSelect(answer)
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .accessibilityLabel("answer_\(answer)")
                }
            }

            if let hint {
                Text("Hint: \(hint)")
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(ChildlockColor.textSecondary)
            }
        }
        .childlockCard()
    }
}

private struct MemoryChallengeSummaryView: View {
    let challenge: MemoryChallenge
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
            Text(challenge.instruction)
                .font(ChildlockTypography.subtitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("Match \(challenge.pairCount) pairs")
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)

            Text(challenge.symbols.joined(separator: "  "))
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .padding(.vertical, ChildlockSpacing.xs)

            Button("I Matched All Pairs", action: onComplete)
                .buttonStyle(ChildlockPrimaryButtonStyle())
                .accessibilityLabel("memory_complete")
        }
        .childlockCard()
    }
}
