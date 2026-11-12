import SwiftUI

struct PrepareView: View {
    @Environment(SessionStore.self) private var store
    @AppStorage("culet.defaultMinutes") private var defaultMinutes = SessionTiming.defaultDuration
    @AppStorage("culet.defaultPromptRotation") private var defaultRotation = SessionTiming.defaultPromptInterval
    @AppStorage("culet.discreet") private var discreet = false
    let situation: Situation
    let onStarted: () -> Void
    @State private var minutes = SessionTiming.defaultDuration
    @State private var rotation = SessionTiming.defaultPromptInterval
    @State private var kind: PromptKind = .open

    private var deck: [ConversationPrompt] { PromptLibrary.deck(for: situation) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: situation.category)
                    Text(situation.title).font(.system(.largeTitle, weight: .light)).tracking(-1.2)
                    Text(situation.subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.5))
                }.padding(.top, 16)

                VStack(alignment: .leading, spacing: 14) {
                    if let preview = deck.first(where: { $0.kind == kind }) {
                        let colors = CuletPalette.sceneColors(for: situation.id, fallback: situation.colorIndex)
                        PromptCard(prompt: preview, color: colors.primary,
                                   secondaryColor: colors.secondary, hintMode: discreet)
                    }
                    if situation.isCustom {
                        Label("General prompts, with your occasion’s name.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    SessionTimeRow(title: "Duration", identifier: "session-duration", minutes: $minutes)
                    Divider().overlay(.white.opacity(0.05))
                    SessionTimeRow(title: "Prompt interval", identifier: "session-prompt-interval", minutes: $rotation)
                    Divider().overlay(.white.opacity(0.05))
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Conversation direction").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Starting point", selection: $kind) {
                            ForEach(PromptKind.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented)
                    }
                    Divider().overlay(.white.opacity(0.05))
                    Toggle(isOn: $discreet) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Hint Mode").font(.subheadline)
                            Text("Replace full questions with brief topic cues.").font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityIdentifier("hint-mode-toggle")
                }.padding(.horizontal, 4).padding(.bottom, 20)
            }.padding(.horizontal, 24)
        }
        .culetScreen().navigationTitle("Set the scene").navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if store.session != nil {
                    Text("End your current session to start a new one.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Continue current session", action: onStarted)
                        .buttonStyle(PrimaryActionStyle())
                } else {
                    Button {
                        Task {
                            if await store.start(situation: situation, minutes: minutes, kind: kind, discreet: discreet, rotation: rotation) {
                                onStarted()
                            }
                        }
                    } label: {
                        HStack {
                            if store.isBusy { ProgressView().tint(.black) }
                            Text("Start session")
                            Image(systemName: "arrow.up.right").font(.caption)
                        }
                    }.buttonStyle(PrimaryActionStyle()).disabled(store.isBusy)
                        .accessibilityIdentifier("start-session")
                }
            }.padding(.horizontal, 24).padding(.vertical, 12)
                .background(CuletTheme.background.opacity(0.94))
        }
        .onAppear {
            minutes = SessionTiming.validMinutes(defaultMinutes, fallback: SessionTiming.defaultDuration)
            rotation = SessionTiming.validMinutes(defaultRotation, fallback: SessionTiming.defaultPromptInterval)
        }
    }
}
