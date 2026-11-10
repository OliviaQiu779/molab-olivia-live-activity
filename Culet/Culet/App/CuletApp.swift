import SwiftUI

@main
struct CuletApp: App {
    @State private var store = SessionStore()
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).tint(CuletTheme.accent)
                .preferredColorScheme(.dark)
        }
    }
}

enum AppTab: Hashable { case home, session, profile }

struct RootView: View {
    @Environment(SessionStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = .home

    var body: some View {
        @Bindable var store = store
        TabView(selection: $selection) {
            Tab("Home", systemImage: "square.grid.2x2", value: AppTab.home) {
                HomeView(selection: $selection)
            }
            Tab("Session", systemImage: "waveform", value: AppTab.session) {
                SessionView(selection: $selection)
            }
            Tab("Profile", systemImage: "person", value: AppTab.profile) {
                ProfileView()
            }
        }
        .task { await store.reconcile() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await store.reconcile() } }
        }
        .onOpenURL { url in
            if url.scheme == "culet", url.host == "session" { selection = .session }
        }
        .alert("Session update", isPresented: Binding(
            get: { store.notice != nil }, set: { if !$0 { store.notice = nil } }
        )) {
            Button("OK") { store.notice = nil }
        } message: { Text(store.notice ?? "") }
    }
}
