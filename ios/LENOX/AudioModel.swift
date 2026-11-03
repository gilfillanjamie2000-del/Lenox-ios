import AVFoundation
import Combine
import Foundation

final class SelectedTrack: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    let byteCount: Int
    private let scoped: Bool
    init(url: URL, synthetic: Bool = false) throws {
        guard url.isFileURL else { throw AudioFailure.invalidFile }
        let access = synthetic ? false : url.startAccessingSecurityScopedResource()
        let local = url.standardizedFileURL.path.hasPrefix(NSHomeDirectory() + "/")
        guard access || local else { throw AudioFailure.permission }
        do {
            let info = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard info.isRegularFile == true, let size = info.fileSize,
                  size > 0, size <= 64 * 1024 * 1024 else { throw AudioFailure.size }
            self.url = url
            self.title = url.deletingPathExtension().lastPathComponent
            self.byteCount = size
            self.scoped = access
        } catch {
            if access { url.stopAccessingSecurityScopedResource() }
            throw error
        }
    }
    deinit { if scoped { url.stopAccessingSecurityScopedResource() } }
}

enum AudioFailure: LocalizedError {
    case invalidFile, permission, size, prepare, playback, stale
    var errorDescription: String? {
        switch self {
        case .invalidFile: return "Select a local audio file. Network URLs are not supported."
        case .permission: return "File access is unavailable. Select the file again in Files."
        case .size: return "Select a downloaded, non-empty audio file no larger than 64 MiB."
        case .prepare: return "This audio file could not be decoded. Try WAV, MP3, AAC or AIFF."
        case .playback: return "Playback could not start on the current audio route."
        case .stale: return "The app state changed. Reopen LENOX and select the file again."
        }
    }
}

struct DeckState {
    var trackID: UUID?
    var title = "No track loaded"
    var playing = false
    var position: Double = 0
    var duration: Double = 0
}

@MainActor final class AudioModel: ObservableObject {
    @Published private(set) var tracks: [SelectedTrack] = []
    @Published private(set) var decks = [DeckState(), DeckState()]
    @Published var message = "Select audio in Library. Loading a deck never starts playback."
    @Published var crossfade = 0.5 { didSet { updateLevels() } }
    @Published var gains = [0.5, 0.5] { didSet { updateLevels() } }
    @Published var channels = [1.0, 1.0] { didSet { updateLevels() } }
    @Published private(set) var rates = [1.0, 1.0]
    @Published private(set) var active = false
    private var players: [AVAudioPlayer?] = [nil, nil]
    private var gate = PlaybackGate()
    private var observations = Set<AnyCancellable>()
    private var smokeStarted = false
    private(set) var pickerToken: UInt64 = 0

    init() {
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main).sink { [weak self] _ in
                self?.interrupt("Audio interruption. Resume explicitly; playback will not restart automatically.")
            }.store(in: &observations)
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .receive(on: DispatchQueue.main).sink { [weak self] note in
                let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue
                if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                    self?.interrupt("Audio output disconnected. Resume explicitly after checking your output.")
                }
            }.store(in: &observations)
    }
    func setActive(_ value: Bool) {
        active = value
        gate.setActive(value)
        if !value { pauseAll() }
        if value { runSmokeIfRequested() }
    }
    func beginPicker() -> Bool {
        guard active else { message = AudioFailure.stale.localizedDescription; return false }
        pickerToken = gate.generation
        return true
    }
    func acceptSelection(_ result: Result<[URL], Error>) {
        guard gate.accepts(pickerToken) else { message = AudioFailure.stale.localizedDescription; return }
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            guard tracks.count < 20 else { message = "This test host supports 20 session tracks. Clear the library to begin again."; return }
            let track = try SelectedTrack(url: url)
            tracks.append(track)
            message = "Selected \(track.title). Original file is read-only; access lasts for this session."
        } catch { message = error.localizedDescription }
    }
    func load(_ track: SelectedTrack, into deck: Int) {
        guard valid(deck), active, tracks.contains(where: { $0.id == track.id }) else { return }
        // Construct the candidate before releasing an existing playable deck.
        do {
            let player = try AVAudioPlayer(contentsOf: track.url)
            guard player.duration.isFinite, player.duration > 0 else { throw AudioFailure.prepare }
            player.enableRate = true
            player.rate = Float(rates[deck])
            players[deck]?.stop()
            players[deck] = player
            decks[deck] = DeckState(trackID: track.id, title: track.title, playing: false,
                                   position: 0, duration: player.duration)
            updateLevels()
            message = "Deck \(deck == 0 ? "A" : "B") loaded. Press Play when ready."
        } catch { message = "Load failed: \(error.localizedDescription)" }
    }
    func play(_ deck: Int) {
        guard valid(deck), active, let player = players[deck],
              let id = decks[deck].trackID, tracks.contains(where: { $0.id == id }) else {
            message = "Open LENOX and load an authorised track before playing."; return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            updateLevels()
            guard player.play() else { throw AudioFailure.playback }
            refresh()
        } catch { player.pause(); refresh(); message = error.localizedDescription }
    }
    func pause(_ deck: Int) { guard valid(deck) else { return }; players[deck]?.pause(); refresh() }
    func stop(_ deck: Int) {
        guard valid(deck) else { return }
        players[deck]?.stop(); players[deck] = nil; decks[deck] = DeckState()
        if players.allSatisfy({ $0?.isPlaying != true }) { deactivateSession() }
    }
    func pauseAll() {
        players.forEach { $0?.pause() }; refresh(); deactivateSession()
    }
    private func deactivateSession() {
        do { try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
        catch { message = "Audio paused; session release reported: \(error.localizedDescription)" }
    }
    private func interrupt(_ reason: String) {
        gate.invalidate(); pauseAll(); message = reason
    }
    func clearLibrary() {
        gate.invalidate(); stop(0); stop(1); tracks.removeAll()
        message = "Session library cleared. Original music was not changed."
    }
    func setRate(_ deck: Int, _ rate: Double) {
        guard valid(deck), MixPolicy.validRate(rate) else { return }
        rates[deck] = rate; players[deck]?.rate = Float(rate)
    }
    func seek(_ deck: Int, _ seconds: Double) {
        guard valid(deck), let p = players[deck], let position = MixPolicy.seek(seconds, duration: p.duration) else { return }
        p.currentTime = position; refresh()
    }
    func refresh() {
        for i in 0..<2 {
            if let player = players[i] {
                decks[i].playing = player.isPlaying
                decks[i].position = player.currentTime
                decks[i].duration = player.duration
            }
        }
    }
    private func valid(_ deck: Int) -> Bool { (0..<2).contains(deck) }
    private func updateLevels() {
        guard gains.count == 2, channels.count == 2 else { return }
        for i in 0..<2 {
            players[i]?.volume = MixPolicy.level(deck: i, crossfade: crossfade, gain: gains[i], channel: channels[i])
        }
    }

    // Explicit CI-only fixture path: never plays user audio automatically.
    private func runSmokeIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("--ci-smoke"), !smokeStarted else { return }
        smokeStarted = true
        Task { await smokeTest() }
    }
    private func smokeTest() async {
        var checks: [[String: Any]] = []
        func record(_ name: String, _ condition: Bool) { checks.append(["name": name, "passed": condition]) }
        do {
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent("lenox-synthetic-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: false)
            for (i, frequency) in [440.0, 660.0].enumerated() {
                let url = dir.appendingPathComponent("Synthetic-\(Int(frequency))Hz.wav")
                try Self.tone(frequency).write(to: url, options: .atomic)
                let track = try SelectedTrack(url: url, synthetic: true)
                tracks.append(track); load(track, into: i)
            }
            record("two synthetic WAV files decoded", decks.allSatisfy { $0.duration > 2.9 })
            record("loading never autoplays", players.allSatisfy { $0?.isPlaying == false })
            gains = [0.1, 0.1]; play(0); play(1)
            try await Task.sleep(nanoseconds: 500_000_000)
            refresh()
            record("both native players advance", decks.allSatisfy { $0.playing && $0.position > 0 })
            crossfade = 0
            record("left endpoint mutes B", players[1]?.volume == 0)
            crossfade = 1
            record("right endpoint mutes A", players[0]?.volume == 0)
            crossfade = 0.5
            setRate(0, 1.25)
            record("rate control applied", players[0]?.rate == 1.25)
            seek(1, 1)
            record("native seek applied", abs((players[1]?.currentTime ?? 0) - 1) < 0.2)
            setActive(false)
            record("background pauses both players", players.allSatisfy { $0?.isPlaying == false })
            play(0)
            record("background play rejected", players[0]?.isPlaying == false)
            setActive(true)
            record("foreground does not autoplay", players.allSatisfy { $0?.isPlaying == false })
            message = "Synthetic simulator checks finished. Physical-device and visual approval remain pending."
        } catch { checks.append(["name": "fixture execution: \(error.localizedDescription)", "passed": false]) }
        let ok = !checks.isEmpty && checks.allSatisfy { $0["passed"] as? Bool == true }
        let report: [String: Any] = ["ok": ok, "checks": checks, "kind": "iOS simulator, generated WAV only",
                                   "source": Bundle.main.object(forInfoDictionaryKey: "LENOXSourceCommit") as? String ?? "unknown",
                                   "physical_device_tested": false]
        do {
            let destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ci-smoke.json")
            try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: destination, options: .atomic)
        } catch { message = "Could not save CI evidence: \(error.localizedDescription)" }
    }
    private static func tone(_ frequency: Double) -> Data {
        let rate: UInt32 = 22_050, count = Int(rate) * 3
        var data = Data()
        func text(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { data.append(UInt8(value & 255)); data.append(UInt8(value >> 8)) }
        func u32(_ value: UInt32) { u16(UInt16(value & 65535)); u16(UInt16(value >> 16)) }
        text("RIFF"); u32(UInt32(36 + count * 2)); text("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(rate); u32(rate * 2); u16(2); u16(16); text("data"); u32(UInt32(count * 2))
        for n in 0..<count {
            let sample = Int16(sin(2 * .pi * frequency * Double(n) / Double(rate)) * 1800)
            u16(UInt16(bitPattern: sample))
        }
        return data
    }
}
