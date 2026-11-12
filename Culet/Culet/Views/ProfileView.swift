import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var store
    @AppStorage("culet.defaultMinutes") private var defaultMinutes = SessionTiming.defaultDuration
    @AppStorage("culet.defaultPromptRotation") private var defaultRotation = SessionTiming.defaultPromptInterval
    @AppStorage("culet.discreet") private var discreet = false
    @AppStorage("culet.displayName") private var displayName = "Olivia Q"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    VStack(alignment: .leading, spacing: 20) {
                        NavigationLink {
                            ProfileDetailsView(displayName: $displayName)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "person")
                                    .font(.system(size: 17, weight: .ultraLight))
                                    .frame(width: 48, height: 48)
                                    .glassEffect(.regular, in: .circle)
                                    .accessibilityHidden(true)
                                Text(displayName.isEmpty ? "Olivia Q" : displayName)
                                    .font(.title3).lineLimit(2)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .frame(minHeight: 48)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }.padding(.top, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "Summary")
                        HStack(spacing: 0) {
                            stat(value: store.completedCount, title: "Sessions")
                            Rectangle().fill(.white.opacity(0.12)).frame(width: 0.5, height: 50)
                            stat(value: store.savedPromptCount, title: "Saved")
                        }.padding(.vertical, 24).softPanel()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "Preferences")
                        VStack(spacing: 0) {
                            SessionTimeRow(title: "Duration", identifier: "profile-duration", minutes: $defaultMinutes)
                            Divider()
                            SessionTimeRow(title: "Prompt interval", identifier: "profile-prompt-interval", minutes: $defaultRotation)
                            Divider()
                            Toggle(isOn: $discreet) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Hint Mode").font(.subheadline)
                                    Text("Replace full questions with brief topic cues.")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }.padding(.vertical, 12).accessibilityIdentifier("hint-mode-toggle")
                        }
                    }.padding(.horizontal, 2)

                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: "Support")
                        VStack(spacing: 0) {
                            NavigationLink {
                                ProfileHelpView()
                            } label: {
                                settingsRow("Help", icon: "questionmark.circle")
                            }
                            .buttonStyle(.plain)
                            Divider()
                            NavigationLink {
                                AboutCuletView()
                            } label: {
                                settingsRow("About Culet", icon: "info.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 2)

                    HStack {
                        Text("culet").font(.system(size: 14, weight: .medium)).tracking(-0.5)
                        Spacer()
                        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Eyebrow(text: "V \(version)")
                        }
                    }.foregroundStyle(.white.opacity(0.5)).padding(.bottom, 28)
                }.padding(.horizontal, 24)
            }.scrollIndicators(.hidden).culetScreen()
                .navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
        }
    }

    private func settingsRow(_ title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).accessibilityHidden(true)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .font(.subheadline)
        .frame(minHeight: 44)
        .contentShape(.rect)
    }

    private func stat(value: Int, title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(format: "%02d", value))
                .font(.system(size: 46, weight: .ultraLight, design: .monospaced)).tracking(-3)
            Eyebrow(text: title)
        }.frame(maxWidth: .infinity)
    }
}

private struct ProfileDetailsView: View {
    @Binding var displayName: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Eyebrow(text: "Display name")
            TextField("Your name", text: $draft)
                .textContentType(.name)
                .submitLabel(.done)
                .onSubmit(save)
                .padding(16).softPanel()
            Button("Save", action: save)
                .buttonStyle(PrimaryActionStyle())
            Spacer()
        }
        .padding(24).culetScreen()
        .navigationTitle("Personal profile").navigationBarTitleDisplayMode(.inline)
        .onAppear { draft = displayName }
    }

    private func save() {
        displayName = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        dismiss()
    }
}

private struct ProfileHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                topic("Live Activities", detail: "Start a session to see a prompt on your Lock Screen. Use Another Idea to change prompts, or tap the bookmark to save one.")
                topic("Hint Mode", detail: "Show brief topic cues on your Lock Screen while keeping the full questions in the app.")
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        }
        .culetScreen().navigationTitle("Help").navigationBarTitleDisplayMode(.inline)
    }

    private func topic(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}

private struct AboutCuletView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Culet").font(.largeTitle)
            Text("Conversation prompts for the Lock Screen.").foregroundStyle(.secondary)
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24).culetScreen()
        .navigationTitle("About Culet").navigationBarTitleDisplayMode(.inline)
    }
}
