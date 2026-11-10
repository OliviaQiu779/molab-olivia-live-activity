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
    @ScaledMetric private var headlineSize: CGFloat = 43

    private var filtered: [Situation] {
        SituationLibrary.all.filter {
            (category == "All" || $0.category == category) &&
            (search.isEmpty || "\($0.title) \($0.subtitle) \($0.category)".localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    HStack {
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

                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(SituationLibrary.categories, id: \.self) { item in
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

                    HStack {
                        Eyebrow(text: "Choose a scene")
                        Spacer()
                        Text(String(format: "%02d", filtered.count))
                            .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
                    }.padding(.top, 4)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                        ForEach(filtered) { situation in
                            Button { path.append(situation) } label: { SituationCard(situation: situation) }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("occasion-\(situation.id)")
                                .matchedTransitionSource(id: situation.id, in: cards)
                        }
                    }
                    if filtered.isEmpty { ContentUnavailableView.search(text: search) }

                    Button { customName = search; showingCustom = true } label: {
                        HStack(spacing: 14) {
                            Text("Create your own").font(.subheadline)
                            Spacer()
                            Image(systemName: "plus").font(.system(size: 15, weight: .light))
                                .frame(width: 36, height: 36)
                                .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                        }.padding(18).softPanel()
                    }.buttonStyle(.plain).accessibilityIdentifier("custom-occasion")
                        .padding(.bottom, 25)
                }.padding(.horizontal, 22)
            }
            .scrollIndicators(.hidden).culetScreen()
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
                        Text("Name your occasion. We’ll start with a selection of general prompts.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        TextField("e.g. My first book club", text: $customName)
                            .padding(18).softPanel().submitLabel(.done)
                            .accessibilityIdentifier("custom-name")
                        Button("Continue", systemImage: "arrow.right") {
                            let situation = Situation.custom(String(customName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(60)))
                            showingCustom = false
                            path.append(situation)
                        }.buttonStyle(PrimaryActionStyle())
                            .disabled(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(customName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                        Spacer()
                    }.padding(24).culetScreen()
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showingCustom = false } } }
                }.presentationDetents([.medium, .large]).preferredColorScheme(.dark)
            }
        }
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
            CuletCardSurface(tint: CuletPalette.color(at: situation.colorIndex),
                             secondaryTint: CuletPalette.color(at: situation.colorIndex + 3))
        }
        .foregroundStyle(.white)
        .contentShape(.rect(cornerRadius: 30))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(situation.title). \(situation.subtitle)")
    }
}
