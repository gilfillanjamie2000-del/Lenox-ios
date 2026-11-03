import AVFoundation
import Combine
import Foundation

final class SelectedTrack: Identifiable {
    let id: UUID
    let url: URL
    let title: String
    let byteCount: Int
    private let scoped: Bool
    init(url: URL, synthetic: Bool = false, id: UUID = UUID()) throws {
        self.id = id
        guard url.isFileURL else { throw AudioFailure.invalidFile }
        let access = synthetic ? false : url.startAccessingSecurityScopedResource()
        let local = url.resolvingSymlinksInPath().standardizedFileURL.path.hasPrefix(NSHomeDirectory() + "/")
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
    @Published var message = "Select audio in Library. Playlists and file references save locally; original music stays untouched."
    @Published private(set) var library = LibraryState()
    @Published private(set) var libraryBlocked = false
    private let libraryStore: PlaylistStore = {
        let fm = FileManager.default
        var root = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LENOX", isDirectory: true)
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--ci-playlists-") }) {
            root = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlaylistTest", isDirectory: true)
        }
        #endif
        return PlaylistStore(file: PlaylistDiskFile(url: root.appendingPathComponent("library-v1.json")))
    }()
    private var relinkID: UUID?
    private var pickerRevision: UInt64 = 0
    private var playlistSmokeStarted = false
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
        library = libraryStore.state; libraryBlocked = libraryStore.blocked
        if libraryBlocked { message = PlaylistFailure.locked.localizedDescription }
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
        if value { runSmokeIfRequested(); runPlaylistSmokeIfRequested() }
    }
    func beginPicker(relinkTo id: UUID? = nil) -> Bool {
        guard active, !libraryBlocked else { message = "Open LENOX with readable saved metadata before choosing files."; return false }
        if let id = id, !library.tracks.contains(where: { $0.id == id }) { return false }
        pickerToken = gate.generation; pickerRevision = library.revision; relinkID = id
        return true
    }
    func acceptSelection(_ result: Result<[URL], Error>) {
        guard gate.accepts(pickerToken) else { message = AudioFailure.stale.localizedDescription; return }
        defer { relinkID = nil }
        do {
            guard let url = try result.get().first else { return }
            let track = try SelectedTrack(url: url, id: relinkID ?? UUID())
            try persistSelected(track, replacing: relinkID, revision: pickerRevision)
            message = "Saved reference to \(track.title). Original audio was not copied or changed. Load a deck explicitly."
        } catch { syncLibrary(); message = error.localizedDescription }
    }
    private func persistSelected(_ track: SelectedTrack, replacing: UUID?, revision: UInt64) throws {
        let bookmark = try coordinatedRead(track.url) { url in
            try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        try libraryStore.saveTrack(SavedTrack(id: track.id, title: track.title, byteCount: track.byteCount, bookmark: bookmark),
                                   replacing: replacing, revision: revision)
        // Publish and release obsolete players only after the metadata save succeeds.
        if let id = replacing {
            for i in 0..<2 where decks[i].trackID == id { stop(i) }
            tracks.removeAll { $0.id == id }
        }
        tracks.append(track); syncLibrary()
    }
    private func syncLibrary() { library = libraryStore.state; libraryBlocked = libraryStore.blocked }
    @discardableResult private func saveAction(_ messageOnSuccess: String, _ action: () throws -> Void) -> Bool {
        do { try action(); syncLibrary(); message = messageOnSuccess; return true }
        catch { syncLibrary(); message = error.localizedDescription; return false }
    }
    @discardableResult func savePlaylist(id: UUID?, name: String, tracks: [UUID], revision: UInt64) -> Bool {
        saveAction("Playlist saved on this device. Original music is unchanged.") {
            if let id = id { try libraryStore.edit(id: id, name: name, tracks: tracks, revision: revision) }
            else { try libraryStore.create(name: name, tracks: tracks, revision: revision) }
        }
    }
    @discardableResult func deletePlaylist(_ id: UUID, revision: UInt64) -> Bool {
        saveAction("Playlist removed. Library references and original audio were not deleted.") {
            try libraryStore.delete(id: id, revision: revision)
        }
    }
    func forgetSavedTrack(_ id: UUID) {
        if saveAction("Saved reference removed. Original file is unchanged.", { try libraryStore.forgetTrack(id: id, revision: library.revision) }) {
            for i in 0..<2 where decks[i].trackID == id { stop(i) }; tracks.removeAll { $0.id == id }
        }
    }
    @discardableResult func loadSaved(_ id: UUID, into deck: Int, play: Bool = false) -> Bool {
        guard active, !libraryBlocked, let saved = library.tracks.first(where: { $0.id == id }) else { return false }
        do {
            // Resolve only at the user's request. A stored bookmark is not proof of current access.
            let selected: SelectedTrack
            if let existing = tracks.first(where: { $0.id == id }) { selected = existing }
            else {
                guard let data = saved.bookmark else { throw AudioFailure.permission }
                var stale = false
                let url = try URL(resolvingBookmarkData: data, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &stale)
                guard !stale else { throw AudioFailure.stale }
                selected = try SelectedTrack(url: url, id: id)
                guard selected.byteCount == saved.byteCount else { throw AudioFailure.stale }
                tracks.append(selected)
            }
            return play ? loadAndPlay(selected, into: deck) : load(selected, into: deck)
        } catch { message = "File unavailable or changed. Relink in Library; the playlist entry is retained."; return false }
    }
    func playlistBackup(_ id: UUID) -> Data? {
        do { return try libraryStore.export(id: id) }
        catch { message = error.localizedDescription; return nil }
    }
    func acceptPlaylistBackup(_ result: Result<[URL], Error>) {
        guard gate.accepts(pickerToken) else { message = AudioFailure.stale.localizedDescription; return }
        do {
            guard let url = try result.get().first, url.isFileURL else { throw PlaylistFailure.invalid }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            guard scoped || url.resolvingSymlinksInPath().path.hasPrefix(NSHomeDirectory() + "/") else { throw AudioFailure.permission }
            let data = try coordinatedRead(url) { item in
                let handle = try FileHandle(forReadingFrom: item); defer { try? handle.close() }
                return try handle.read(upToCount: PlaylistPolicy.maxBytes + 1) ?? Data()
            }
            _ = saveAction("Imported playlist metadata. Relink each track in Library; backup files do not grant audio access.") {
                try libraryStore.importBackup(data, revision: pickerRevision)
            }
        } catch { message = error.localizedDescription }
    }
    private func coordinatedRead<T>(_ url: URL, _ read: (URL) throws -> T) throws -> T {
        var coordinationError: NSError?, outcome: Result<T, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordinationError) { item in
            outcome = Result { try read(item) }
        }
        if let error = coordinationError { throw error }
        guard let outcome = outcome else { throw AudioFailure.invalidFile }; return try outcome.get()
    }
    @discardableResult func load(_ track: SelectedTrack, into deck: Int) -> Bool {
        guard valid(deck), active, tracks.contains(where: { $0.id == track.id }) else { return false }
        // Construct the candidate before releasing an existing playable deck.
        do {
            let player = try coordinatedRead(track.url) { item -> AVAudioPlayer in
                let info = try item.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                guard info.isRegularFile == true, info.fileSize == track.byteCount else { throw AudioFailure.stale }
                return try AVAudioPlayer(contentsOf: item)
            }
            guard player.duration.isFinite, player.duration > 0 else { throw AudioFailure.prepare }
            player.enableRate = true
            player.rate = Float(rates[deck])
            players[deck]?.stop()
            players[deck] = player
            decks[deck] = DeckState(trackID: track.id, title: track.title, playing: false,
                                   position: 0, duration: player.duration)
            updateLevels()
            message = "Deck \(deck == 0 ? "A" : "B") loaded. Press Play when ready."
            return true
        } catch { message = "Load failed: \(error.localizedDescription)"; return false }
    }
    // This combined action is explicit. A failed load must never play an old deck.
    @discardableResult func loadAndPlay(_ track: SelectedTrack, into deck: Int) -> Bool {
        guard load(track, into: deck) else { return false }
        play(deck)
        return decks[deck].playing
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
    @discardableResult func loadAndPlay(_ track: SavedTrack, into deck: Int) -> Bool { loadSaved(track.id, into: deck, play: true) }
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
        message = "Session access released. Saved playlists and references remain; originals were not changed."
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
            gains = [0.1, 0.1]
            record("explicit load-and-play starts selected deck", loadAndPlay(tracks[0], into: 0))
            play(1)
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
            let unselected = try SelectedTrack(url: tracks[0].url, synthetic: true)
            let previousID = decks[0].trackID
            record("unselected load-and-play rejected without playing old deck",
                   !loadAndPlay(unselected, into: 0) && decks[0].trackID == previousID && players[0]?.isPlaying == false)
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
    private func runPlaylistSmokeIfRequested() {
        #if targetEnvironment(simulator)
        let args = ProcessInfo.processInfo.arguments
        guard !playlistSmokeStarted, args.contains("--ci-playlists-write") || args.contains("--ci-playlists-read") else { return }
        playlistSmokeStarted = true
        var checks: [[String: Any]] = []
        func record(_ name: String, _ value: Bool) { checks.append(["name": name, "passed": value]) }
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let phase = args.contains("--ci-playlists-write") ? "write" : "read"
        do {
            if phase == "write" {
                guard library.tracks.isEmpty && library.playlists.isEmpty else { throw PlaylistFailure.invalid }
                for hz in [440.0, 660.0] {
                    let url = directory.appendingPathComponent("Playlist-fixture-\(Int(hz)).wav")
                    try Self.tone(hz).write(to: url, options: .atomic)
                    let track = try SelectedTrack(url: url, synthetic: true)
                    try persistSelected(track, replacing: nil, revision: library.revision)
                }
                record("two native bookmarks saved", library.tracks.count == 2 && library.tracks.allSatisfy { $0.bookmark != nil })
                record("create playlist through app adapter", savePlaylist(id: nil, name: "Saved set", tracks: library.tracks.map(\.id), revision: library.revision))
                let p = library.playlists[0]
                record("rename and reorder through adapter", savePlaylist(id: p.id, name: "Night set", tracks: Array(p.trackIDs.reversed()), revision: library.revision))
                let backup = try libraryStore.export(id: p.id)
                try backup.write(to: directory.appendingPathComponent("playlist-backup.json"), options: .atomic)
                record("backup omits bookmarks", !String(decoding: backup, as: UTF8.self).contains("bookmark"))
                record("save does not autoplay", decks.allSatisfy { !$0.playing })
            } else {
                record("state survives actual process relaunch", library.tracks.count == 2 && library.playlists.count == 1)
                guard let p = library.playlists.first else { throw PlaylistFailure.missing }
                record("saved name and order restored", p.name == "Night set" && p.trackIDs == library.tracks.map(\.id).reversed().map { $0 })
                record("no automatic access or playback", tracks.isEmpty && decks.allSatisfy { !$0.playing })
                record("bookmark resolves for explicit native load", loadSaved(p.trackIDs[0], into: 0))
                record("restored load does not autoplay", !decks[0].playing && decks[0].duration > 2.9)
                let backup = try Data(contentsOf: directory.appendingPathComponent("playlist-backup.json"))
                var transfer = try PlaylistPolicy.decodeTransfer(backup)
                transfer = PlaylistTransfer(name: "Imported set", tracks: transfer.tracks)
                let importedURL = directory.appendingPathComponent("imported-playlist.json")
                try PlaylistPolicy.encode(transfer).write(to: importedURL, options: .atomic)
                guard beginPicker() else { throw AudioFailure.stale }
                acceptPlaylistBackup(.success([importedURL]))
                record("metadata import does not restore authorisation", library.tracks.count == 4 && library.playlists.count == 2 && library.tracks.suffix(2).allSatisfy { $0.bookmark == nil })
                let previous = decks[0].trackID
                record("unlinked imported track rejected; old deck unchanged", !loadSaved(library.tracks.last!.id, into: 0, play: true) && decks[0].trackID == previous && !decks[0].playing)
            }
        } catch { record("runtime exception: \(error.localizedDescription)", false) }
        let report: [String: Any] = ["source": Bundle.main.object(forInfoDictionaryKey: "LENOXSourceCommit") as? String ?? "unknown", "phase": phase, "checks": checks, "ok": !checks.isEmpty && checks.allSatisfy { $0["passed"] as? Bool == true }, "physical_device_tested": false]
        do { try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: directory.appendingPathComponent("playlist-\(phase).json"), options: .atomic) }
        catch { message = "Could not write playlist CI report." }
        #endif
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
