import SwiftUI

struct PrepareView: View {
    @Environment(SessionStore.self) private var store
    @AppStorage("culet.defaultMinutes") private var defaultMinutes = 60
    @AppStorage("culet.discreet") private var discreet = false
    let situation: Situation
    let onStarted: () -> Void
    @State private var minutes = 60
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
                        PromptCard(prompt: preview, color: CuletTheme.colors[situation.colorIndex],
                                   secondaryColor: CuletPalette.color(at: situation.colorIndex + 3), hintMode: discreet)
                    }
                    if situation.isCustom {
                        Label("General prompts, with your occasion’s name.", systemImage: "info.circle")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Duration").font(.subheadline)
                        Spacer()
                        Picker("Session length", selection: $minutes) {
                            ForEach([30, 60, 90, 120], id: \.self) { Text("\($0) min").tag($0) }
                        }.labelsHidden().tint(.white)
                    }
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
                            if await store.start(situation: situation, minutes: minutes, kind: kind, discreet: discreet) {
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
        .onAppear { minutes = [30, 60, 90, 120].contains(defaultMinutes) ? defaultMinutes : 60 }
    }
}
