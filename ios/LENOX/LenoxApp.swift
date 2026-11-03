import SwiftUI
import UniformTypeIdentifiers

@main @MainActor struct LenoxApp: App {
    @StateObject private var audio = AudioModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            LaunchExperience().environmentObject(audio).preferredColorScheme(.dark)
                .onAppear { audio.setActive(scenePhase == .active) }
                .onChange(of: scenePhase) { audio.setActive($0 == .active, invalidatePending: $0 == .background) }
        }
    }
}

// Android reference: 54f01bb213a5, app/index.html. Native views, not a WebView.
// Original private artwork is deliberately NOT replaced with generated imitation.
private enum StudioStyle {
    static let ink = Color(red: 11/255, green: 16/255, blue: 32/255)
    static let panel = Color(red: 36/255, green: 32/255, blue: 68/255)
    static let outline = Color(red: 104/255, green: 80/255, blue: 167/255)
    static let cyan = Color(red: 69/255, green: 234/255, blue: 255/255)
    static let muted = Color(red: 181/255, green: 195/255, blue: 223/255)
    static let text = Color(red: 237/255, green: 242/255, blue: 255/255)
    static let background = LinearGradient(colors: [Color(red: 36/255, green: 46/255, blue: 80/255), ink], startPoint: .topLeading, endPoint: .bottomTrailing)
}
private struct StudioButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, 8)
            .foregroundStyle(enabled ? StudioStyle.text : StudioStyle.muted)
            .background(LinearGradient(colors: [StudioStyle.panel, StudioStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(StudioStyle.outline, lineWidth: 1))
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.5)
    }
}
struct StudioPanel<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(LinearGradient(colors: [StudioStyle.panel, StudioStyle.ink], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(StudioStyle.outline, lineWidth: 1))
    }
}

struct StudioView: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var route = StudioRoute.initial(arguments: ProcessInfo.processInfo.arguments)
    @State private var picker = false
    @State private var pickerMultiple = true
    @State private var search = ""
    @State private var relinking: SavedTrack?
    @State private var forgetting: SavedTrack?
    @AccessibilityFocusState private var headingFocused: Bool
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if route == .mixer {
                    MixerScreen(exit: { route = .home }, openLibrary: { route = .library })
                } else if route == .playlists {
                    PlaylistScreen(openMixer: { route = .mixer }, openLibrary: { route = .library })
                    dock
                } else {
                    if route != .home { header }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) { screen }
                            .padding(.horizontal, 16).padding(.bottom, 20)
                            .frame(maxWidth: 760).frame(maxWidth: .infinity)
                    }.id(route)
                    dock
                }
            }.frame(width: geometry.size.width, height: geometry.size.height)
                .background(StudioStyle.background.ignoresSafeArea())
        }
        .foregroundStyle(StudioStyle.text).tint(StudioStyle.cyan).buttonStyle(StudioButtonStyle())
        .sheet(isPresented: $picker) {
            AudioDocumentPicker(isPresented: $picker, multiple: pickerMultiple, completion: audio.acceptSelection)
                .interactiveDismissDisabled()
        }
        .onReceive(tick) { _ in if audio.active { audio.refresh() } }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button("‹ Home") { route = .home }.frame(width: 80).accessibilityIdentifier("pageHome")
                Text(route.title).font(.title3.bold()).accessibilityAddTraits(.isHeader).accessibilityFocused($headingFocused)
                Spacer(minLength: 0)
            }
            Text("LENOX ALPHA · OFFLINE DJ STUDIO").font(.caption2).tracking(1).foregroundStyle(StudioStyle.muted)
        }.padding(16)
    }
    @ViewBuilder private var screen: some View {
        switch route {
        case .home: home
        case .library: library
        case .mixer: EmptyView()
        case .playlists: EmptyView()
        case .occasions:
            StudioPanel {
                Text("Set the atmosphere").font(.headline)
                Text("Occasion and energy filtering require the reviewed metadata contract. Imported iOS audio currently has no reviewed occasion or energy values. No event suitability is inferred from filenames.")
                Button("Open Music Library") { route = .library }
            }
        case .assistant:
            StudioPanel {
                Text("✧ MIX ASSISTANT").font(.headline).foregroundStyle(StudioStyle.cyan)
                Text("Local BPM/key compatibility from supplied metadata. Unknown values stay unknown.")
                ForEach(0..<2, id: \.self) { i in
                    Text("DECK \(i == 0 ? "A" : "B") · \(audio.decks[i].title)").font(.subheadline)
                }
                Text("BPM — · Key — · Genre — · Energy —").font(.caption).foregroundStyle(StudioStyle.muted)
                Text("Recommendations and opposite-deck recommendation loading are not implemented on iOS yet. No match score or audio analysis is fabricated.")
                Button("Open two-deck mixer") { route = .mixer }
            }
        case .status: status
        case .more:
            StudioPanel {
                Text("Studio tools").font(.headline)
                shortcut("Mix Assistant", symbol: "sparkles", target: .assistant, identifier: "more-assistant")
                shortcut("Occasions", symbol: "calendar", target: .occasions, identifier: "more-occasions")
                shortcut("System Status", symbol: "info.circle", target: .status, identifier: "more-status")
            }
        }
    }
    private var home: some View {
        VStack(spacing: 16) {
            StudioPanel {
                if let hero = ApprovedAssets.hero {
                    Button { route = .assistant } label: {
                        Image(uiImage: hero).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }.buttonStyle(.plain)
                        .accessibilityLabel("LENOX Tap to Mix. Open Mix Assistant")
                        .accessibilityIdentifier("lenoxMix")
                } else {
                    Text("LENOX").font(.largeTitle.weight(.black)).tracking(7)
                    Text("Original Android hero artwork is unavailable.").font(.caption)
                    Button("TAP TO MIX") { route = .assistant }.accessibilityIdentifier("lenoxMix")
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: textSize.isAccessibilitySize ? 1 : 2), spacing: 10) {
                    shortcut("MUSIC LIBRARY", symbol: "music.note.list", target: .library, identifier: "lenoxLibrary")
                    shortcut("PLAYLISTS", symbol: "list.bullet", target: .playlists, identifier: "lenoxPlaylist")
                    shortcut("OCCASIONS", symbol: "sparkles", target: .occasions, identifier: "lenoxOccasion")
                    shortcut("SYSTEM STATUS", symbol: "info.circle", target: .status, identifier: "lenoxStatus")
                }
            }
            StudioPanel {
                Text("YOUR DJ STUDIO").font(.headline).tracking(2).foregroundStyle(StudioStyle.cyan)
                Text("\(audio.library.tracks.count) saved track references").font(.subheadline)
                Button("Two-deck mixer") { route = .mixer }.accessibilityIdentifier("openMixer")
                Text("Read-only selected audio. Original files remain untouched. The native file picker and system permission prompts follow iOS.").font(.caption).foregroundStyle(StudioStyle.muted)
            }
        }.padding(.top, 8)
    }
    private func shortcut(_ title: String, symbol: String, target: StudioRoute, identifier: String) -> some View {
        Button { route = target } label: {
            Label(title, systemImage: symbol).font(.caption.bold()).frame(minHeight: 60)
        }.accessibilityIdentifier(identifier)
    }
    private var library: some View {
        LazyVStack(spacing: 16) {
            StudioPanel {
                Text("Music Library").font(.headline)
                Button("Import songs from Files") { if audio.beginPicker() { pickerMultiple = true; picker = true } }.accessibilityIdentifier("selectAudio")
                    .disabled(audio.libraryBlocked)
                Text("Select one or several songs, then tap Open. No song-count or audio-file-size cap. Audio is checked before saving. You can also place songs in Files → On My iPhone → LENOX Test. Original audio stays untouched.").font(.caption)
                TextField("Search title", text: $search).textFieldStyle(.roundedBorder).accessibilityIdentifier("librarySearch")
                Text("Artist, genre, BPM and key are not imported or measured. A saved reference is not proof of current file access.").font(.caption)
                if audio.libraryBlocked { Text(PlaylistFailure.locked.localizedDescription).foregroundStyle(.red) }
                Text(audio.message).font(.caption).foregroundStyle(StudioStyle.muted)
                    .accessibilityIdentifier("import-result")
            }
            if audio.library.tracks.isEmpty {
                StudioPanel { Text("No music saved").font(.headline); Text("Select downloaded audio in Files. No demo songs are mixed into your library.") }
            } else {
                let matching = audio.library.tracks.filter { StudioRoute.matches(title: $0.title, query: search) }
                if matching.isEmpty { StudioPanel { Text("No matching tracks.") } }
                ForEach(matching) { track in
                    StudioPanel {
                        Text(track.title).font(.headline)
                        Text("\(track.byteCount) bytes · BPM/key unknown").font(.caption)
                        Text(audio.referenceStatus(track).label).font(.caption)
                        HStack {
                            DeckLoadButton(track: track, deck: 0, didLoad: { route = .mixer })
                            DeckLoadButton(track: track, deck: 1, didLoad: { route = .mixer })
                        }.disabled(track.bookmark == nil || audio.libraryBlocked || !audio.active)
                        Button("Relink audio") { relinking = track }.disabled(audio.libraryBlocked)
                        if !audio.library.playlists.contains(where: { $0.trackIDs.contains(track.id) }) {
                            Button("Forget unused reference", role: .destructive) { forgetting = track }.disabled(audio.libraryBlocked)
                        }
                        Text("Load does not play. A missing file stays in its playlists until explicitly edited.").font(.caption2)
                    }
                }
                Button("Release session file access") { audio.clearLibrary() }
                Button("Open saved playlists") { route = .playlists }
            }
            operationStatus
        }
        .alert("Relink saved track?", isPresented: Binding(get: { relinking != nil }, set: { if !$0 { relinking = nil } }), presenting: relinking) { value in
            Button("Choose replacement audio") {
                if audio.beginPicker(relinkTo: value.id) { pickerMultiple = false; picker = true }; relinking = nil
            }
            Button("Cancel", role: .cancel) { relinking = nil }
        } message: { value in Text("The file you select will replace the saved reference for \(value.title) in every playlist using it. No audio is overwritten or played automatically.") }
        .alert("Forget unused reference?", isPresented: Binding(get: { forgetting != nil }, set: { if !$0 { forgetting = nil } }), presenting: forgetting) { value in
            Button("Forget reference", role: .destructive) { audio.forgetSavedTrack(value.id); forgetting = nil }
            Button("Cancel", role: .cancel) { forgetting = nil }
        } message: { _ in Text("Only the saved reference is removed. Original audio is kept.") }
    }
    private var operationStatus: some View {
        Text(audio.message).font(.caption).foregroundStyle(StudioStyle.muted).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("operationStatus")
    }
    private var status: some View {
        VStack(spacing: 16) {
            StudioPanel {
                Text("Offline studio").font(.headline)
                Text("Native navigation and selected-file playback; no server connection, microphone or telemetry.")
                Text("This is an Android-reference alignment candidate, not verified visual or functional parity.")
            }
            StudioPanel {
                Text("Build and evidence").font(.headline)
                Text("Source: " + (Bundle.main.object(forInfoDictionaryKey: "LENOXSourceCommit") as? String ?? "local-unrecorded")).font(.caption.monospaced()).textSelection(.enabled)
                Text("Unsigned test build. iPhone signing, physical-device testing and independent review remain required.")
                Text("Saved playlists, metadata backups and the native performance mixer are implemented. Analysis, EQ, SYNC and vinyl scratching are not implemented. Device acceptance is still pending.")
            }
        }
    }
    private var dock: some View {
        HStack(spacing: 4) {
            dockItem("Home", symbol: "house", target: .home)
            dockItem("Library", symbol: "music.note.list", target: .library)
            dockItem("Playlists", symbol: "list.bullet", target: .playlists)
            dockItem("Mixer", symbol: "slider.horizontal.3", target: .mixer)
            dockItem("More", symbol: "ellipsis", target: .more)
        }.padding(.horizontal, 8).padding(.vertical, 6)
            .background(StudioStyle.ink)
            .overlay(alignment: .top) { Rectangle().fill(StudioStyle.outline).frame(height: 1) }
    }
    private func dockItem(_ title: String, symbol: String, target: StudioRoute) -> some View {
        Button { route = target } label: {
            VStack(spacing: 3) { Image(systemName: symbol); Text(title).font(.caption2) }
                .foregroundStyle(route == target ? StudioStyle.cyan : StudioStyle.muted)
                .frame(maxWidth: .infinity, minHeight: 48)
        }.buttonStyle(.plain).accessibilityIdentifier("dock-" + target.rawValue)
            .accessibilityAddTraits(route == target ? .isSelected : [])
    }
}
