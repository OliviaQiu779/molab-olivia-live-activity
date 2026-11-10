import SwiftUI

enum CuletPalette {
    static let colors: [Color] = [
        .init(red: 0.31, green: 0.55, blue: 0.80),
        .init(red: 0.38, green: 0.70, blue: 0.82),
        .init(red: 0.87, green: 0.22, blue: 0.52),
        .init(red: 0.89, green: 0.40, blue: 0.17),
        .init(red: 0.52, green: 0.69, blue: 0.39)
    ]
    static func color(at index: Int) -> Color {
        colors[(index % colors.count + colors.count) % colors.count]
    }
}

/// The exact same gradient and edge treatment is compiled into the app and widget.
/// Native gradients stay crisp when WidgetKit archives the view for the Lock Screen.
struct CuletCardSurface: View {
    let tint: Color
    var secondaryTint: Color = CuletPalette.colors[3]
    var cornerRadius: CGFloat = 30
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.isLuminanceReduced) private var luminanceReduced

    var body: some View {
        GeometryReader { geometry in
            let radius = max(geometry.size.width, geometry.size.height)
            ZStack {
                Color(red: 0.045, green: 0.055, blue: 0.065)
                if !reduceTransparency {
                    RadialGradient(colors: [tint.opacity(luminanceReduced ? 0.4 : 0.85), tint.opacity(0.28), .clear],
                                   center: .init(x: 0.88, y: 0.16), startRadius: 0, endRadius: radius * 0.86)
                    RadialGradient(colors: [secondaryTint.opacity(luminanceReduced ? 0.15 : 0.36), .clear],
                                   center: .init(x: 0.04, y: 0.95), startRadius: 0, endRadius: radius * 0.63)
                    LinearGradient(colors: [.white.opacity(0.035), .clear, .black.opacity(0.60)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                } else {
                    tint.opacity(0.20)
                }
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.30), .white.opacity(0.025), .white.opacity(0.13)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 0.7)
        }
        .accessibilityHidden(true)
    }
}
