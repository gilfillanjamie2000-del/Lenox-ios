import Foundation

// Versioned metadata only. Bookmarks are private capabilities, never backup fields.
struct SavedTrack: Codable, Equatable, Identifiable {
    let id: UUID
    var title: String
    var byteCount: Int
    var bookmark: Data?
}
struct SavedPlaylist: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var trackIDs: [UUID]
}
struct LibraryState: Codable, Equatable {
    var format = "lenox-ios-library"
    var version = 1
    var revision: UInt64 = 0
    var tracks: [SavedTrack] = []
    var playlists: [SavedPlaylist] = []
}
struct PlaylistTransfer: Codable, Equatable {
    struct Track: Codable, Equatable { let title: String; let byteCount: Int }
    var format = "lenox-playlist"
    var version = 1
    let name: String
    let tracks: [Track]
}
enum PlaylistFailure: LocalizedError {
    case invalid, collision, stale, limit, locked, missing, referenced
    var errorDescription: String? {
        switch self {
        case .invalid: return "Invalid or unsupported playlist data. Nothing was replaced."
        case .collision: return "That playlist name already exists. Open it to edit; it was not overwritten."
        case .stale: return "The saved library changed. Reopen the editor before saving."
        case .limit: return "This test version supports 20 saved tracks and 100 playlists."
        case .locked: return "Saved library cannot be read safely. Writes are blocked; the existing file is preserved."
        case .missing: return "Saved entry not found. Nothing was changed."
        case .referenced: return "Remove this track from its playlists before forgetting it."
        }
    }
}
enum PlaylistPolicy {
    static let maxBytes = 4 * 1024 * 1024
    static let maxTracks = 20
    static let maxPlaylists = 100
    static let maxAudioBytes = 64 * 1024 * 1024
    static func key(_ name: String) -> String { name.precomposedStringWithCompatibilityMapping.lowercased() }
    static func validText(_ text: String, max: Int) -> Bool {
        !text.isEmpty && text.utf16.count <= max && text == text.trimmingCharacters(in: .whitespacesAndNewlines) &&
        !text.unicodeScalars.contains { CharacterSet.controlCharacters.contains($0) || $0.properties.generalCategory == .format }
    }
    static func validate(_ state: LibraryState) throws {
        guard state.format == "lenox-ios-library", state.version == 1,
              state.tracks.count <= maxTracks, state.playlists.count <= maxPlaylists else { throw PlaylistFailure.invalid }
        let ids = Set(state.tracks.map(\.id))
        guard ids.count == state.tracks.count, Set(state.playlists.map(\.id)).count == state.playlists.count else { throw PlaylistFailure.invalid }
        var names = Set<String>()
        for t in state.tracks {
            guard validText(t.title, max: 512), (1...maxAudioBytes).contains(t.byteCount),
                  t.bookmark == nil || (1...131072).contains(t.bookmark!.count) else { throw PlaylistFailure.invalid }
        }
        for p in state.playlists {
            guard validText(p.name, max: 80), names.insert(key(p.name)).inserted,
                  Set(p.trackIDs).count == p.trackIDs.count, Set(p.trackIDs).isSubset(of: ids) else { throw PlaylistFailure.invalid }
        }
    }
    static func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        guard data.count <= maxBytes else { throw PlaylistFailure.limit }; return data
    }
    // Reject unknown fields, including injected URLs/bookmarks, before decoding a backup.
    static func decodeTransfer(_ data: Data) throws -> PlaylistTransfer {
        guard !data.isEmpty, data.count <= maxBytes,
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys) == Set(["format", "version", "name", "tracks"]),
              let rows = object["tracks"] as? [[String: Any]], rows.count <= maxTracks,
              rows.allSatisfy({ Set($0.keys) == Set(["title", "byteCount"]) }) else { throw PlaylistFailure.invalid }
        let value = try JSONDecoder().decode(PlaylistTransfer.self, from: data)
        guard value.format == "lenox-playlist", value.version == 1, validText(value.name, max: 80),
              value.tracks.allSatisfy({ validText($0.title, max: 512) && (1...maxAudioBytes).contains($0.byteCount) }) else { throw PlaylistFailure.invalid }
        return value
    }
}
protocol PlaylistFileIO {
    func read() throws -> Data?
    func write(_ data: Data) throws
}
struct PlaylistDiskFile: PlaylistFileIO {
    let url: URL
    func read() throws -> Data? {
        let attrs: [FileAttributeKey: Any]
        do { attrs = try FileManager.default.attributesOfItem(atPath: url.path) }
        catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile { return nil }
        guard attrs[.type] as? FileAttributeType == .typeRegular else { throw PlaylistFailure.invalid }
        let file = try FileHandle(forReadingFrom: url); defer { try? file.close() }
        let data = try file.read(upToCount: PlaylistPolicy.maxBytes + 1) ?? Data()
        guard !data.isEmpty, data.count <= PlaylistPolicy.maxBytes else { throw PlaylistFailure.invalid }; return data
    }
    func write(_ data: Data) throws {
        guard data.count <= PlaylistPolicy.maxBytes else { throw PlaylistFailure.limit }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }
}
// Single app-process owner; AudioModel calls only on MainActor. Not a distributed lock.
final class PlaylistStore {
    private let file: PlaylistFileIO
    private var diskBytes: Data?
    private(set) var state = LibraryState()
    private(set) var blocked = false
    init(file: PlaylistFileIO) {
        self.file = file
        do {
            diskBytes = try file.read()
            if let data = diskBytes {
                let loaded = try JSONDecoder().decode(LibraryState.self, from: data)
                try PlaylistPolicy.validate(loaded); state = loaded
            }
        } catch { blocked = true }
    }
    private func transact(_ revision: UInt64, _ change: (inout LibraryState) throws -> Void) throws {
        guard !blocked else { throw PlaylistFailure.locked }
        guard revision == state.revision, revision < UInt64.max else { throw PlaylistFailure.stale }
        // Never overwrite externally changed or newly unreadable metadata.
        guard try file.read() == diskBytes else { blocked = true; throw PlaylistFailure.stale }
        var candidate = state
        try change(&candidate); candidate.revision += 1
        try PlaylistPolicy.validate(candidate)
        let bytes = try PlaylistPolicy.encode(candidate)
        try file.write(bytes) // State changes only AFTER an atomic save succeeds.
        diskBytes = bytes; state = candidate
    }
    func saveTrack(_ track: SavedTrack, replacing: UUID? = nil, revision: UInt64) throws {
        try transact(revision) { s in
            if let id = replacing {
                guard track.id == id, let i = s.tracks.firstIndex(where: { $0.id == id }) else { throw PlaylistFailure.missing }
                s.tracks[i] = track
            } else {
                guard s.tracks.count < PlaylistPolicy.maxTracks else { throw PlaylistFailure.limit }
                guard !s.tracks.contains(where: { $0.id == track.id }) else { throw PlaylistFailure.invalid }
                s.tracks.append(track)
            }
        }
    }
    @discardableResult func create(name: String, tracks: [UUID], revision: UInt64) throws -> UUID {
        let id = UUID()
        try transact(revision) { s in
            guard s.playlists.count < PlaylistPolicy.maxPlaylists else { throw PlaylistFailure.limit }
            guard !s.playlists.contains(where: { PlaylistPolicy.key($0.name) == PlaylistPolicy.key(name) }) else { throw PlaylistFailure.collision }
            s.playlists.append(SavedPlaylist(id: id, name: name, trackIDs: tracks))
        }; return id
    }
    func edit(id: UUID, name: String, tracks: [UUID], revision: UInt64) throws {
        try transact(revision) { s in
            guard let i = s.playlists.firstIndex(where: { $0.id == id }) else { throw PlaylistFailure.missing }
            guard !s.playlists.contains(where: { $0.id != id && PlaylistPolicy.key($0.name) == PlaylistPolicy.key(name) }) else { throw PlaylistFailure.collision }
            s.playlists[i].name = name; s.playlists[i].trackIDs = tracks
        }
    }
    func delete(id: UUID, revision: UInt64) throws {
        try transact(revision) { s in
            guard let i = s.playlists.firstIndex(where: { $0.id == id }) else { throw PlaylistFailure.missing }
            s.playlists.remove(at: i) // Never delete tracks or audio.
        }
    }
    func forgetTrack(id: UUID, revision: UInt64) throws {
        try transact(revision) { s in
            guard !s.playlists.contains(where: { $0.trackIDs.contains(id) }) else { throw PlaylistFailure.referenced }
            guard let i = s.tracks.firstIndex(where: { $0.id == id }) else { throw PlaylistFailure.missing }
            s.tracks.remove(at: i)
        }
    }
    func export(id: UUID) throws -> Data {
        guard !blocked, let p = state.playlists.first(where: { $0.id == id }) else { throw PlaylistFailure.missing }
        let tracks = try p.trackIDs.map { id -> PlaylistTransfer.Track in
            guard let t = state.tracks.first(where: { $0.id == id }) else { throw PlaylistFailure.missing }
            return PlaylistTransfer.Track(title: t.title, byteCount: t.byteCount)
        }
        return try PlaylistPolicy.encode(PlaylistTransfer(name: p.name, tracks: tracks))
    }
    @discardableResult func importBackup(_ data: Data, revision: UInt64) throws -> UUID {
        let transfer = try PlaylistPolicy.decodeTransfer(data), id = UUID()
        try transact(revision) { s in
            guard s.tracks.count + transfer.tracks.count <= PlaylistPolicy.maxTracks,
                  s.playlists.count < PlaylistPolicy.maxPlaylists else { throw PlaylistFailure.limit }
            guard !s.playlists.contains(where: { PlaylistPolicy.key($0.name) == PlaylistPolicy.key(transfer.name) }) else { throw PlaylistFailure.collision }
            // Imports NEVER inherit a bookmark or auto-match existing file access.
            let tracks = transfer.tracks.map { SavedTrack(id: UUID(), title: $0.title, byteCount: $0.byteCount, bookmark: nil) }
            s.tracks.append(contentsOf: tracks)
            s.playlists.append(SavedPlaylist(id: id, name: transfer.name, trackIDs: tracks.map(\.id)))
        }; return id
    }
}
