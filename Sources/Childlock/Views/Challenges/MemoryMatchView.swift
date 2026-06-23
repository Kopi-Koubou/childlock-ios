import SwiftUI

/// A real card-matching game: all cards start face down, the child flips two
/// at a time, and the challenge completes only when every pair is matched.
public struct MemoryMatchView: View {
    private struct Card: Identifiable {
        let id = UUID()
        let symbol: String
    }

    private let challenge: MemoryChallenge
    private let onComplete: () -> Void

    @State private var cards: [Card] = []
    @State private var faceUpIndices: [Int] = []
    @State private var matchedIDs: Set<UUID> = []
    @State private var isResolvingMismatch = false

    public init(challenge: MemoryChallenge, onComplete: @escaping () -> Void) {
        self.challenge = challenge
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: ChildlockSpacing.md) {
            Text(challenge.instruction)
                .font(ChildlockTypography.childTitle)
                .foregroundStyle(ChildlockColor.textPrimary)

            Text("\(matchedIDs.count / 2) of \(challenge.pairCount) pairs found")
                .font(ChildlockTypography.body)
                .foregroundStyle(ChildlockColor.textSecondary)

            LazyVGrid(columns: gridColumns, spacing: ChildlockSpacing.xs) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    cardView(card: card, index: index)
                }
            }
        }
        .onAppear {
            if cards.isEmpty {
                cards = initialCards()
            }
        }
    }

    private func initialCards() -> [Card] {
        let pairedSymbols = challenge.symbols.flatMap { [$0, $0] }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--childlock-qa-seed-pending-memory-challenge") {
            return pairedSymbols.map { Card(symbol: $0) }
        }
        #endif

        return pairedSymbols
            .map { Card(symbol: $0) }
            .shuffled()
    }

    private var gridColumns: [GridItem] {
        let columnCount = cards.count > 12 ? 4 : 3
        return Array(
            repeating: GridItem(.flexible(), spacing: ChildlockSpacing.xs),
            count: columnCount
        )
    }

    private func cardView(card: Card, index: Int) -> some View {
        let isFaceUp = faceUpIndices.contains(index) || matchedIDs.contains(card.id)
        let isMatched = matchedIDs.contains(card.id)

        return Button {
            flipCard(at: index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: ChildlockRadius.md)
                    .fill(isFaceUp ? ChildlockColor.surface : ChildlockColor.memory.opacity(0.55))
                    .childlockShadow(ChildlockShadow.sm)

                if isFaceUp {
                    Text(card.symbol)
                        .font(.system(size: 30))
                } else {
                    Image(systemName: "questionmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(height: 64)
            .opacity(isMatched ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.2), value: isFaceUp)
        }
        .buttonStyle(.plain)
        .disabled(isFaceUp || isResolvingMismatch)
        .accessibilityIdentifier("memory_card_\(index)")
        .accessibilityLabel(memoryCardAccessibilityLabel(index: index, isFaceUp: isFaceUp, isMatched: isMatched))
    }

    private func memoryCardAccessibilityLabel(index: Int, isFaceUp: Bool, isMatched: Bool) -> String {
        let position = index + 1

        if isMatched {
            return "Memory card \(position), matched"
        }

        if isFaceUp {
            return "Memory card \(position), revealed"
        }

        return "Memory card \(position), hidden"
    }

    private func flipCard(at index: Int) {
        guard !isResolvingMismatch else { return }
        guard !faceUpIndices.contains(index) else { return }
        guard !matchedIDs.contains(cards[index].id) else { return }

        faceUpIndices.append(index)
        guard faceUpIndices.count == 2 else { return }

        let first = cards[faceUpIndices[0]]
        let second = cards[faceUpIndices[1]]

        if first.symbol == second.symbol {
            matchedIDs.insert(first.id)
            matchedIDs.insert(second.id)
            faceUpIndices = []

            if matchedIDs.count == cards.count {
                onComplete()
            }
        } else {
            isResolvingMismatch = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 800_000_000)
                faceUpIndices = []
                isResolvingMismatch = false
            }
        }
    }
}
