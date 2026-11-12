import ActivityKit
import AppIntents
import Foundation
import Observation

struct NextPromptIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Another conversation idea"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Session ID") var sessionID: String

    init() {}
    init(sessionID: String) { self.sessionID = sessionID }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let activity = Activity<SocialActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == sessionID && $0.activityState == .active
        }) else { return .result() }
        guard activity.attributes.endsAt > .now else {
            await activity.end(nil, dismissalPolicy: .immediate)
            return .result()
        }
        var state = activity.content.state
        let attributes = activity.attributes
        let deck = attributes.deck
        if !state.applyTimedDirection(in: deck, from: attributes.startedAt, until: attributes.endsAt) {
            state.advance(in: deck)
        }
        state.isPromptSaved = SavedPrompts.shared.contains(activity.attributes.prompt(for: state))
        await activity.update(ActivityContent(state: state, staleDate: activity.attributes.endsAt))
        return .result()
    }
}

struct SavePromptIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Save or remove a conversation prompt"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Session ID") var sessionID: String
    @Parameter(title: "Prompt ID") var promptID: String
    @Parameter(title: "Save") var save: Bool

    init() {}
    init(sessionID: String, promptID: String, save: Bool) {
        self.sessionID = sessionID
        self.promptID = promptID
        self.save = save
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let activity = Activity<SocialActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == sessionID && $0.activityState == .active
        }), activity.attributes.endsAt > .now else { return .result() }

        var state = activity.content.state
        guard let prompt = activity.attributes.prompt(for: state), prompt.id == promptID else {
            return .result()
        }
        SavedPrompts.shared.setSaved(save, for: prompt)
        state.isPromptSaved = save
        await activity.update(ActivityContent(state: state, staleDate: activity.attributes.endsAt))
        return .result()
    }
}

// LiveActivityIntent runs in the app process, so both surfaces use this store.
@MainActor @Observable
final class SavedPrompts {
    static let shared = SavedPrompts()

    private let defaults = UserDefaults.standard
    private let key = "culet.favorites"
    private var prompts: [ConversationPrompt]
    var count: Int { prompts.count }

    private init() {
        let data = defaults.data(forKey: key) ?? defaults.data(forKey: "whisper.favorites")
        prompts = data.flatMap { try? JSONDecoder().decode([ConversationPrompt].self, from: $0) } ?? []
    }

    func contains(_ prompt: ConversationPrompt?) -> Bool {
        guard let prompt else { return false }
        return prompts.contains { $0.id == prompt.id }
    }

    func setSaved(_ saved: Bool, for prompt: ConversationPrompt) {
        guard saved != contains(prompt) else { return }
        if saved {
            prompts.insert(prompt, at: 0)
        } else {
            prompts.removeAll { $0.id == prompt.id }
        }
        defaults.set(try? JSONEncoder().encode(prompts), forKey: key)
    }
}
