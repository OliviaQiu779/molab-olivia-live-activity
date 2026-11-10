import SwiftUI

struct SessionView: View {
    @Environment(SessionStore.self) private var store
    @Binding var selection: AppTab
    @State private var confirmingEnd = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let session = store.session, let prompt = session.prompt {
                    VStack(alignment: .leading, spacing: 26) {
                        HStack {
                            Eyebrow(text: "Here. Now.")
                            Spacer()
                            Circle().fill(CuletTheme.accent).frame(width: 4, height: 4)
                            Eyebrow(text: "Live")
                        }.padding(.top, 18)
                        HStack(alignment: .bottom) {
                            Text(session.title).font(.system(.largeTitle, weight: .light)).tracking(-1.2)
                            Spacer(minLength: 8)
                            VStack(alignment: .trailing, spacing: 5) {
                                Text(timerInterval: session.startedAt...session.endsAt, countsDown: true)
                                    .font(.system(.title3, design: .monospaced, weight: .ultraLight))
                                    .monospacedDigit().fixedSize()
                                Eyebrow(text: "Remaining")
                            }
                        }

                        Picker("Conversation direction", selection: Binding(
                            get: { session.state.kind },
                            set: { value in Task { await store.next(kind: value) } }
                        )) {
                            ForEach(PromptKind.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).disabled(store.isBusy)

                        PromptCard(prompt: prompt, color: CuletPalette.color(at: session.colorIndex ?? 0),
                                   secondaryColor: CuletPalette.color(at: (session.colorIndex ?? 0) + 3))

                        Button {
                            Task { await store.next() }
                        } label: {
                            HStack(spacing: 12) {
                                Text("Another idea")
                                Image(systemName: "arrow.up.right").font(.caption)
                            }
                        }.buttonStyle(PrimaryActionStyle()).disabled(store.isBusy)
                            .accessibilityIdentifier("next-prompt")

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: session.hasLiveActivity ? "lock.iphone" : "iphone")
                                .font(.system(size: 15, weight: .light))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(session.hasLiveActivity ? "On your Lock Screen" : "In-app session")
                                    .font(.caption)
                                if !session.hasLiveActivity {
                                    Text("Live Activity is unavailable. Your prompts are here.")
                                        .font(.caption).foregroundStyle(.white.opacity(0.55))
                                } else if session.discreet {
                                    Text("Hint Mode is on.")
                                        .font(.caption).foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            Spacer()
                        }.foregroundStyle(.white.opacity(0.65)).padding(.vertical, 4)
                    }.padding(.horizontal, 24).padding(.bottom, 16)
                } else {
                    VStack(spacing: 25) {
                        CardLightField(color: CuletTheme.colors[0], variant: 0)
                            .frame(width: 180, height: 220).clipShape(.rect(cornerRadius: 70))
                            .overlay(RoundedRectangle(cornerRadius: 70).strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
                        Text("A moment to connect.")
                            .font(.system(.largeTitle, weight: .light)).tracking(-1).multilineTextAlignment(.center)
                        Text("Choose a scene to begin.").font(.subheadline).foregroundStyle(.secondary)
                        Button("Find your occasion", systemImage: "arrow.up.right") { selection = .home }
                            .buttonStyle(PrimaryActionStyle())
                    }.frame(maxWidth: .infinity).padding(32).padding(.top, 45)
                }
            }.scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if store.session?.prompt != nil {
                        Button(role: .destructive) {
                            confirmingEnd = true
                        } label: {
                            Text("End Session")
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.78))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(store.isBusy)
                        .accessibilityIdentifier("end-session")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 6)
                        .background(CuletTheme.background)
                    }
                }
                .culetScreen()
                .navigationTitle("Session").navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $confirmingEnd) {
                    EndSessionSheet(isBusy: store.isBusy,
                                    onKeepGoing: { confirmingEnd = false }) {
                        Task {
                            await store.end()
                            confirmingEnd = false
                        }
                    }
                    .presentationDetents([.height(280)])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(36)
                    .presentationBackground {
                        CuletCardSurface(tint: CuletPalette.color(at: store.session?.colorIndex ?? 0).opacity(0.3),
                                         secondaryTint: .black, cornerRadius: 36)
                    }
                    .interactiveDismissDisabled(store.isBusy)
                    .preferredColorScheme(.dark)
                }
                .onChange(of: store.session?.id) { _, id in
                    if id == nil { confirmingEnd = false }
                }
        }
    }
}

private struct EndSessionSheet: View {
    let isBusy: Bool
    let onKeepGoing: () -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("End this session?")
                .font(.system(.title2, weight: .light)).tracking(-0.5)
                .padding(.top, 12)
            Button(action: onEnd) {
                HStack(spacing: 10) {
                    if isBusy { ProgressView().tint(.black) }
                    Text("End session")
                }
            }
            .buttonStyle(PrimaryActionStyle()).disabled(isBusy)
            .accessibilityIdentifier("confirm-end-session")
            Button(action: onKeepGoing) {
                Text("Keep going")
                    .font(.system(.subheadline, weight: .medium)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .overlay(Capsule().strokeBorder(.white.opacity(0.85), lineWidth: 1))
                    .contentShape(.capsule)
            }
            .buttonStyle(.plain).disabled(isBusy).accessibilityIdentifier("keep-session")
        }
        .padding(26).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(.white)
    }
}
