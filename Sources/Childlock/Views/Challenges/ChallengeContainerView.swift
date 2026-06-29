import SwiftUI

public struct ChallengeContainerView: View {
    @Bindable private var viewModel: ChallengeViewModel
    private let onParentUnlock: () -> Void

    public init(viewModel: ChallengeViewModel, onParentUnlock: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.onParentUnlock = onParentUnlock
    }

    public var body: some View {
        ZStack {
            ChildlockColor.background.ignoresSafeArea()

            if viewModel.state == .handback {
                HandBackView(childName: viewModel.activeProfile?.name) {
                    onParentUnlock()
                    viewModel.clearChallenge()
                }
            } else if viewModel.state == .completed {
                CelebrationView(solveTimeSeconds: viewModel.lastSolveTimeSeconds)
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
                        PatternChallengeView(
                            challenge: patternChallenge,
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
                        MemoryMatchView(
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
        .onAppear { speakPromptIfNeeded() }
        .onChange(of: viewModel.state) { _, state in
            if state == .completed || state == .handback {
                ChallengeSpeaker.shared.stop()
            }
        }
    }

    private func speakPromptIfNeeded() {
        guard AppState.shared.settings.voicePromptsEnabled else { return }
        guard let prompt = viewModel.challenge?.voicePrompt else { return }
        ChallengeSpeaker.shared.speak(prompt)
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
                    .accessibilityIdentifier("answer_\(answer)")
                    .accessibilityLabel("Answer \(answer)")
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

private struct PatternChallengeView: View {
    let challenge: PatternChallenge
    let hint: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ChildlockSpacing.md) {
            Text("Tap the next one")
                .font(ChildlockTypography.childTitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            HStack(spacing: ChildlockSpacing.xs) {
                ForEach(Array(challenge.sequence.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(ChildlockTypography.childBody)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.7)
                }

                Text("?")
                    .font(ChildlockTypography.childBody)
                    .foregroundStyle(ChildlockColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Pattern \(challenge.sequence.joined(separator: ", ")), question mark")

            VStack(spacing: ChildlockSpacing.xs) {
                ForEach(challenge.allAnswers, id: \.self) { answer in
                    Button {
                        onSelect(answer)
                    } label: {
                        Text(answer)
                            .font(ChildlockTypography.childBody)
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                    }
                    .buttonStyle(ChildlockSecondaryButtonStyle())
                    .accessibilityIdentifier("answer_\(answer)")
                    .accessibilityLabel("Answer \(answer)")
                }
            }

            if let hint {
                Text(hint)
                    .font(ChildlockTypography.caption)
                    .foregroundStyle(Color(hex: "7A5A1A"))
                    .padding(ChildlockSpacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChildlockColor.warnSoft)
                    .clipShape(RoundedRectangle(cornerRadius: ChildlockRadius.md))
            }
        }
        .childlockCard()
    }
}
