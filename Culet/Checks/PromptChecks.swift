import Foundation

@main
struct PromptChecks {
    static func main() throws {
        let scenes = SituationLibrary.all + [Situation.custom("Book club", id: "custom-check")]
        var builtInTexts = Set<String>()
        for scene in scenes {
            let deck = PromptLibrary.deck(for: scene)
            precondition(deck.count == 24, "Every scene needs 24 prompts")
            precondition(Set(deck.map(\.id)).count == 24)
            precondition(PromptLibrary.deck(sceneID: scene.id, title: scene.title) == deck,
                         "The widget and app must resolve exactly the same library")
            for prompt in deck {
                precondition(!prompt.hint.isEmpty && prompt.hint.count < 80 && prompt.hint != prompt.text)
                if !scene.isCustom {
                    precondition(builtInTexts.insert(prompt.text).inserted,
                                 "Built-in scenes must not recycle the same prompt: \(prompt.text)")
                }
            }
            for kind in PromptKind.allCases {
                let start = deck.firstIndex { $0.kind == kind }!
                var state = PromptProgress(promptIndex: start, kind: kind)
                var seen = Set<Int>()
                for _ in 0..<8 {
                    precondition(deck[state.promptIndex].kind == kind)
                    precondition(seen.insert(state.promptIndex).inserted, "No repeats until a direction is exhausted")
                    state.advance(in: deck)
                }
                precondition(seen.count == 8 && state.seenIndices.count == 1, "Only then begin a new cycle")
                let encodedProgress = try JSONEncoder().encode(state)
                precondition(encodedProgress.count < 1024, "Only lightweight progress is transmitted")
            }
            var progress = PromptProgress(promptIndex: 0, kind: .open)
            progress.advance(in: deck)
            let firstTwo = Set(progress.seenIndices)
            progress.advance(in: deck, to: .explore)
            progress.advance(in: deck, to: .open)
            precondition(!firstTwo.contains(progress.promptIndex), "Changing direction must preserve earlier progress")
            let restored = try JSONDecoder().decode(PromptProgress.self, from: JSONEncoder().encode(progress))
            precondition(restored == progress, "Progress must survive app/Lock Screen handoff and relaunch")
            let decoded = try JSONDecoder().decode([ConversationPrompt].self, from: JSONEncoder().encode(deck))
            precondition(decoded == deck, "Saved prompts must round-trip")
        }
        let legacy = Data("{\"promptIndex\":0,\"kind\":\"Open\"}".utf8)
        let migrated = try JSONDecoder().decode(PromptProgress.self, from: legacy)
        precondition(migrated.seenIndices == [0])
        var invalid = PromptProgress(promptIndex: -99, kind: .open, seenIndices: [-3, 999])
        invalid.normalize(in: PromptLibrary.deck(for: scenes[0]))
        precondition(invalid.promptIndex == 0 && invalid.seenIndices == [0])
        precondition(builtInTexts.count == 336)
        print("Passed: 336 distinct scene prompts + 24 custom prompts, topic hints, all rotation cycles, direction changes, persistence, legacy decoding, and progress payload budget.")
    }
}
