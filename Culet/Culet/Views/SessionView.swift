import SwiftUI

struct SessionView: View {
    @Environment(SessionStore.self) private var store
    @Binding var selection: AppTab
    @State private var confirmingEnd = false

    var body: some View {
        NavigationStack {
            Group {
                if let session = store.session, let prompt = session.prompt {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 26) {
                            HStack(alignment: .bottom) {
                                Text(session.title).font(.system(.largeTitle, weight: .light)).tracking(-1.2)
                                Spacer(minLength: 8)
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text(timerInterval: session.startedAt...session.endsAt, countsDown: true)
                                        .font(.system(.title3, design: .monospaced, weight: .ultraLight))
                                        .monospacedDigit().fixedSize()
                                    Eyebrow(text: "Remaining")
                                }
                            }.padding(.top, 18)

                            Picker("Conversation direction", selection: Binding(
                                get: { session.state.kind },
                                set: { value in Task { await store.next(kind: value) } }
                            )) {
                                ForEach(PromptKind.allCases) { Text($0.rawValue).tag($0) }
                            }.pickerStyle(.segmented).disabled(store.isBusy)

                            let isSaved = store.isSaved(prompt)
                            PromptCard(prompt: prompt, color: CuletPalette.color(at: session.colorIndex ?? 0),
                                       secondaryColor: CuletPalette.color(at: (session.colorIndex ?? 0) + 3)) {
                                Button {
                                    Task { await store.toggleSavedPrompt(prompt) }
                                } label: {
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                        .frame(width: 36, height: 36)
                                        .glassEffect(.regular.interactive(), in: .circle)
                                        .frame(width: 44, height: 44)
                                        .contentShape(.rect)
                                }
                                .buttonStyle(.plain).disabled(store.isBusy)
                                .accessibilityLabel(isSaved ? "Remove saved prompt" : "Save prompt")
                                .accessibilityIdentifier("save-prompt")
                            }

                            VStack(spacing: 12) {
                                Button {
                                    Task { await store.next() }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text("Another idea")
                                        Image(systemName: "arrow.up.right").font(.caption)
                                    }
                                }
                                .buttonStyle(PrimaryActionStyle()).disabled(store.isBusy)
                                .accessibilityIdentifier("next-prompt")

                                Button(role: .destructive) {
                                    confirmingEnd = true
                                } label: {
                                    Text("End Session")
                                        .font(.body)
                                        .foregroundStyle(.white.opacity(0.78))
                                        .frame(maxWidth: .infinity, minHeight: 48)
                                        .contentShape(.rect)
                                }
                                .buttonStyle(.plain).disabled(store.isBusy)
                                .accessibilityIdentifier("end-session")
                            }
                        }.padding(.horizontal, 24).padding(.bottom, 16)
                    }.scrollIndicators(.hidden)
                } else {
                    emptySession
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

    private var emptySession: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("A moment to connect.")
                            .font(.system(.largeTitle, weight: .light))
                            .tracking(-1)
                        Text("Choose a scene to begin.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)

                    Button("Find your occasion", systemImage: "arrow.up.right") {
                        selection = .home
                    }
                    .buttonStyle(PrimaryActionStyle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 60)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
        }
        .background {
            ZStack {
                EllipticalGradient(
                    stops: [
                        .init(color: Color(red: 0.22, green: 0.37, blue: 0.38), location: 0),
                        .init(color: Color(red: 0.15, green: 0.27, blue: 0.30), location: 0.35),
                        .init(color: .clear, location: 1)
                    ],
                    center: .init(x: 0.35, y: 0.41),
                    endRadiusFraction: 0.66
                )
                EllipticalGradient(
                    colors: [Color(red: 0.23, green: 0.19, blue: 0.30).opacity(0.72), .clear],
                    center: .init(x: 0.67, y: 0.50),
                    endRadiusFraction: 0.68
                )
            }
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.11),
                        .init(color: .black, location: 0.32),
                        .init(color: .black, location: 0.57),
                        .init(color: .clear, location: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
        .toolbarBackground(.hidden, for: .navigationBar)
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
