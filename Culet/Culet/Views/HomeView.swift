import SwiftUI

struct HomeView: View {
    @Environment(SessionStore.self) private var store
    @Binding var selection: AppTab
    @Namespace private var cards
    @State private var search = ""
    @State private var category = "All"
    @State private var path: [Situation] = []
    @State private var showingCustom = false
    @State private var customName = ""
    @State private var customScenes: [Situation] = []
    @State private var showingCustomLoadError = false
    @State private var showingCustomSaveError = false
    @ScaledMetric private var headlineSize: CGFloat = 43

    private var categories: [String] {
        var categories = SituationLibrary.categories
        if !customScenes.isEmpty {
            categories.insert(Situation.customCategory, at: 1)
        }
        return categories
    }

    private var trimmedCustomName: String {
        String(customName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60))
    }

    private var filtered: [Situation] {
        (customScenes + SituationLibrary.all).filter {
            (category == "All" || $0.category == category) &&
            (search.isEmpty || "\($0.title) \($0.subtitle) \($0.category)".localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack(spacing: 8) {
                        Image(decorative: "CuletMark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 28)
                        Text("culet").font(.system(size: 24, weight: .medium)).tracking(-1)
                        Spacer()
                    }.padding(.top, 12)

                    Text("Your next\nconversation.")
                        .font(.system(size: headlineSize, weight: .light))
                        .tracking(-2).lineSpacing(-1).padding(.vertical, 6)

                    if let session = store.session {
                        Button { selection = .session } label: {
                            HStack(spacing: 12) {
                                Circle().fill(CuletTheme.accent).frame(width: 5, height: 5)
                                Text(session.title).font(.subheadline)
                                Spacer()
                                Eyebrow(text: "Resume")
                                Image(systemName: "arrow.up.right").font(.caption)
                            }.padding(18).softPanel()
                        }.buttonStyle(.plain)
                    }

                    VStack(spacing: 18) {
                        HStack(spacing: 10) {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .light))
                                    .foregroundStyle(.white.opacity(0.5))
                                TextField("Find your occasion", text: $search)
                                    .font(.subheadline).autocorrectionDisabled()
                                    .accessibilityIdentifier("occasion-search")
                                if !search.isEmpty {
                                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                                        .accessibilityLabel("Clear search")
                                }
                            }.padding(.horizontal, 18).padding(.vertical, 15)
                                .background(.white.opacity(0.055), in: .capsule)
                                .overlay(Capsule().strokeBorder(.white.opacity(0.09), lineWidth: 0.5))

                            Button {
                                customName = search
                                showingCustom = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 17, weight: .medium))
                                    .frame(width: 48, height: 48)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Create your own occasion")
                            .accessibilityIdentifier("custom-occasion")
                        }

                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { item in
                                    Button { category = item } label: {
                                        Text(item).font(.system(size: 12, weight: .regular))
                                            .padding(.horizontal, 15).padding(.vertical, 10)
                                            .foregroundStyle(category == item ? .black : .white.opacity(0.58))
                                            .background(category == item ? Color(white: 0.93) : .clear, in: .capsule)
                                            .overlay(Capsule().strokeBorder(.white.opacity(category == item ? 0 : 0.14), lineWidth: 0.5))
                                    }.buttonStyle(.plain)
                                        .accessibilityAddTraits(category == item ? .isSelected : [])
                                }
                            }
                        }.scrollIndicators(.hidden)
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(filtered) { situation in
                            Button { path.append(situation) } label: { SituationCard(situation: situation) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("occasion-\(situation.id)")
                                .matchedTransitionSource(id: situation.id, in: cards)
                        }
                    }
                    if filtered.isEmpty { ContentUnavailableView.search(text: search) }

                }.padding(.horizontal, 22).padding(.bottom, 25)
            }
            .scrollIndicators(.hidden).culetScreen()
            .task {
                do {
                    customScenes = try CustomSceneLibrary.load()
                } catch {
                    showingCustomLoadError = true
                }
            }
            .alert("Couldn’t load your occasions", isPresented: $showingCustomLoadError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Close and reopen Culet to try again.")
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Situation.self) { situation in
                PrepareView(situation: situation) {
                    path.removeAll()
                    selection = .session
                }
                .navigationTransition(.zoom(sourceID: situation.id, in: cards))
            }
            .sheet(isPresented: $showingCustom) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 24) {
                        Eyebrow(text: "Custom scene")
                        Text("Set the scene.").font(.system(.largeTitle, weight: .light)).tracking(-1)
                        TextField("e.g. My first book club", text: $customName)
                            .padding(18).softPanel().submitLabel(.done)
                            .accessibilityIdentifier("custom-name")
                            .onSubmit(createCustomScene)
                        Button("Continue", systemImage: "arrow.right", action: createCustomScene)
                            .buttonStyle(PrimaryActionStyle())
                            .disabled(trimmedCustomName.isEmpty)
                            .opacity(trimmedCustomName.isEmpty ? 0.4 : 1)
                        Spacer()
                    }.padding(24).culetScreen()
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCustom = false } } }
                        .alert("Couldn’t save your occasion", isPresented: $showingCustomSaveError) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("Your name is still here. Try again.")
                        }
                }.presentationDetents([.medium, .large]).preferredColorScheme(.dark)
            }
        }
    }
    private func createCustomScene() {
        let name = trimmedCustomName
        guard !name.isEmpty else { return }
        let situation = Situation.custom(name)
        do {
            customScenes = try CustomSceneLibrary.add(situation)
            search = ""
            category = "All"
            showingCustom = false
            path.append(situation)
        } catch {
            showingCustomSaveError = true
        }
    }
}

private enum CustomSceneLibrary {
    private static let file = URL.applicationSupportDirectory
        .appending(path: "custom-scenes.json", directoryHint: .notDirectory)

    static func load() throws -> [Situation] {
        do {
            return try JSONDecoder().decode([Situation].self, from: Data(contentsOf: file))
        } catch CocoaError.fileReadNoSuchFile {
            return []
        }
    }

    static func add(_ scene: Situation) throws -> [Situation] {
        var scenes = try load()
        scenes.insert(scene, at: 0)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(scenes).write(to: file, options: .atomic)
        return scenes
    }
}

private struct SituationCard: View {
    let situation: Situation
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(situation.category.uppercased())
                    .font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(0.8)
                    .foregroundStyle(.white.opacity(0.65))
                Spacer(minLength: 2)
                Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .light))
            }
            Spacer(minLength: 90)
            Text(situation.title)
                .font(.system(.title3, weight: .regular)).tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .bottomLeading)
        }
        .padding(18).frame(minHeight: 208, alignment: .bottomLeading)
        .background {
            let colors = CuletPalette.sceneColors(for: situation.id, fallback: situation.colorIndex)
            CuletCardSurface(tint: colors.primary, secondaryTint: colors.secondary)
        }
        .foregroundStyle(.white)
        .contentShape(.rect(cornerRadius: 30))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(situation.title). \(situation.subtitle)")
    }
}
