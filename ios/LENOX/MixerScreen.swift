import SwiftUI

private enum MixerStyle {
    static let lime = Color(red: 0.65, green: 0.9, blue: 0.22)
    static let graphite = Color(red: 0.07, green: 0.08, blue: 0.08)
    static let panel = Color(red: 0.12, green: 0.14, blue: 0.14)
}

// Every library/playlist picker uses the same explicit live-deck confirmation.
struct DeckLoadButton: View {
    @EnvironmentObject private var audio: AudioModel
    let track: SavedTrack
    let deck: Int
    var didLoad: () -> Void = {}
    @State private var confirming = false
    @State private var request: DeckLoadRequest?
    var body: some View {
        Button("Load \(deck == 0 ? "A" : "B")") {
            request = audio.loadRequest(track.id, deck: deck)
            if audio.decks[deck].playing { confirming = true } else { load() }
        }
        .frame(minHeight: 44)
        .disabled(track.bookmark == nil || audio.libraryBlocked || !audio.active)
        .accessibilityIdentifier("load-\(deck)-" + track.title)
        .alert("Replace playing Deck \(deck == 0 ? "A" : "B")?", isPresented: $confirming) {
            Button("Replace and pause") { load() }
            Button("Cancel", role: .cancel) { request = nil }
        } message: { Text("Only this deck will be replaced. The selected track loads paused; the other deck keeps playing.") }
    }
    private func load() {
        if let request, audio.performLoad(request) { didLoad() }
        request = nil
    }
}

struct MixerScreen: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.dynamicTypeSize) private var textSize
    let exit: () -> Void
    let openLibrary: () -> Void
    @State private var focusedDeck = 0
    @State private var sheet: MixerSheet?
    enum MixerSheet: String, Identifiable { case loadA, loadB, levels, beatmatch, tools; var id: String { rawValue } }

    var body: some View {
        GeometryReader { geometry in
            let landscape = geometry.size.width > geometry.size.height && !textSize.isAccessibilitySize
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button(action: exit) { Label("Exit", systemImage: "chevron.left") }.accessibilityIdentifier("mixer-exit")
                    Spacer(minLength: 0)
                    Text("LENOX / MIXER").font(.caption.weight(.bold)).tracking(2)
                    Spacer(minLength: 0)
                    Button { sheet = .beatmatch } label: { Image(systemName: "waveform.path") }.accessibilityLabel("Beatmatch availability")
                    Button { sheet = .tools } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("Performance tools")
                }.frame(minHeight: 44)
                if landscape {
                    HStack(alignment: .top, spacing: 12) {
                        PerformanceDeck(index: 0, compact: true, load: { sheet = .loadA })
                        centralMixer.frame(width: max(130, geometry.size.width * 0.21))
                        PerformanceDeck(index: 1, compact: true, load: { sheet = .loadB })
                    }.frame(maxHeight: .infinity, alignment: .top)
                } else {
                    Picker("Focused deck", selection: $focusedDeck) {
                        Text("DECK A").tag(0); Text("DECK B").tag(1)
                    }.pickerStyle(.segmented).accessibilityIdentifier("mixer-deck-focus")
                    // Deliberately focused portrait layout; accessibility text can scroll
                    // the deck, while Exit and the crossfader remain outside that scroll.
                    ScrollView {
                        PerformanceDeck(index: focusedDeck, compact: false, load: { sheet = focusedDeck == 0 ? .loadA : .loadB })
                    }
                    HStack { deckSummary(0); Spacer(); deckSummary(1) }
                    crossfader
                    Button("Channel levels & gain") { sheet = .levels }.frame(minHeight: 44)
                }
                Text(audio.message).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                    .accessibilityIdentifier("mixer-result")
            }.padding(.horizontal, 12).padding(.bottom, 8)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .background(MixerStyle.graphite.ignoresSafeArea())
        .tint(MixerStyle.lime).foregroundStyle(.white).buttonStyle(.bordered)
        .sheet(item: $sheet) { item in
            NavigationStack {
                Group {
                    switch item {
                    case .loadA, .loadB: MixerTrackPicker(deck: item == .loadA ? 0 : 1, loaded: { sheet = nil }, openLibrary: { sheet = nil; openLibrary() })
                    case .levels: List { channelControls(0); channelControls(1) }
                    case .beatmatch:
                        List {
                            Section("Manual matching") {
                                Text("Use each deck’s tempo fader and ±50 ms jog controls to match by ear.")
                                ForEach(0..<2, id: \.self) { i in
                                    Text("Deck \(i == 0 ? "A" : "B"): BPM unknown · speed \(Int((audio.rates[i] * 100).rounded()))%")
                                }
                            }
                            Section("Analysis unavailable") { Text("Source waveforms, beat grids and tempo/phase SYNC are not implemented. No analysed values or beat alignment are inferred from the spinning platter.") }
                        }
                    case .tools:
                        List {
                            Section("Available") { Text("Independent decks, manual tempo, seek, bounded jog, gain, channel levels and crossfader.") }
                            Section("Not available in this build") { Text("Vinyl scratching, hot cues, loops, EQ, effects, sampler, recording and separate headphone cue output need their own audio implementation and device testing.") }
                            Section { Text("The platter displays playback position. Dragging seeks; it does not play decoded audio backwards.") }
                        }
                    }
                }
                .navigationTitle(item == .loadA ? "Load Deck A" : item == .loadB ? "Load Deck B" : item == .levels ? "Channel levels" : item == .beatmatch ? "Beatmatch" : "Performance tools")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { sheet = nil } } }
            }.tint(MixerStyle.lime).preferredColorScheme(.dark)
        }
    }
    private var centralMixer: some View {
        VStack(spacing: 8) {
            Text("CHANNELS").font(.caption2.bold()).tracking(2)
            ForEach(0..<2, id: \.self) { i in
                VStack(spacing: 0) {
                    Text("\(i == 0 ? "A" : "B") · \(Int(audio.channels[i] * 100))%").font(.caption.monospacedDigit())
                    Slider(value: Binding(get: { audio.channels[i] }, set: { audio.channels[i] = $0 }), in: 0...1)
                        .accessibilityLabel("Deck \(i == 0 ? "A" : "B") channel")
                }
            }
            crossfader
            HStack(spacing: 4) {
                Button("Gain") { sheet = .levels }.frame(minHeight: 44)
                Button("Pause both") { audio.pauseAll() }.frame(minHeight: 44)
            }.font(.caption)
        }
        .padding(8).background(MixerStyle.panel, in: RoundedRectangle(cornerRadius: 16))
    }
    private var crossfader: some View {
        VStack(spacing: 0) {
            HStack { Text("A"); Spacer(); Text("CROSSFADER").font(.caption2.bold()); Spacer(); Text("B") }
            Slider(value: $audio.crossfade, in: 0...1, step: 0.01)
                .accessibilityLabel("Crossfader from Deck A to Deck B").accessibilityIdentifier("crossfader")
            Text("\(Int((audio.crossfade * 100).rounded()))% toward B").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
    }
    private func deckSummary(_ i: Int) -> some View {
        VStack(alignment: .leading) {
            Text("\(i == 0 ? "A" : "B") · \(audio.decks[i].playing ? "Playing" : "Paused / idle")").font(.caption.bold())
            Text(audio.decks[i].title).font(.caption2).lineLimit(1)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private func channelControls(_ i: Int) -> some View {
        Section("Deck \(i == 0 ? "A" : "B")") {
            Text("Gain · \(Int(audio.gains[i] * 100))%")
            Slider(value: Binding(get: { audio.gains[i] }, set: { audio.gains[i] = $0 }), in: 0...1).accessibilityLabel("Deck \(i == 0 ? "A" : "B") gain")
            Text("Channel · \(Int(audio.channels[i] * 100))%")
            Slider(value: Binding(get: { audio.channels[i] }, set: { audio.channels[i] = $0 }), in: 0...1).accessibilityLabel("Deck \(i == 0 ? "A" : "B") channel")
            Text("No master limiter or independent headphone cue output.").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct MixerTrackPicker: View {
    @EnvironmentObject private var audio: AudioModel
    let deck: Int
    let loaded: () -> Void
    let openLibrary: () -> Void
    @State private var query = ""
    var body: some View {
        List {
            Button("Add or relink audio in Library", action: openLibrary)
            if audio.library.tracks.isEmpty { Text("Select audio in Library first.") }
            ForEach(audio.library.tracks.filter { StudioRoute.matches(title: $0.title, query: query) }) { track in
                VStack(alignment: .leading, spacing: 6) {
                    Text(track.title).font(.headline)
                    Text(audio.referenceStatus(track).label).font(.caption).foregroundStyle(.secondary)
                    DeckLoadButton(track: track, deck: deck, didLoad: loaded)
                }
            }
            Text(audio.message).font(.caption)
        }.searchable(text: $query, prompt: "Search tracks")
    }
}

private struct PerformanceDeck: View {
    @EnvironmentObject private var audio: AudioModel
    let index: Int
    let compact: Bool
    let load: () -> Void
    private var state: DeckState { audio.decks[index] }
    private var name: String { index == 0 ? "A" : "B" }
    var body: some View {
        VStack(spacing: compact ? 3 : 10) {
            HStack { Text("DECK " + name).font(.caption.bold()).foregroundStyle(MixerStyle.lime); Spacer(); Text(state.playing ? "PLAYING" : "PAUSED / IDLE").font(.caption2) }
            Text(state.title).font(.subheadline.weight(.semibold)).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                VinylPlatter(index: index).frame(width: compact ? 90 : 170, height: compact ? 90 : 170)
                VStack(spacing: 4) {
                    Button("Load", action: load).frame(minHeight: 44).accessibilityIdentifier("mixer-load-\(index)")
                    Text("BPM —").font(.caption).foregroundStyle(.secondary)
                    if !compact { Text("Drag to seek\nNot vinyl scratch").font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary) }
                }.frame(maxWidth: .infinity)
            }
            HStack(spacing: 6) {
                Button { state.playing ? audio.pause(index) : audio.play(index) } label: {
                    Image(systemName: state.playing ? "pause.fill" : "play.fill").frame(maxWidth: .infinity, minHeight: 28)
                }.buttonStyle(.borderedProminent).accessibilityLabel("Deck " + name + (state.playing ? " pause" : " play"))
                    .accessibilityIdentifier("mixer-play-\(index)").disabled(state.trackID == nil || !audio.active)
                Button { audio.seek(index, 0) } label: { Image(systemName: "backward.end.fill").frame(minHeight: 28) }.accessibilityLabel("Deck " + name + " seek to start").disabled(state.trackID == nil)
                Button { audio.stop(index) } label: { Image(systemName: "stop.fill").frame(minHeight: 28) }.accessibilityLabel("Deck " + name + " stop and unload").disabled(state.trackID == nil)
            }
            VStack(spacing: 0) {
                HStack { Text(StudioRoute.clock(state.position)); Spacer(); Text("−" + StudioRoute.clock(max(0, state.duration - state.position))) }.font(.caption2.monospacedDigit())
                Slider(value: Binding(get: { state.position }, set: { audio.seek(index, $0) }), in: 0...max(1, state.duration))
                    .disabled(state.trackID == nil).accessibilityLabel("Deck " + name + " seek")
            }
            VStack(spacing: 0) {
                Text("TEMPO · \(Int((audio.rates[index] * 100).rounded()))%").font(.caption.bold()).monospacedDigit()
                Slider(value: Binding(get: { audio.rates[index] }, set: { audio.setRate(index, $0) }), in: 0.5...2, step: 0.01)
                    .accessibilityLabel("Deck " + name + " playback tempo percentage")
            }
            if !compact {
                HStack {
                    Button("−50 ms") { audio.jog(index, delta: -0.05) }
                    Button("Reset tempo") { audio.setRate(index, 1) }
                    Button("+50 ms") { audio.jog(index, delta: 0.05) }
                }.disabled(state.trackID == nil).font(.caption)
            }
        }.frame(maxWidth: .infinity).padding(compact ? 6 : 12)
            .background(MixerStyle.panel, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct VinylPlatter: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let index: Int
    @State private var previousDrag: CGFloat = 0
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !audio.decks[index].playing || reduceMotion)) { _ in
            ZStack {
                Circle().fill(AngularGradient(colors: [.black, .gray.opacity(0.5), .black, .gray.opacity(0.4), .black], center: .center))
                ForEach(0..<9, id: \.self) { i in Circle().stroke(.white.opacity(0.07), lineWidth: 1).padding(CGFloat(7 + i * 3)) }
                Circle().stroke(MixerStyle.lime.opacity(audio.decks[index].playing ? 0.9 : 0.35), lineWidth: 3)
                Circle().fill(.black).padding(28)
                VStack(spacing: 2) { Text("LENOX").font(.system(size: 12, weight: .black)); Text(index == 0 ? "A" : "B").font(.caption.bold()).foregroundStyle(MixerStyle.lime) }
                VStack { Capsule().fill(MixerStyle.lime).frame(width: 3, height: 12).padding(7); Spacer() }
                    .rotationEffect(.degrees(reduceMotion ? 0 : PerformancePolicy.platterDegrees(position: audio.playbackPosition(index))))
            }
        }
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 5).onChanged { value in
            let delta = Double(value.translation.width - previousDrag) / 100
            previousDrag = value.translation.width
            audio.jog(index, delta: max(-0.25, min(0.25, delta)))
        }.onEnded { _ in previousDrag = 0 })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Deck \(index == 0 ? "A" : "B") jog seek platter")
        .accessibilityValue(audio.decks[index].playing ? "Playing" : "Paused")
        .accessibilityHint("Swipe up or down to seek by one tenth of a second. This is not vinyl scratching.")
        .accessibilityAdjustableAction { direction in
            if direction == .increment { audio.jog(index, delta: 0.1) }
            else if direction == .decrement { audio.jog(index, delta: -0.1) }
        }
        .accessibilityIdentifier("platter-\(index)")
    }
}
