import Foundation

/// Small, serializable progress shared by the app and Live Activity intents.
/// History survives direction changes and relaunches without sending the library.
struct PromptProgress: Codable, Hashable {
    var promptIndex: Int
    var kind: PromptKind
    var isPromptSaved = false
    private var timedDirection: PromptKind = .open
    private(set) var seenIndices: [Int]

    init(promptIndex: Int, kind: PromptKind, seenIndices: [Int]? = nil) {
        self.promptIndex = promptIndex
        self.kind = kind
        self.seenIndices = seenIndices ?? [promptIndex]
    }

    private enum CodingKeys: String, CodingKey { case promptIndex, kind, seenIndices, isPromptSaved, timedDirection }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        promptIndex = try container.decode(Int.self, forKey: .promptIndex)
        kind = try container.decode(PromptKind.self, forKey: .kind)
        isPromptSaved = try container.decodeIfPresent(Bool.self, forKey: .isPromptSaved) ?? false
        timedDirection = try container.decodeIfPresent(PromptKind.self, forKey: .timedDirection) ?? .open
        seenIndices = try container.decodeIfPresent([Int].self, forKey: .seenIndices) ?? [promptIndex]
    }

    private static func transitions(from start: Date, until end: Date) -> [(date: Date, kind: PromptKind)] {
        let duration = end.timeIntervalSince(start)
        return [
            (start.addingTimeInterval(duration / 6), .explore),
            (start.addingTimeInterval(duration * 5 / 6), .wrapUp)
        ]
    }

    func nextTransition(from start: Date, until end: Date) -> Date {
        let transitions = Self.transitions(from: start, until: end)
        switch timedDirection {
        case .open: return transitions[0].date
        case .explore: return transitions[1].date
        case .wrapUp: return end
        }
    }

    /// Keeps a manually selected direction until the next scheduled transition.
    @discardableResult
    mutating func applyTimedDirection(in deck: [ConversationPrompt], from start: Date,
                                     until end: Date, now: Date = .now) -> Bool {
        guard now < end,
              let direction = Self.transitions(from: start, until: end).last(where: { $0.date <= now })?.kind,
              direction != timedDirection, timedDirection != .wrapUp else { return false }

        timedDirection = direction
        guard direction != kind else { return false }
        advance(in: deck, to: direction)
        return true
    }

    mutating func normalize(in deck: [ConversationPrompt]) {
        guard !deck.isEmpty else { promptIndex = 0; seenIndices = []; return }
        if !deck.indices.contains(promptIndex) || deck[promptIndex].kind != kind {
            promptIndex = deck.firstIndex { $0.kind == kind } ?? 0
        }
        var seen = Set<Int>()
        seenIndices = seenIndices.filter { deck.indices.contains($0) && seen.insert($0).inserted }
        if !seenIndices.contains(promptIndex) { seenIndices.append(promptIndex) }
    }

    mutating func advance(in deck: [ConversationPrompt], to selectedKind: PromptKind? = nil) {
        normalize(in: deck)
        guard !deck.isEmpty else { return }
        let selected = selectedKind ?? kind
        let candidates = deck.indices.filter { deck[$0].kind == selected }
        guard !candidates.isEmpty else { return }
        if candidates.allSatisfy({ seenIndices.contains($0) }) {
            // Only reset the exhausted direction. Preserve progress in the others.
            seenIndices.removeAll { candidates.contains($0) }
        }
        for offset in 1...deck.count {
            let candidate = (promptIndex + offset) % deck.count
            if deck[candidate].kind == selected && !seenIndices.contains(candidate) {
                promptIndex = candidate
                kind = selected
                seenIndices.append(candidate)
                return
            }
        }
    }
}
