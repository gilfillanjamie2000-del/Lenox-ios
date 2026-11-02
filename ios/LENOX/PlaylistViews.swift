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
    let openLibrary: () -> Void
    @State private var query = ""
    @State private var draft: PlaylistDraft?
    @State private var importing = false

    var body: some View {
        NavigationStack {
            List {
                if audio.libraryBlocked {
                    Section { Label(PlaylistFailure.locked.localizedDescription, systemImage: "lock.shield").foregroundStyle(.orange) }
                }
                Section {
                    Button { draft = PlaylistDraft(playlistID: nil, revision: audio.library.revision, name: "", tracks: []) } label: {
                        Label("Create playlist", systemImage: "plus.circle.fill")
                    }.disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-create")
                    Button { if audio.beginPicker() { importing = true } } label: {
                        Label("Import playlist backup", systemImage: "square.and.arrow.down")
                    }.disabled(audio.libraryBlocked || !audio.active).accessibilityIdentifier("playlist-import")
                } footer: {
                    Text("Your playlists stay on this device. Backups contain track names and order, not songs or file permissions.")
                }
                Section("Your sets · \(audio.library.playlists.count)") {
                    if audio.library.playlists.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Your next set starts here", systemImage: "music.note.list").font(.headline)
                            Text("Create a playlist, add tracks from your library, then save. You can change the order at any time.").font(.subheadline).foregroundStyle(.secondary)
                        }.padding(.vertical, 12)
                    } else {
                        let matches = audio.library.playlists.filter { StudioRoute.matches(title: $0.name, query: query) }
                        if matches.isEmpty { Text("No playlists match your search.").foregroundStyle(.secondary) }
                        ForEach(matches) { playlist in
                            NavigationLink(value: playlist.id) {
                                HStack(spacing: 14) {
                                    Image(systemName: "square.stack.fill").font(.title2).foregroundStyle(.cyan).frame(width: 40)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(playlist.name).font(.headline)
                                        Text("\(playlist.trackIDs.count) tracks").font(.caption).foregroundStyle(.secondary)
                                    }
                                }.padding(.vertical, 8)
                            }.accessibilityIdentifier("playlist-row-" + playlist.name)
                        }
                    }
                }
                Section { Text(audio.message).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("playlist-result") }
            }
            .navigationTitle("Playlists")
            .searchable(text: $query, prompt: "Search playlists")
            .navigationDestination(for: UUID.self) { id in
                PlaylistDetails(playlistID: id, openMixer: openMixer, openLibrary: openLibrary)
            }
            .sheet(item: $draft) { PlaylistEditor(draft: $0).environmentObject(audio) }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json], allowsMultipleSelection: false, onCompletion: audio.acceptPlaylistBackup)
        }.buttonStyle(.automatic)
    }
}

struct PlaylistDetails: View {
    @EnvironmentObject private var audio: AudioModel
    @Environment(\.dismiss) private var dismiss
    let playlistID: UUID
    let openMixer: () -> Void
    let openLibrary: () -> Void
    @State private var draft: PlaylistDraft?
    @State private var deleting: PlaylistDraft?
    @State private var document: PlaylistDocument?
    @State private var exporting = false
    private var playlist: SavedPlaylist? { audio.library.playlists.first { $0.id == playlistID } }

    var body: some View {
        List {
            if let playlist {
                Section {
                    Text("\(playlist.trackIDs.count) tracks · saved on this device").foregroundStyle(.secondary)
                    Button("Edit / rename") { draft = snapshot(playlist) }
                        .disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-edit")
                    Button { if let data = audio.playlistBackup(playlist.id) { document = PlaylistDocument(data: data); exporting = true } } label: {
                        Label("Save backup to Files", systemImage: "square.and.arrow.up")
                    }.accessibilityIdentifier("playlist-export")
                }
                Section("Play order") {
                    if playlist.trackIDs.isEmpty { Text("This playlist is empty. Choose Edit to add saved tracks.").foregroundStyle(.secondary) }
                    ForEach(Array(playlist.trackIDs.enumerated()), id: \.element) { offset, id in
                        if let track = audio.library.tracks.first(where: { $0.id == id }) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    Text(String(format: "%02d", offset + 1)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                                    Text(track.title).font(.headline)
                                }
                                Label(audio.referenceStatus(track).label, systemImage: audio.referenceStatus(track).symbol)
                                    .font(.caption).foregroundStyle(track.bookmark == nil ? .orange : .secondary)
                                HStack(spacing: 14) {
                                    DeckLoadButton(track: track, deck: 0, didLoad: openMixer)
                                    DeckLoadButton(track: track, deck: 1, didLoad: openMixer)
                                }.buttonStyle(.bordered)
                                if audio.referenceStatus(track) == .relink || audio.referenceStatus(track) == .unavailable {
                                    Button("Relink in Library", action: openLibrary).font(.subheadline)
                                }
                            }.padding(.vertical, 8)
                        }
                    }
                } footer: { Text("Loading a deck does not start playback. Original audio is never changed.") }
                Section {
                    Button("Delete playlist", role: .destructive) { deleting = snapshot(playlist) }
                        .disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-delete")
                }
            } else {
                Text("This playlist is no longer available. Return to Playlists to choose another set.")
            }
            Section { Text(audio.message).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("playlist-result") }
        }
        .navigationTitle(playlist?.name ?? "Playlist")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $draft) { PlaylistEditor(draft: $0).environmentObject(audio) }
        .alert("Delete playlist?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting) { value in
            Button("Delete playlist", role: .destructive) {
                if let id = value.playlistID, audio.deletePlaylist(id, revision: value.revision) { dismiss() }
                deleting = nil
            }
            Button("Cancel", role: .cancel) { deleting = nil }
        } message: { value in Text("Remove \(value.name)? Library references and original music are kept.") }
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
    @State private var error: String?
    init(draft: PlaylistDraft) { self.draft = draft; _name = State(initialValue: draft.name); _order = State(initialValue: draft.tracks) }
    var body: some View {
        NavigationStack {
            List {
                Section("Playlist name") { TextField("Name (up to 80 characters)", text: $name).accessibilityIdentifier("playlist-name") }
                Section {
                    ForEach(order, id: \.self) { id in
                        Text(audio.library.tracks.first(where: { $0.id == id })?.title ?? "Unavailable entry")
                    }
                    .onDelete { order.remove(atOffsets: $0) }
                    .onMove { order.move(fromOffsets: $0, toOffset: $1) }
                    if order.isEmpty { Text("Add a saved track below.").foregroundStyle(.secondary) }
                } header: { Text("Play order") } footer: { Text("Drag the handles to reorder. Changes apply only when you Save.") }
                Section("Add saved track") {
                    if audio.library.tracks.isEmpty { Text("Select audio in Library first, then return to this playlist.").foregroundStyle(.secondary) }
                    ForEach(audio.library.tracks.filter { !order.contains($0.id) }) { track in
                        Button { order.append(track.id) } label: { Label(track.title, systemImage: "plus.circle") }
                            .accessibilityIdentifier("playlist-add-" + track.title)
                    }.moveDisabled(true).deleteDisabled(true)
                }
                Section { Text("Cancel leaves the saved playlist unchanged. Missing audio references are retained, not silently removed.").font(.caption) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(draft.playlistID == nil ? "New playlist" : "Edit playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.accessibilityIdentifier("playlist-cancel") }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if audio.savePlaylist(id: draft.playlistID, name: name, tracks: order, revision: draft.revision) { dismiss() }
                        else { error = audio.message }
                    }.disabled(audio.libraryBlocked).accessibilityIdentifier("playlist-save")
                }
            }
            .alert("Playlist was not saved", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) { error = nil }
            } message: { Text(error ?? "") }
        }.interactiveDismissDisabled().buttonStyle(.automatic)
    }
}
