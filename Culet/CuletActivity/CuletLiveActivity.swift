import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CuletWidgetBundle: WidgetBundle {
    var body: some Widget { CuletLiveActivity() }
}

struct CuletLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SocialActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color(red: 0.045, green: 0.055, blue: 0.065))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "culet://session"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("culet").font(.system(size: 14, weight: .medium)).tracking(-0.5)
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.title).font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.65)).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    CuletActivityCard(attributes: context.attributes, state: context.state,
                                      isExpired: context.isStale, showHeader: false)
                        .padding(.top, 4)
                }
            } compactLeading: {
                Text("c").font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CuletPalette.color(at: context.attributes.colorIndex ?? 0))
            } compactTrailing: {
                Image(systemName: context.isStale ? "checkmark" : context.state.kind.symbol)
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.85))
            } minimal: {
                Text("c").font(.system(size: 16, weight: .medium))
                    .foregroundStyle(CuletPalette.color(at: context.attributes.colorIndex ?? 0))
            }
            .widgetURL(URL(string: "culet://session"))
            .keylineTint(CuletPalette.color(at: context.attributes.colorIndex ?? 0).opacity(0.4))
        }
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<SocialActivityAttributes>
    @Environment(\.showsWidgetContainerBackground) private var showsBackground
    var body: some View {
        CuletActivityCard(attributes: context.attributes, state: context.state,
                          isExpired: context.isStale, showBackground: showsBackground)
    }
}

#Preview("Lock Screen", as: .content, using: SocialActivityAttributes(
    sessionID: "preview", sceneID: "friends", title: "Mutual Friends", colorIndex: 0, symbol: "person.2",
    startedAt: .now, endsAt: .now.addingTimeInterval(3600), discreet: false
)) {
    CuletLiveActivity()
} contentStates: {
    SocialActivityAttributes.ContentState(promptIndex: 0, kind: .open)
    SocialActivityAttributes.ContentState(promptIndex: 8, kind: .explore)
    SocialActivityAttributes.ContentState(promptIndex: 16, kind: .wrapUp)
}
