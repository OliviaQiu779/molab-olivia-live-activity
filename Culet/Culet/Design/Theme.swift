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

/// Gradient-only surface. No decorative ticks, rings, glyphs, or line illustrations.
struct CardLightField: View {
    let color: Color
    var variant = 0
    var body: some View {
        CuletCardSurface(tint: color, secondaryTint: CuletPalette.color(at: variant + 3))
    }
}

struct PromptCard: View {
    let prompt: ConversationPrompt
    var color: Color = CuletTheme.colors[0]
    var secondaryColor: Color = CuletPalette.colors[3]
    var hintMode = false
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Eyebrow(text: prompt.kind.rawValue)
                Spacer()
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

