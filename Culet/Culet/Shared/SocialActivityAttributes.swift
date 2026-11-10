import ActivityKit
import Foundation

struct SocialActivityAttributes: ActivityAttributes {
    typealias ContentState = PromptProgress

    let sessionID: String
    var sceneID: String? = nil
    let title: String
    var colorIndex: Int? = nil
    let symbol: String
    let startedAt: Date
    let endsAt: Date
    let discreet: Bool

    var resolvedSceneID: String {
        sceneID ?? SituationLibrary.all.first(where: { $0.title == title })?.id ?? "custom-\(sessionID)"
    }
    var deck: [ConversationPrompt] {
        PromptLibrary.deck(sceneID: resolvedSceneID, title: title)
    }
    func prompt(for state: ContentState) -> ConversationPrompt? {
        let prompts = deck
        if prompts.indices.contains(state.promptIndex), prompts[state.promptIndex].kind == state.kind {
            return prompts[state.promptIndex]
        }
        return prompts.first { $0.kind == state.kind }
    }
}
