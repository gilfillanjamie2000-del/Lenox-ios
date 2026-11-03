# iOS playlists and safe file saving

Status: implementation and local verification; read the exact GitHub run for native build results. No merge, signing, device acceptance or Android parity approval.

## Scope, ownership and provenance

Mike (Iammrmikeman) requested this iOS continuation. IMPROVEMENT to iOS PR #3; RELATED to existing library LEN-7, playlists LEN-8, Android governance #52 and iOS feasibility #62. No existing assignment, Android branch or contributor credit changes. GitHub iOS PR/issue checks found only #1–#3; the accessible Linear playlist search returned no matches, so its inventory is incomplete.

Base: `5922983fc6059ba798724eb9061b277b44b8ecfc`, branch `feature/ios-android-reference-alignment-20261031`. New work: `feature/ios-playlist-persistence-20261031`. Android behavioural reference: `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`, especially PlaylistRenamePolicy and PlaylistEditOrder. This is original native Swift implementation; no private Android implementation, music or credentials are published.

## User flow

1. Library → Select audio from Files saves a local reference and private bookmark, not a copy of the song.
2. Playlists → Create playlist → name it → add saved tracks → Save. Edit / rename permits adding, removing and reordering tracks. Cancel discards the draft. Conflicting names are rejected, never overwritten.
3. Saved playlist → Load A or Load B resolves current access and loads without playing. Start playback explicitly in the mixer. A failed load does not start the previous deck.
4. Save backup to Files exports a JSON metadata document through the system exporter. Only a successful exporter callback reports success. The user controls the destination; no music is exported.
5. Import playlist backup adds a new playlist only. Its entries require explicit Relink audio in Library; import never authorises a path or auto-matches a file. Relink confirmation explains that every playlist using that reference will point to the selected replacement.
6. Delete playlist removes only its metadata. Forget unused reference is refused while any playlist still uses it. Release session file access releases active scopes/players but keeps saved metadata.

## Storage and security contract

`PlaylistStore.swift` stores versioned `lenox-ios-library` v1 metadata in Application Support/LENOX/library-v1.json. Limits: 20 saved tracks, 100 playlists, 64 MiB per selected audio file, 4 MiB metadata input/output, 128 KiB per private bookmark. Names are 1–80 UTF-16 code units, with NFKC + lowercase collision keys; edge whitespace, control and formatting characters are rejected. Track titles are bounded to 512 UTF-16 code units. These are deliberate test-version limits, not Android capacity parity.

The app is the single MainActor owner. A mutation checks the editor's revision and last-seen disk bytes, validates a copy, atomically writes it, then publishes memory. Failed writes retain prior memory and disk. Unexpected external disk changes block overwrite. This is not an interprocess lock or proof of power-loss durability. No fsync/power-failure certification is claimed.

iOS metadata writes request complete file protection. A corrupt, unsupported or unreadable saved file blocks writes and remains untouched; there is no automatic wipe, migration, repair or overwrite. Preserve it for authorised recovery. Uninstalling the app removes local app data; a separately exported metadata file is not a backup of the music.

On startup, only metadata is read: no bookmark resolution or autoplay. At explicit loading, iOS resolves the saved bookmark without UI, rejects stale references, balances security-scoped access and coordinates file reads. Unavailable files stay in playlists and ask for relinking. File-size checks are not cryptographic content identity; same-size changes are not detected. Provider/Files timing, iCloud downloads, device lock/unlock and permission revocation still need physical-device tests. Synchronous metadata and decoder setup remain bounded but need responsiveness profiling.

## Portable backup contract and Android handover

`lenox-playlist` v1 contains exactly `format`, `version`, `name`, `tracks`; each ordered track contains exactly `title` and `byteCount`. Unknown fields, injected URLs/bookmarks, invalid names, unsupported versions and oversize inputs are rejected. Export contains no local UUIDs, paths, bookmarks, credentials or audio. Imported records get new IDs and nil bookmarks.

This is a NEW documented metadata format, NOT a claim of compatibility with Android's current backup importer. An Android adapter must be independently implemented/reviewed against the same fixtures before exchange is advertised. The example `parity/playlist-transfer-v1.example.json` is synthetic metadata, not playable media. Android should retain its native SAF references locally and never accept permission grants from this format. Explicit user relinking is required on either platform.

## Files and reproduction

- `PlaylistStore.swift`: portable validation, persistence and backup policy.
- `PlaylistViews.swift`: create/edit/delete UI and Files import/export.
- `AudioModel.swift`: bookmarks, native read coordination, saving/playback adapter and Simulator-only persistence probe.
- `LenoxApp.swift`: persistent Library, relink/forget confirmation, playlist routing and deck selection.
- `Tests/Playlists/main.swift`: 60 executable assertions, including real temporary-disk reloads and injected failures.
- `scripts/test_playlist_mutations.py`: four separately compiled broken variants, detected by assertion failures.
- `scripts/ci-playlists.sh`: existing mixer/alignment checks plus two distinct app launches for metadata persistence.

Local commands:

```sh
mkdir -p .build
swiftc ios/LENOX/PlaylistStore.swift Tests/Playlists/main.swift -o .build/playlist-tests
.build/playlist-tests
python3 scripts/test_playlist_mutations.py
python3 scripts/check_playlists.py
```

Also retain the existing 41 mixer and 43 alignment assertions and static checks. Local Swift parsing does not type-check SwiftUI against Apple SDKs. Deterministic project generation must match the checked-in Xcode project. The dedicated workflow uses only this public repository, explicit feature branch, standard macos-15, read-only token and pinned actions. Previous workflows/branches are unchanged. Output is still unsigned, not directly installable on iPhone.

## Acceptance evidence boundaries / next safe action

Local results: 60 playlist assertions, 41 mixer assertions and 43 alignment assertions passed. Four compiled guard-removal probes each produced a real assertion failure; baseline produced none. Source, Swift parse, shell syntax and project-generation checks passed. Independent review is not claimed.

The new native probe uses synthetic WAVs and app-container bookmarks. Write launch expects five checks; read launch expects seven checks after actual process termination/relaunch. It exercises persistent names/order, explicit bookmark-backed loading, no autoplay and permission-free metadata import. It does not exercise the real Files picker, exporter save/cancel UI, iCloud providers, OS-delivered background/permission changes or hardware audio.

Before integration: inspect exact-head cloud results and package provenance; independently review storage/security and shared behaviour; test real Files selection, relink/cancel, save cancellation, duplicate names, reorder/cancel/stale edits, file disappearance, locked-device reopen, corrupt data and full storage on a signed test iPhone. Jamie decides integration. Artwork integration, recommendations, EQ, beat sync and full visual/functional parity remain separate unfinished work.


## Native studio continuation — 2 November 2026

[Draft PR #5](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/5) continues this preserved milestone. Compiled source `4d7ce70794a378a0fa6cc517804ca0893ece3a2b` adds the two explicitly authorised original assets, native launch video, playlist details/editor, adaptive spinning/jog mixer and multi-import/lifecycle repair. [Studio handover](IOS_STUDIO_HANDOVER.md) · [exact receipt](builds/2026-11-02-4d7ce70794a3-studio.json) · [successful run](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41523915266). The earlier evidence above remains historical. The new IPA is unsigned; actual phone Files-provider acceptance and genuine PCM scratching remain open.
