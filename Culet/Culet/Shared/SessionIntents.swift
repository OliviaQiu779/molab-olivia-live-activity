import ActivityKit
import AppIntents
import Foundation

struct NextPromptIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Another conversation idea"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Session ID") var sessionID: String

    init() {}
    init(sessionID: String) { self.sessionID = sessionID }

    func perform() async throws -> some IntentResult {
        guard let activity = Activity<SocialActivityAttributes>.activities.first(where: {
            $0.attributes.sessionID == sessionID && $0.activityState == .active
        }) else { return .result() }
        guard activity.attributes.endsAt > .now else {
            await activity.end(nil, dismissalPolicy: .immediate)
            return .result()
        }
        var state = activity.content.state
        state.advance(in: activity.attributes.deck)
        await activity.update(ActivityContent(state: state, staleDate: activity.attributes.endsAt))
        return .result()
    }
}

struct EndSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End conversation session"
    static var openAppWhenRun: Bool = false
    @Parameter(title: "Session ID") var sessionID: String

    init() {}
    init(sessionID: String) { self.sessionID = sessionID }

    func perform() async throws -> some IntentResult {
        for activity in Activity<SocialActivityAttributes>.activities where activity.attributes.sessionID == sessionID {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
