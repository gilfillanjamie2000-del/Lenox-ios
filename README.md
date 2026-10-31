# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

LENOX is one DJ and music-management product with native iOS and Android implementations. Current work is [draft PR #4: playlists and file saving](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/4), on `feature/ios-playlist-persistence-20261031`. It builds on [alignment PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3) and [first-test PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Application work is **not merged into main**, not independently approved and not a production release.

## Current progress — 31 October 2026

| Area | Evidence-backed state | Remaining gate |
| --- | --- | --- |
| Saved library | Persistent titles, sizes, stable IDs and private iOS bookmarks implemented; references are resolved only on explicit loading | Real Files/provider permission, iCloud and revocation testing |
| Playlists | Native create, rename, add/remove/reorder, cancel/save and confirmed deletion implemented | Independent review and physical-device UI acceptance |
| Safe saving | Versioned private metadata; atomic writes; stale-edit and duplicate-name rejection; corrupt files preserved with writes blocked | Device lock/unlock, full storage and recovery acceptance |
| Backups | Native Save backup to Files and import; JSON titles/sizes/order only, no audio, paths or bookmarks | Real exporter/picker save/cancel tests; Android adapter not implemented |
| Local verification | 60 playlist + 41 mixer + 43 alignment assertions passed; four separately compiled guard mutations detected | Local Swift checks are not Apple-platform or device approval |
| Native Mac validation | [Run 41221542950](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41221542950) started for exact source `f57009b840f96103a17265018d0e5cf692670a45` | Native result and artifact verification pending in this update |
| Artwork | Earlier original hero/splash extraction and importer retained unchanged | Images still not wired into the native app; visual parity not achieved |
| iPhone installation | **Blocked:** builds remain unsigned; no Apple signing/provisioning configured | Authorised signing and real-iPhone acceptance |

See the [playlist handover](docs/IOS_PLAYLIST_HANDOVER.md) and [exact-source local test receipt](docs/builds/2026-10-31-f57009b840f9-local.json). Later documentation commits are not claimed as newly compiled application revisions. Do not use an older green run to validate the playlist changes.

## What testers can do

Select downloaded audio in Library, then create a playlist, add saved tracks and save it. Edit / rename supports ordering and removal; Cancel discards the draft. Load A/B never autoplays. Relink explicitly replaces a saved file reference across playlists without changing the original song. Delete playlist removes metadata only. Forget unused reference is blocked while a playlist still uses it. Release session file access keeps saved metadata.

**Save backup to Files exports playlist metadata, not music.** Imported entries receive new identities and no file permissions; relink them in Library before playback. The new `lenox-playlist` v1 format is documented and illustrated in the [synthetic transfer example](docs/parity/playlist-transfer-v1.example.json), but Android's current importer does not support it yet. Cross-platform backup compatibility is not claimed.

Test-version limits remain explicit: 20 saved track references, 100 playlists, 64 MiB per audio file and 4 MiB metadata. Missing or stale file access retains playlist entries and asks for relinking. File size is not cryptographic content identity. The store is single-process, not a distributed lock or power-loss certification. A damaged saved file is preserved, not automatically reset. Uninstalling removes app-local data; exported metadata cannot restore the music itself.

## Build and reproduce

Open `ios/LENOX.xcodeproj` in Xcode, shared scheme `LENOX`, iOS 16+. No third-party application packages are required.

```bash
mkdir -p .build
swiftc ios/LENOX/PlaylistStore.swift Tests/Playlists/main.swift -o .build/playlist-tests
.build/playlist-tests
python3 scripts/test_playlist_mutations.py
python3 scripts/check_playlists.py
```

The dedicated GitHub `ios-playlists.yml` job runs the existing mixer/alignment build plus two distinct Simulator launches: save on the first, reload on the second. It requires five write-phase and seven reopen-phase checks, using generated WAVs and app-container bookmarks. This is not real Files UI, iCloud-provider or physical-iPhone evidence. The job only uses the explicit public repository/feature branch and a standard `macos-15` runner, read-only token, pinned actions and bounded retention. No signing, deployment or automatic merge.

## Previous verified milestones — preserved, not reused as current approval

- First native test host `a7fc11fab969f79e8f96c26dd055b7ae9860232d`: [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), 41 portable assertions and 10 generated-audio checks. [Receipt](docs/builds/2026-10-31-a7fc11fab969.json).
- Native Android-reference alignment `cdc101ac7e6b7c9f5826b21e394760798295617f`: [run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323), 41 + 43 assertions and 12 Simulator checks. Downloaded artifact/IPA/source hashes were checked. [Receipt](docs/builds/2026-10-31-cdc101ac7e6b-cloud.json). That older IPA has no persistent playlists or original artwork.
- Original Android hero PNG and corrected splash JPEG were extracted without modification; importer tests and the separate asset package remain documented in [Android artwork import](docs/ANDROID_ARTWORK_IMPORT.md). This playlist work does not replace or discard that work, and does not claim the assets are bundled.

The previous app already has native A/B playback, gain/channel/crossfader, seek and 50–200% manual tempo. Manual tempo is not beat SYNC; the centre-full crossfader is not a limiter. Initial iOS gain remains 50%, versus Android's 100%, pending an explicit shared decision.

## Shared development, credit and remaining work

The [policy](docs/CROSS_PLATFORM_POLICY_V1.md), [feature parity register](docs/FEATURE_PARITY.md), [handover template](docs/FEATURE_HANDOVER_TEMPLATE.md), [alignment handover](docs/ANDROID_REFERENCE_ALIGNMENT.md) and [device/signing checklist](docs/IOS_BUILD_AND_ACCEPTANCE.md) remain in force. Existing Android governance #52, iOS feasibility #62 and Linear LEN-7/LEN-8 assignments are not transferred. Current accessible Linear playlist searches returned no matches, so inventory completeness is not claimed.

Android reference is `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed` on `feature/v3-deck-aware-mix-20261031`. Reproduce behaviour and approved designs natively; do not publish private Android implementation, service configuration, music or secrets. Original contributor credit is retained. Jamie decides integration and unresolved differences.

**Still pending:** real-iPhone Files/exporter/permissions acceptance, independent source/security review, original-artwork integration, complete library scanning, reviewed-metadata AI, occasion tools, EQ, waveforms, beat-aligned SYNC and full visual/functional parity. Source, tests, compile results, Simulator evidence, device acceptance and release approval are separate milestones. No invented completion percentage or automatic promotion is used.
