import SwiftUI

public struct ChallengeContainerView: View {
    @Bindable private var viewModel: ChallengeViewModel

    public init(viewModel: ChallengeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            ChildlockColor.background.ignoresSafeArea()

            if viewModel.state == .completed {
                CelebrationView()
            } else {
                VStack(spacing: ChildlockSpacing.md) {
                    // Brain Break pill
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ChildlockColor.primary)
                            .frame(width: 6, height: 6)
                        Text("Brain Break")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(0.4)
                            .foregroundStyle(ChildlockColor.primaryDeep)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ChildlockColor.primarySoft)
                    .clipShape(RoundedRectangle(cornerRadius: 999))

                    if let mathChallenge = viewModel.challenge as? MathChallenge {
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
                HStack(alignment: .top, spacing: ChildlockSpacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color(hex: "7A5A1A"))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hint")
                            .font(ChildlockTypography.bodyBold)
                            .foregroundStyle(Color(hex: "7A5A1A"))
                        Text(hint)
                            .font(ChildlockTypography.body)
                            .foregroundStyle(Color(hex: "7A5A1A"))
                    }
                }
                .padding(ChildlockSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ChildlockColor.warnSoft)
                .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.card))
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
