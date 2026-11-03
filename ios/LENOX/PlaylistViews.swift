import SwiftUI
import UniformTypeIdentifiers

struct PlaylistDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let bytes = configuration.file.regularFileContents else { throw PlaylistFailure.invalid }
        _ = try PlaylistPolicy.decodeTransfer(bytes); data = bytes
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        _ = try PlaylistPolicy.decodeTransfer(data)
        return FileWrapper(regularFileWithContents: data)
    }
}
struct PlaylistDraft: Identifiable {
    let id = UUID()
    let playlistID: UUID?
    let revision: UInt64
    let name: String
    let tracks: [UUID]
}
struct PlaylistScreen: View {
    @EnvironmentObject private var audio: AudioModel
    let openMixer: () -> Void
    @State private var draft: PlaylistDraft?
    @State private var deleting: PlaylistDraft?
    @State private var document: PlaylistDocument?
    @State private var exporting = false
    @State private var importing = false
    var body: some View {
        VStack(spacing: 16) {
            StudioPanel {
                Text("Saved playlists").font(.headline)
                Text("Saved on this device after each confirmed edit. Original audio is never copied, moved or deleted.").font(.caption)
                Button("Create playlist") { draft = PlaylistDraft(playlistID: nil, revision: audio.library.revision, name: "", tracks: []) }
                    .disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-create")
                Button("Import playlist backup") { if audio.beginPicker() { importing = true } }
                    .disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-import")
                Text("Backups contain titles, file sizes and order only. Imported entries require Relink in Library; imports never grant file access. Android cannot read this new format yet.").font(.caption)
                if audio.libraryBlocked { Text(PlaylistFailure.locked.localizedDescription).foregroundStyle(.red) }
            }
            if audio.library.playlists.isEmpty { StudioPanel { Text("No saved playlists yet.") } }
            ForEach(audio.library.playlists) { playlist in
                StudioPanel {
                    Text(playlist.name).font(.headline)
                    Text("\(playlist.trackIDs.count) tracks").font(.caption)
                    HStack {
                        Button("Edit / rename") { draft = snapshot(playlist) }.accessibilityIdentifier("playlist-edit")
                        Button("Save backup to Files") {
                            if let data = audio.playlistBackup(playlist.id) { document = PlaylistDocument(data: data); exporting = true }
                        }.accessibilityIdentifier("playlist-export")
                    }
                    ForEach(playlist.trackIDs, id: \.self) { id in
                        if let track = audio.library.tracks.first(where: { $0.id == id }) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(track.title).font(.subheadline)
                                Text(track.bookmark == nil ? "Relink in Library before playback" : "Access checked when loading")
                                    .font(.caption2)
                                HStack {
                                    Button("Load A") { if audio.loadSaved(id, into: 0) { openMixer() } }
                                    Button("Load B") { if audio.loadSaved(id, into: 1) { openMixer() } }
                                }.disabled(track.bookmark == nil || !audio.active || audio.libraryBlocked)
                            }
                        }
                    }
                    Button("Delete playlist", role: .destructive) { deleting = snapshot(playlist) }
                        .disabled(audio.libraryBlocked)
                }
            }
            Text(audio.message).font(.caption).accessibilityIdentifier("playlist-result")
        }
        .sheet(item: $draft) { value in PlaylistEditor(draft: value).environmentObject(audio) }
        .alert("Delete playlist?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting) { value in
            Button("Delete playlist", role: .destructive) {
                if let id = value.playlistID { audio.deletePlaylist(id, revision: value.revision) }; deleting = nil
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: { value in Text("Remove \(value.name)? Library references and original music are kept.") }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json], allowsMultipleSelection: false, onCompletion: audio.acceptPlaylistBackup)
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "LENOX-playlist.json") { result in
            switch result {
            case .success: audio.message = "Playlist metadata backup saved to your selected Files destination. Audio and permissions are not included."
            case .failure(let error): audio.message = "Backup was not confirmed saved: \(error.localizedDescription)"
            }
        }
    }
    private func snapshot(_ p: SavedPlaylist) -> PlaylistDraft {
        PlaylistDraft(playlistID: p.id, revision: audio.library.revision, name: p.name, tracks: p.trackIDs)
    }
}
struct PlaylistEditor: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.dismiss) private var dismiss
    let draft: PlaylistDraft
    @State private var name: String
    @State private var order: [UUID]
    init(draft: PlaylistDraft) { self.draft = draft; _name = State(initialValue: draft.name); _order = State(initialValue: draft.tracks) }
    var body: some View {
        NavigationStack {
            List {
                Section("Playlist name") { TextField("Name (up to 80 characters)", text: $name).accessibilityIdentifier("playlist-name") }
                Section("Order — edit to move or remove") {
                    ForEach(order, id: \.self) { id in Text(audio.library.tracks.first(where: { $0.id == id })?.title ?? "Unavailable entry") }
                        .onDelete { order.remove(atOffsets: $0) }
                        .onMove { order.move(fromOffsets: $0, toOffset: $1) }
                }
                Section("Add saved track") {
                    ForEach(audio.library.tracks.filter { !order.contains($0.id) }) { track in
                        Button { order.append(track.id) } label: { Label(track.title, systemImage: "plus.circle") }
                    }
                }
                Section { Text(audio.message).font(.caption); Text("Cancel leaves the saved playlist unchanged. Missing audio references are retained, not silently removed.").font(.caption) }
            }
            .navigationTitle(draft.playlistID == nil ? "New playlist" : "Edit playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        if audio.savePlaylist(id: draft.playlistID, name: name, tracks: order, revision: draft.revision) { dismiss() }
                    }.disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-save")
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
        }
    }
}
