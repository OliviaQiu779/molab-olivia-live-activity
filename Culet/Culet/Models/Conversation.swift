import Foundation

enum PromptKind: String, Codable, CaseIterable, Identifiable {
    case open = "Open", explore = "Explore", wrapUp = "Wrap up"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .open: "sparkle"
        case .explore: "bubble.left.and.bubble.right"
        case .wrapUp: "hand.wave"
        }
    }
}

struct ConversationPrompt: Codable, Hashable, Identifiable {
    let id: String
    let kind: PromptKind
    let text: String
    let hint: String
}

struct Situation: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let category: String
    let colorIndex: Int
    let opening: String
    let followUp: String
    let closing: String
    static let customCategory = "Your occasions"
    var isCustom: Bool { id.hasPrefix("custom-") }

    static func custom(_ name: String, id: String? = nil) -> Situation {
        Situation(id: id ?? "custom-\(UUID().uuidString)", title: name,
                  subtitle: "A little support for your own occasion.", symbol: "sparkles",
                  category: customCategory, colorIndex: 0,
                  opening: "What has been the highlight of your week?",
                  followUp: "What’s something you’re looking forward to?",
                  closing: "It was lovely talking with you. Enjoy the rest of your day!")
    }
}

enum SituationLibrary {
    static let all: [Situation] = [
        .init(id: "friends", title: "Mutual Friends", subtitle: "Meet new people through friends you already know.", symbol: "person.2", category: "Social", colorIndex: 0, opening: "How do you know everyone here?", followUp: "What do you like doing when you have a day to yourself?", closing: "I’m glad we got to meet. Hope to see you around!"),
        .init(id: "network", title: "Networking Event", subtitle: "Find a connection beyond a job title.", symbol: "point.3.connected.trianglepath.dotted", category: "Work & study", colorIndex: 1, opening: "What brought you to this event?", followUp: "What part of your work has you most curious right now?", closing: "I enjoyed hearing about your work. Would you like to stay in touch?"),
        .init(id: "date", title: "First Date", subtitle: "A little curiosity goes a long way.", symbol: "heart", category: "Relationships", colorIndex: 2, opening: "Have you been somewhere lately that you really liked?", followUp: "What does a really good weekend look like to you?", closing: "I’ve enjoyed getting to know you. Thanks for spending this time with me."),
        .init(id: "party", title: "Party", subtitle: "Ease into the room, one hello at a time.", symbol: "party.popper", category: "Social", colorIndex: 3, opening: "What’s the story behind how you know the host?", followUp: "What song would you add to tonight’s playlist?", closing: "It was fun chatting. I’m going to say hello to a few people!"),
        .init(id: "coworkers", title: "Team Lunch", subtitle: "Get to know the person behind the work.", symbol: "fork.knife", category: "Work & study", colorIndex: 1, opening: "Have you found any good lunch spots nearby?", followUp: "What do you enjoy doing after work to unwind?", closing: "This was a nice break. Let’s do lunch again sometime."),
        .init(id: "family", title: "Family Gathering", subtitle: "Make room for stories, old and new.", symbol: "house", category: "Relationships", colorIndex: 3, opening: "What have you been enjoying lately?", followUp: "Is there a family tradition you’d love to bring back?", closing: "It was good to catch up. I’m glad we had some time together."),
        .init(id: "club", title: "Interest Meetup", subtitle: "Start with what brought you together.", symbol: "leaf", category: "Everyday", colorIndex: 4, opening: "How did you first get interested in this?", followUp: "What would you recommend to someone just starting out?", closing: "Thanks for sharing those ideas. See you at the next meetup!"),
        .init(id: "reunion", title: "Friend Reunion", subtitle: "Pick up the thread, at your own pace.", symbol: "arrow.trianglehead.2.clockwise.rotate.90", category: "Relationships", colorIndex: 0, opening: "What’s something good that’s happened since we last met?", followUp: "What’s a memory from back then that still makes you smile?", closing: "I’m really glad we reconnected. Let’s not leave it so long next time."),
        .init(id: "wedding", title: "Wedding", subtitle: "Celebrate with someone new.", symbol: "wineglass", category: "Social", colorIndex: 2, opening: "How do you know the couple?", followUp: "Do you have a favorite story about them?", closing: "Lovely meeting you. Enjoy the celebration!"),
        .init(id: "campus", title: "Campus Welcome", subtitle: "A familiar face starts with hello.", symbol: "graduationcap", category: "Work & study", colorIndex: 4, opening: "What are you most looking forward to this semester?", followUp: "Have you found a favorite place on campus yet?", closing: "It was nice meeting you. Maybe I’ll see you around campus!"),
        .init(id: "neighbors", title: "Neighborhood Chat", subtitle: "Small conversations, closer community.", symbol: "building.2", category: "Everyday", colorIndex: 1, opening: "Do you have a favorite spot in the neighborhood?", followUp: "What do you enjoy most about living around here?", closing: "Nice running into you. Have a good rest of your day!"),
        .init(id: "travel", title: "Travel", subtitle: "Different journeys. A shared moment.", symbol: "airplane", category: "Everyday", colorIndex: 3, opening: "What’s been your favorite part of the trip so far?", followUp: "Is there somewhere you’d love to return to?", closing: "Thanks for the conversation. Enjoy your travels!"),
        .init(id: "conference", title: "Conference Break", subtitle: "Let a shared idea open the conversation.", symbol: "cup.and.saucer", category: "Work & study", colorIndex: 0, opening: "Has a talk stood out to you today?", followUp: "Was there an idea you’d like to try in your own work?", closing: "Thanks for sharing your thoughts. Enjoy the next session!"),
        .init(id: "partner-family", title: "Partner’s Family", subtitle: "Start gently. Let familiarity grow.", symbol: "heart.text.clipboard", category: "Relationships", colorIndex: 2, opening: "Thank you for having me. Do you often get everyone together?", followUp: "What’s a place you enjoy visiting as a family?", closing: "Thank you for making me feel welcome. I’ve enjoyed being here.")
    ]
    static let categories = ["All", "Social", "Work & study", "Relationships", "Everyday"]
}

struct SceneColorPair: Hashable {
    let primary: Int
    let secondary: Int

    static func resolve(_ sceneID: String, fallback: Int) -> Self {
        switch sceneID {
        case "coworkers": return .init(primary: 1, secondary: 0)
        case "family": return .init(primary: 4, secondary: 3)
        case "reunion": return .init(primary: 0, secondary: 2)
        case "wedding": return .init(primary: 2, secondary: 4)
        case "campus": return .init(primary: 4, secondary: 1)
        case "neighbors": return .init(primary: 1, secondary: 2)
        case "travel": return .init(primary: 3, secondary: 4)
        case "conference": return .init(primary: 0, secondary: 4)
        case "partner-family": return .init(primary: 2, secondary: 1)
        default: return .init(primary: fallback, secondary: (fallback + 3) % 5)
        }
    }
}

enum PromptLibrary {
    static func deck(for situation: Situation) -> [ConversationPrompt] {
        let catalogID = situation.isCustom ? "custom" : situation.id
        let hints = baseHints[catalogID] ?? baseHints["custom"]!
        let bases = [situation.opening, situation.followUp, situation.closing]
        return PromptKind.allCases.enumerated().flatMap { position, kind in
            let seeds = [PromptSeed(text: bases[position], hint: hints[position])]
                + (PromptCatalog.additions[catalogID]?[kind] ?? [])
            return seeds.enumerated().map { offset, seed in
                ConversationPrompt(id: "\(situation.id)-\(kind.storageKey)-\(offset)",
                                   kind: kind, text: seed.text, hint: seed.hint)
            }
        }
    }

    static func deck(sceneID: String, title: String) -> [ConversationPrompt] {
        let situation = SituationLibrary.all.first { $0.id == sceneID }
            ?? Situation.custom(title, id: sceneID)
        return deck(for: situation)
    }

    private static let baseHints: [String: [String]] = [
        "friends": ["Ask about the shared friend.", "Explore life beyond the group.", "Leave a friendly point of return."],
        "network": ["Ask what brought them here.", "Explore their current work.", "Offer to stay in touch about work."],
        "date": ["Trade a recent favorite place.", "Discover their ideal weekend.", "Close the date with appreciation."],
        "party": ["Ask how they know the host.", "Find a shared taste in music.", "Make room for other party guests."],
        "coworkers": ["Trade nearby lunch spots.", "Ask how they unwind after work.", "Suggest another lunch together."],
        "family": ["Catch up on everyday pleasures.", "Invite a family tradition.", "Appreciate the time together."],
        "club": ["Ask how the interest began.", "Invite a beginner recommendation.", "Look ahead to the next meetup."],
        "reunion": ["Catch up on a welcome change.", "Revisit a shared memory.", "Keep the reconnection going."],
        "wedding": ["Ask how they know the couple.", "Invite a story about the couple.", "Wish them a lovely celebration."],
        "campus": ["Ask about the semester ahead.", "Trade favorite campus spots.", "Leave a familiar face on campus."],
        "neighbors": ["Find a neighborhood favorite.", "Ask what they enjoy locally.", "Keep the passing encounter warm."],
        "travel": ["Ask about a trip highlight.", "Explore a place they'd revisit.", "Wish them a good onward journey."],
        "conference": ["Ask which talk stood out.", "Connect a talk to a real idea.", "Return to the conference program."],
        "partner-family": ["Thank them for the welcome.", "Invite a favorite family outing.", "Close the visit with gratitude."],
        "custom": ["Invite a small recent highlight.", "Ask what they're anticipating.", "Thank them for the conversation."]
    ]
}

extension PromptKind {
    var storageKey: String {
        switch self {
        case .open: "open"
        case .explore: "explore"
        case .wrapUp: "wrap"
        }
    }
}
