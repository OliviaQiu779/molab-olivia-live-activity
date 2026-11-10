import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var store
    @AppStorage("culet.defaultMinutes") private var defaultMinutes = 60
    @AppStorage("culet.discreet") private var discreet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 12) {
                            Eyebrow(text: "Personal space")
                            Text("Your frequency.")
                                .font(.system(.largeTitle, weight: .light)).tracking(-1.2)
                        }
                        Spacer()
                        Image(systemName: "person").font(.system(size: 17, weight: .ultraLight))
                            .frame(width: 48, height: 48)
                            .glassEffect(.regular, in: .circle)
                    }.padding(.top, 20)

                    stat(value: store.completedCount, title: "Sessions")
                        .padding(.vertical, 24).softPanel()

                    VStack(alignment: .leading, spacing: 22) {
                        Eyebrow(text: "Preferences")
                        HStack {
                            Text("Default duration").font(.subheadline)
                            Spacer()
                            Picker("Default duration", selection: $defaultMinutes) {
                                ForEach([30, 60, 90, 120], id: \.self) { Text("\($0) min").tag($0) }
                            }.labelsHidden().tint(.white)
                        }
                        Divider()
                        Toggle(isOn: $discreet) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Hint Mode").font(.subheadline)
                                Text("Replace full questions with brief topic cues.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }.accessibilityIdentifier("hint-mode-toggle")
                    }.padding(.horizontal, 2)

                    HStack {
                        Text("culet").font(.system(size: 14, weight: .medium)).tracking(-0.5)
                        Spacer()
                        Eyebrow(text: "V 0.4")
                    }.foregroundStyle(.white.opacity(0.5)).padding(.bottom, 60)
                }.padding(.horizontal, 24)
            }.scrollIndicators(.hidden).culetScreen()
                .navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
        }
    }

    private func stat(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: "%02d", value))
                .font(.system(size: 46, weight: .ultraLight, design: .monospaced)).tracking(-3)
            Eyebrow(text: title)
        }.frame(maxWidth: .infinity)
    }
}
