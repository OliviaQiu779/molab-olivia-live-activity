import ActivityKit
import Foundation
import Observation

struct SessionSnapshot: Codable {
    let id: String
    let title: String
    let sceneID: String?
    let colorIndex: Int?
    let symbol: String
    var resolvedSceneID: String {
        sceneID ?? SituationLibrary.all.first(where: { $0.title == title })?.id ?? "custom-\(id)"
    }
    var deck: [ConversationPrompt] { PromptLibrary.deck(sceneID: resolvedSceneID, title: title) }
    let startedAt: Date
    let endsAt: Date
    let discreet: Bool
    var state: SocialActivityAttributes.ContentState
    var hasLiveActivity: Bool

    var prompt: ConversationPrompt? {
        attributes.prompt(for: state)
    }
    var attributes: SocialActivityAttributes {
        .init(sessionID: id, sceneID: resolvedSceneID, title: title, colorIndex: colorIndex, symbol: symbol, startedAt: startedAt,
              endsAt: endsAt, discreet: discreet)
    }

    init(situation: Situation, minutes: Int, kind: PromptKind, discreet: Bool) {
        id = UUID().uuidString
        title = situation.title
        sceneID = situation.id
        colorIndex = situation.colorIndex
        symbol = situation.symbol
        startedAt = .now
        endsAt = startedAt.addingTimeInterval(TimeInterval(minutes * 60))
        self.discreet = discreet
        let initialDeck = PromptLibrary.deck(for: situation)
        state = .init(promptIndex: initialDeck.firstIndex(where: { $0.kind == kind }) ?? 0, kind: kind)
        hasLiveActivity = false
    }

    init(activity: Activity<SocialActivityAttributes>) {
        let a = activity.attributes
        id = a.sessionID; title = a.title; sceneID = a.sceneID; colorIndex = a.colorIndex; symbol = a.symbol
        startedAt = a.startedAt; endsAt = a.endsAt; discreet = a.discreet
        state = activity.content.state
        hasLiveActivity = true
        state.normalize(in: deck)
    }
}

@MainActor @Observable
final class SessionStore {
    private(set) var session: SessionSnapshot?
    private(set) var completedCount = 0
    var savedPromptCount: Int { SavedPrompts.shared.count }
    private(set) var isBusy = false
    var notice: String?

    @ObservationIgnored private var activity: Activity<SocialActivityAttributes>?
    @ObservationIgnored private var contentTask: Task<Void, Never>?
    @ObservationIgnored private var stateTask: Task<Void, Never>?
    @ObservationIgnored private var sessionTimer: Task<Void, Never>?
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        // Preserve local preferences when an existing installation keeps its bundle ID.
        for suffix in ["session", "completed", "defaultMinutes", "discreet"] {
            let currentKey = "culet.\(suffix)"
            if defaults.object(forKey: currentKey) == nil,
               let legacyValue = defaults.object(forKey: "whisper.\(suffix)") {
                defaults.set(legacyValue, forKey: currentKey)
            }
        }
        if let data = defaults.data(forKey: "culet.session") {
            session = try? JSONDecoder().decode(SessionSnapshot.self, from: data)
            if var restored = session {
                restored.state.normalize(in: restored.deck)
                session = restored
            }
        }
        completedCount = defaults.integer(forKey: "culet.completed")
    }

    func reconcile() async {
        guard !isBusy else { return }
        let activities = Activity<SocialActivityAttributes>.activities
        let current = activities.first(where: {
            (session == nil || $0.attributes.sessionID == session?.id) &&
            ($0.activityState == .active || $0.activityState == .stale)
        })
        if let current {
            session = SessionSnapshot(activity: current)
            observe(current)
        } else if session?.hasLiveActivity == true {
            clearSession()
        }
        if let session, session.endsAt <= .now {
            await end()
        } else {
            await updateTimedDirection()
            persist()
            scheduleSessionTimer()
        }
    }

    @discardableResult
    func start(situation: Situation, minutes: Int, kind: PromptKind, discreet: Bool) async -> Bool {
        guard !isBusy, session == nil else { return false }
        isBusy = true
        defer { isBusy = false }
        var snapshot = SessionSnapshot(situation: situation, minutes: minutes, kind: kind, discreet: discreet)
        snapshot.state.isPromptSaved = isSaved(snapshot.prompt)
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                let requested = try Activity.request(attributes: snapshot.attributes,
                    content: ActivityContent(state: snapshot.state, staleDate: snapshot.endsAt), pushType: nil)
                snapshot.hasLiveActivity = true
                session = snapshot
                observe(requested)
            } catch {
                notice = "Your session is ready in the app, but the Lock Screen activity could not start. \(error.localizedDescription)"
            }
        } else {
            notice = "Your session is ready in the app. Live Activities are unavailable or turned off. You can check Settings → Apps → Culet → Live Activities."
        }
        session = snapshot
        persist()
        scheduleSessionTimer()
        return true
    }

    func next(kind: PromptKind? = nil) async {
        guard !isBusy, var snapshot = session else { return }
        guard snapshot.endsAt > .now else { await end(); return }
        isBusy = true
        defer { isBusy = false }
        // Read the latest activity state, including updates made from the Lock Screen.
        if let activity { snapshot.state = activity.content.state }
        let deck = snapshot.deck
        let switched = snapshot.state.applyTimedDirection(in: deck, from: snapshot.startedAt, until: snapshot.endsAt)
        if !switched || (kind != nil && kind != snapshot.state.kind) {
            snapshot.state.advance(in: deck, to: kind)
        }
        snapshot.state.isPromptSaved = isSaved(snapshot.prompt)
        session = snapshot
        if let activity {
            await activity.update(ActivityContent(state: snapshot.state, staleDate: snapshot.endsAt))
        }
        persist()
    }

    func isSaved(_ prompt: ConversationPrompt?) -> Bool {
        SavedPrompts.shared.contains(prompt)
    }

    func toggleSavedPrompt(_ prompt: ConversationPrompt) async {
        guard !isBusy, var snapshot = session, snapshot.endsAt > .now else { return }
        let saved = !isSaved(prompt)
        SavedPrompts.shared.setSaved(saved, for: prompt)

        if let activity { snapshot.state = activity.content.state }
        guard snapshot.prompt?.id == prompt.id else { return }
        snapshot.state.isPromptSaved = saved
        session = snapshot
        if let activity {
            isBusy = true
            await activity.update(ActivityContent(state: snapshot.state, staleDate: snapshot.endsAt))
            isBusy = false
        }
    }

    func end() async {
        guard !isBusy, session != nil else { return }
        isBusy = true
        if let activity { await activity.end(nil, dismissalPolicy: .immediate) }
        clearSession()
        isBusy = false
    }

    private func observe(_ liveActivity: Activity<SocialActivityAttributes>) {
        guard activity?.id != liveActivity.id else { return }
        contentTask?.cancel(); stateTask?.cancel()
        activity = liveActivity
        contentTask = Task { [weak self] in
            for await content in liveActivity.contentUpdates {
                guard !Task.isCancelled, let self, self.session?.id == liveActivity.attributes.sessionID else { return }
                self.session?.state = content.state
                self.persist()
            }
        }
        stateTask = Task { [weak self] in
            for await state in liveActivity.activityStateUpdates {
                guard !Task.isCancelled, let self, self.session?.id == liveActivity.attributes.sessionID else { return }
                if state == .ended || state == .dismissed {
                    // An in-app end owns its own cleanup.
                    if !self.isBusy { self.clearSession() }
                    return
                }
            }
        }
    }

    private func updateTimedDirection() async {
        guard !isBusy, var snapshot = session else { return }
        if let activity { snapshot.state = activity.content.state }
        let previousState = snapshot.state
        snapshot.state.applyTimedDirection(in: snapshot.deck, from: snapshot.startedAt, until: snapshot.endsAt)
        guard snapshot.state != previousState else { return }

        isBusy = true
        defer { isBusy = false }
        snapshot.state.isPromptSaved = isSaved(snapshot.prompt)
        session = snapshot
        if let activity {
            await activity.update(ActivityContent(state: snapshot.state, staleDate: snapshot.endsAt))
        }
        persist()
    }

    private func scheduleSessionTimer() {
        sessionTimer?.cancel()
        guard let session else { return }
        let id = session.id
        let nextTransition = session.state.nextTransition(from: session.startedAt, until: session.endsAt)
        let seconds = max(0, nextTransition.timeIntervalSinceNow)

        sessionTimer = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(seconds))
                while self?.isBusy == true {
                    try await Task.sleep(for: .milliseconds(100))
                }
            } catch { return }
            guard let self, !Task.isCancelled, let current = self.session, current.id == id else { return }

            if current.endsAt <= .now {
                await self.end()
            } else {
                await self.updateTimedDirection()
                if !Task.isCancelled { self.scheduleSessionTimer() }
            }
        }
    }

    private func clearSession() {
        if session != nil {
            completedCount += 1
            defaults.set(completedCount, forKey: "culet.completed")
        }
        contentTask?.cancel(); stateTask?.cancel(); sessionTimer?.cancel()
        contentTask = nil; stateTask = nil; sessionTimer = nil; activity = nil
        session = nil
        persist()
    }

    private func persist() {
        if let session, let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: "culet.session")
        } else { defaults.removeObject(forKey: "culet.session") }
    }
}
