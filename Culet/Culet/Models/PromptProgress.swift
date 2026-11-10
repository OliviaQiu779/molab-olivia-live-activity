import Foundation

/// Small, serializable progress shared by the app and Live Activity intents.
/// History survives direction changes and relaunches without sending the library.
struct PromptProgress: Codable, Hashable {
    var promptIndex: Int
    var kind: PromptKind
    private(set) var seenIndices: [Int]

    init(promptIndex: Int, kind: PromptKind, seenIndices: [Int]? = nil) {
        self.promptIndex = promptIndex
        self.kind = kind
        self.seenIndices = seenIndices ?? [promptIndex]
    }

    private enum CodingKeys: String, CodingKey { case promptIndex, kind, seenIndices }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        promptIndex = try container.decode(Int.self, forKey: .promptIndex)
        kind = try container.decode(PromptKind.self, forKey: .kind)
        seenIndices = try container.decodeIfPresent([Int].self, forKey: .seenIndices) ?? [promptIndex]
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
