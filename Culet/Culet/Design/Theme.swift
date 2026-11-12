import SwiftUI

enum CuletTheme {
    static let ink = Color(white: 0.94)
    static let accent = Color(red: 0.80, green: 0.91, blue: 0.66)
    static let background = Color(red: 0.027, green: 0.031, blue: 0.035)
    static let colors = CuletPalette.colors
}

struct AmbientBackground: View {
    var body: some View {
        CuletTheme.background.ignoresSafeArea().accessibilityHidden(true)
    }
}

/// A restrained, thick frosted surface, with a lit top edge and a dark lower rim.
struct SoftPanel: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var radius: CGFloat = 28
    func body(content: Content) -> some View {
        content
            .background(reduceTransparency ? Color(white: 0.12) : Color.white.opacity(0.045), in: .rect(cornerRadius: radius))
            .background(.ultraThinMaterial, in: .rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(LinearGradient(colors: [.white.opacity(0.24), .white.opacity(0.035), .white.opacity(0.10)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
            }
            .shadow(color: .black.opacity(0.35), radius: 18, y: 9)
    }
}

extension View {
    func softPanel() -> some View { modifier(SoftPanel()) }
    func culetScreen() -> some View {
        foregroundStyle(CuletTheme.ink).background { AmbientBackground() }
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .tracking(2).foregroundStyle(.white.opacity(0.52))
    }
}

struct PromptCard<HeaderAccessory: View>: View {
    let prompt: ConversationPrompt
    let color: Color
    let secondaryColor: Color
    let hintMode: Bool
    let headerAccessory: HeaderAccessory

    init(prompt: ConversationPrompt, color: Color = CuletTheme.colors[0],
         secondaryColor: Color = CuletPalette.colors[3], hintMode: Bool = false,
         @ViewBuilder headerAccessory: () -> HeaderAccessory = { EmptyView() }) {
        self.prompt = prompt
        self.color = color
        self.secondaryColor = secondaryColor
        self.hintMode = hintMode
        self.headerAccessory = headerAccessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Eyebrow(text: prompt.kind.rawValue)
                Spacer()
                headerAccessory
            }
            Spacer(minLength: 10)
            Text(hintMode ? prompt.hint : prompt.text)
                .font(.system(.title, weight: .light)).tracking(-0.7).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 10)
            Text(hintMode ? "Hint Mode" : prompt.hint).font(.caption).foregroundStyle(.white.opacity(0.6))
        }
        .padding(26).frame(minHeight: 300)
        .background {
            CuletCardSurface(tint: color, secondaryTint: secondaryColor, cornerRadius: 36)
        }
        .foregroundStyle(.white)
    }
}

struct SessionTimeRow: View {
    let title: LocalizedStringKey
    let identifier: String
    @Binding var minutes: Int
    @State private var draft = SessionTiming.minutes.lowerBound
    @State private var showingEditor = false

    var body: some View {
        HStack {
            Text(title).font(.subheadline)
            Spacer()
            Button {
                showingEditor = true
            } label: {
                HStack(spacing: 5) {
                    Text("\(minutes) min").monospacedDigit()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .font(.subheadline)
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(title))
            .accessibilityValue(Text("\(minutes) min"))
            .accessibilityIdentifier(identifier)
        }
        .frame(minHeight: 44)
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                Picker("Minutes", selection: $draft) {
                    ForEach(SessionTiming.minutes, id: \.self) { value in
                        Text("\(value) min").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .culetScreen()
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            minutes = draft
                            showingEditor = false
                        }
                        .accessibilityIdentifier("save-session-time")
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(.dark)
            .onAppear {
                draft = SessionTiming.validMinutes(minutes, fallback: SessionTiming.minutes.lowerBound)
            }
        }
    }
}

struct PrimaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, weight: .medium))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(Color(white: configuration.isPressed ? 0.75 : 0.94), in: .capsule)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

