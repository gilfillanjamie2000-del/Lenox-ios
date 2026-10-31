import SwiftUI
import UniformTypeIdentifiers

@main @MainActor struct LenoxApp: App {
    @StateObject private var audio = AudioModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            StudioView().environmentObject(audio).preferredColorScheme(.dark)
                .onAppear { audio.setActive(scenePhase == .active) }
                .onChange(of: scenePhase) { audio.setActive($0 == .active) }
        }
    }
}

struct StudioView: View {
    @EnvironmentObject private var audio: AudioModel
    @State private var tab = ProcessInfo.processInfo.arguments.contains("--ci-smoke") ? 2 : 0
    @State private var picker = false
    private let tick = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                List {
                    Section {
                        Text("LENOX").font(.largeTitle.bold()).foregroundStyle(.cyan)
                        Text("iOS audio test · 0.1.0").font(.headline)
                        Text("A native test host following the Android library and two-deck workflow. This is not the approved final interface.")
                    }
                    Section("This test build") {
                        Label("\(audio.tracks.count) selected session tracks", systemImage: "music.note.list")
                        Button("Open Library") { tab = 1 }
                        Button("Open two-deck mixer") { tab = 2 }
                    }
                    Section("Not implemented yet") {
                        Text("Saved playlists, AI recommendations, measured BPM/key, beat-aligned SYNC, EQ, waveforms and Android artwork parity.")
                    }
                    Section("Safety") { Text("Files are read-only. No microphone, streaming, telemetry or background playback. Keep monitoring volume low.") }
                }.navigationTitle("LENOX Test")
            }.tabItem { Label("Home", systemImage: "house") }.tag(0)
            NavigationStack {
                List {
                    Section {
                        Button("Select audio from Files") { if audio.beginPicker() { picker = true } }
                            .accessibilityIdentifier("selectAudio")
                        Text("One file at a time; up to 20 files, 64 MiB each. Selection and access are session-only.").font(.caption)
                    }
                    Section("Selected tracks") {
                        if audio.tracks.isEmpty { Text("No files selected. Nothing is scanned automatically.").foregroundStyle(.secondary) }
                        ForEach(audio.tracks) { track in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(track.title).font(.headline)
                                Text("\(track.byteCount) bytes · BPM/key unknown").font(.caption).foregroundStyle(.secondary)
                                HStack {
                                    Button("Load A") { audio.load(track, into: 0); tab = 2 }.buttonStyle(.bordered)
                                    Button("Load B") { audio.load(track, into: 1); tab = 2 }.buttonStyle(.bordered)
                                }
                            }.padding(.vertical, 4)
                        }
                    }
                    Section { Button("Clear session library", role: .destructive) { audio.clearLibrary() }.disabled(audio.tracks.isEmpty) }
                    Section("Status") { Text(audio.message).font(.caption) }
                }.navigationTitle("Music Library")
            }.tabItem { Label("Library", systemImage: "music.note.list") }.tag(1)
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Native playback test — not beat-synchronised").font(.caption).foregroundStyle(.secondary)
                        DeckView(index: 0); DeckView(index: 1)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CROSSFADER").font(.headline)
                            Slider(value: $audio.crossfade, in: 0...1).accessibilityLabel("Crossfader")
                            HStack { Text("A"); Spacer(); Text("B") }
                            Text("Centre-full curve matches the Android reference. Combined output can clip; no limiter is implemented.").font(.caption).foregroundStyle(.secondary)
                        }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        Button("Pause both decks") { audio.pauseAll() }.buttonStyle(.borderedProminent)
                        Text(audio.message).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                    }.padding()
                }.navigationTitle("Two Decks")
            }.tabItem { Label("Mixer", systemImage: "slider.horizontal.3") }.tag(2)
            NavigationStack {
                List {
                    Section("Build identity") {
                        Text("Unsigned test candidate — not App Store or TestFlight ready")
                        Text("Source: " + (Bundle.main.object(forInfoDictionaryKey: "LENOXSourceCommit") as? String ?? "local-unrecorded")).font(.caption.monospaced()).textSelection(.enabled)
                    }
                    Section("Verification boundaries") {
                        Text("A successful compile is not a phone test. Simulator evidence uses generated tones, never your music.")
                        Text("Real iPhone Files permissions, route changes, interruptions, playback quality and visual acceptance remain pending.")
                    }
                    Section("Cross-platform work") {
                        Text("Portable mixer tests and a continuation handover live with this source. Android is unchanged.")
                        Text("Final design and shared AI contracts require independent review and Jamie's integration decision.")
                    }
                }.navigationTitle("Project Status")
            }.tabItem { Label("Status", systemImage: "checklist") }.tag(3)
        }
        .tint(.cyan)
        .fileImporter(isPresented: $picker, allowedContentTypes: [.audio], allowsMultipleSelection: false, onCompletion: audio.acceptSelection)
        .onReceive(tick) { _ in if audio.active { audio.refresh() } }
    }
}

struct DeckView: View {
    @EnvironmentObject private var audio: AudioModel
    let index: Int
    private var state: DeckState { audio.decks[index] }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(index == 0 ? "DECK A" : "DECK B").font(.headline).foregroundStyle(.cyan)
                Spacer(); Text(state.playing ? "Playing" : state.trackID == nil ? "Empty" : "Ready / paused").font(.caption)
            }
            Text(state.title).font(.subheadline).lineLimit(2)
            Menu("Load track") {
                ForEach(audio.tracks) { track in Button(track.title) { audio.load(track, into: index) } }
            }.disabled(audio.tracks.isEmpty)
            HStack {
                Button("Play") { audio.play(index) }.disabled(state.trackID == nil || !audio.active)
                Button("Pause") { audio.pause(index) }.disabled(!state.playing)
                Button("Stop") { audio.stop(index) }.disabled(state.trackID == nil)
            }.buttonStyle(.bordered)
            Slider(value: Binding(get: { state.position }, set: { audio.seek(index, $0) }), in: 0...max(1, state.duration))
                .disabled(state.trackID == nil).accessibilityLabel("Deck \(index == 0 ? "A" : "B") position")
            Text(String(format: "%.1f / %.1f seconds", state.position, state.duration)).font(.caption.monospacedDigit())
            Text("Gain \(Int(audio.gains[index] * 100))% · Channel \(Int(audio.channels[index] * 100))%").font(.caption)
            Slider(value: Binding(get: { audio.gains[index] }, set: { audio.gains[index] = $0 }), in: 0...1).accessibilityLabel("Deck gain")
            Slider(value: Binding(get: { audio.channels[index] }, set: { audio.channels[index] = $0 }), in: 0...1).accessibilityLabel("Channel volume")
            Text("Manual speed \(Int(audio.rates[index] * 100))% — not SYNC").font(.caption)
            Slider(value: Binding(get: { audio.rates[index] }, set: { audio.setRate(index, $0) }), in: 0.5...2, step: 0.05).accessibilityLabel("Playback speed")
        }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
