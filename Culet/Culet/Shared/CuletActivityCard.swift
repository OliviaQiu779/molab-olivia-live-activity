import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

/// A compact version of the app's prompt card. Keeps the standard Lock Screen
/// presentation at 156 pt at default text sizes, including the controls.
struct CuletActivityCard: View {
    let attributes: SocialActivityAttributes
    let state: SocialActivityAttributes.ContentState
    var isExpired = false
    var showBackground = true
    var showHeader = true
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var prompt: ConversationPrompt? { attributes.prompt(for: state) }
    private var isOver: Bool { isExpired || attributes.endsAt <= .now }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showHeader { HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("culet").font(.system(size: 14, weight: .medium)).tracking(-0.5)
                Spacer(minLength: 4)
                Text(attributes.title).font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72)).lineLimit(1)
            } }
            Text(isOver ? "Session complete." : (attributes.discreet ? prompt?.hint : prompt?.text) ?? "A moment to connect.")
                .font(.system(size: dynamicTypeSize.isAccessibilitySize ? 20 : 19, weight: .light))
                .tracking(-0.35).lineSpacing(2)
                .lineLimit(3).minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .accessibilityIdentifier("activity-prompt")
            HStack(spacing: 8) {
                if !isOver {
                    Button(intent: NextPromptIntent(sessionID: attributes.sessionID)) {
                        HStack(spacing: 8) {
                            Text("Another idea")
                            Image(systemName: "arrow.up.right").font(.system(size: 10))
                        }
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.black)
                        .padding(.horizontal, 13).frame(height: 30)
                        .background(Color(white: 0.95), in: .capsule)
                    }.buttonStyle(.plain).accessibilityLabel("Another idea").accessibilityIdentifier("activity-next-prompt")
                }
                Spacer(minLength: 2)
                if isOver {
                    Text("COMPLETE")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(1.3).foregroundStyle(.white.opacity(0.65))
                } else if let prompt {
                    Button(intent: SavePromptIntent(sessionID: attributes.sessionID,
                                                    promptID: prompt.id, save: !state.isPromptSaved)) {
                        Image(systemName: state.isPromptSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(.white.opacity(0.10), in: .circle)
                            .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(state.isPromptSaved ? "Remove saved prompt" : "Save prompt")
                    .accessibilityIdentifier("activity-save-prompt")
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 15)
        .frame(height: showHeader ? (dynamicTypeSize.isAccessibilitySize ? 160 : 156) : 128)
        .background {
            if showBackground {
                CuletCardSurface(tint: CuletPalette.color(at: attributes.colorIndex ?? 0),
                                 secondaryTint: CuletPalette.color(at: (attributes.colorIndex ?? 0) + 3),
                                 cornerRadius: 24)
            }
        }
        .foregroundStyle(.white).environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
    }
}
