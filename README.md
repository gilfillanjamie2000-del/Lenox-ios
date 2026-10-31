# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

LENOX is one DJ and music-management product with native iOS and Android implementations. The aim is equivalent approved design and behaviour, not separate products.

> **Team start here:** current playlist and file-saving work is in [draft PR #4](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/4), on [feature/ios-playlist-persistence-20261031](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-playlist-persistence-20261031). It continues [alignment PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3) and [first-test PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Application code is **not merged into main**. This homepage is a documentation update, not integration or release approval.

## Current progress — 31 October 2026

| Area | Implemented or verified | Remaining gate |
| --- | --- | --- |
| Persistent library | Saved titles, sizes, stable identities and private iOS bookmarks; explicit loading/relinking, no startup autoplay | Real Files/provider/iCloud and permission revocation tests |
| Playlists | Native create, rename, add/remove/reorder, cancel/save, confirmed delete and A/B deck loading | Independent code/security review and physical-device UI acceptance |
| Saving safeguards | Atomic private metadata writes, stale-edit rejection, Unicode-normalised name collision guards, corrupt-file preservation | Device lock/unlock, full storage and reviewed recovery acceptance |
| Backup files | Save metadata JSON to Files; strict import creates unlinked entries, never file permissions | Real exporter/picker save/cancel tests; Android format adapter still needed |
| Local regression tests | **60 playlist + 41 mixer + 43 alignment assertions passed**; four compiled broken variants correctly rejected | Not a substitute for native SDK compilation or device testing |
| Exact-source Mac validation | [Run 41221542950](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41221542950), source `f57009b840f96103a17265018d0e5cf692670a45` | Inspect its live conclusion and source-bound evidence; new artifact verification is not claimed in this README checkpoint |
| Original Android artwork | Earlier exact-image extraction/importer and its tests retained | Hero/splash still not wired into native app |
| iPhone installation | **Blocked:** no Apple signing/provisioning configured | Authorised signing and real-iPhone acceptance |
| Overall parity | **Not achieved** | Complete navigation, original artwork, library scanning, metadata AI, occasion tools, EQ, waveforms, beat SYNC and paired-platform acceptance |

The [playlist handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/IOS_PLAYLIST_HANDOVER.md) documents source files, storage contracts, known risks, tests and the next safe action. [Local verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/builds/2026-10-31-f57009b840f9-local.json). Later documentation-only commits are not represented as newly compiled application revisions.

## What is being built

Select downloaded audio in Library, then create and save a playlist. Edit / rename supports track addition, removal and reordering. Cancel leaves the saved version untouched; duplicate names cannot overwrite a different playlist. Load A/B does not autoplay. Missing files remain listed and ask for relinking. Deleting a playlist removes metadata, not its songs. An unused reference can be forgotten; references still used by playlists are protected.

**File saving means playlist metadata, not copying or modifying original music.** Save backup to Files exports titles, byte sizes and order through the native exporter. Imports have new IDs and no bookmarks, paths or audio; explicit user relinking is required. The new `lenox-playlist` v1 JSON format is documented, but Android's existing importer does not yet support it. Do not advertise cross-platform backup compatibility.

Test limits: 20 saved references, 100 playlists, 64 MiB per selected audio file and 4 MiB metadata. The private store lives in app Application Support with protected atomic writes. Damaged or unreadable state is preserved and writes fail closed; no automatic reset or repair. The store is single-process, not a distributed lock or power-loss certification. Size checks are not content hashes. App uninstall removes local data; metadata exports cannot restore the music itself.

## For developers resuming work

- [Active source, Xcode project and test commands](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-playlist-persistence-20261031)
- [Playlist/storage handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/IOS_PLAYLIST_HANDOVER.md)
- [Portable metadata format example](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/parity/playlist-transfer-v1.example.json)
- [Updated platform parity register](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/FEATURE_PARITY.md)
- [Signing and physical-device checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)

Open `ios/LENOX.xcodeproj` from the implementation branch; shared scheme `LENOX`, minimum iOS 16.0, no third-party application packages. The new CI preserves existing audio/alignment checks and adds two separate app launches to verify save/reload with synthetic WAVs and local-container bookmarks. Real Files pickers, external providers, exporter cancellation, revocation and audible hardware performance are distinct pending checks.

## Preserved earlier milestones

The first native host `a7fc11fab969f79e8f96c26dd055b7ae9860232d` passed [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), with 41 portable assertions and 10 Simulator checks. Its [receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/builds/2026-10-31-a7fc11fab969.json) remains historical evidence.

Native alignment `cdc101ac7e6b7c9f5826b21e394760798295617f` passed [run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323), with 41 + 43 assertions and 12 generated-audio checks. Downloaded artifact, IPA, source identity and 19 manifest file hashes were verified. [Alignment verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/builds/2026-10-31-cdc101ac7e6b-cloud.json). That older unsigned IPA does not include persistent playlists or original artwork; its success does not validate PR #4.

The existing mixer provides native A/B transport, seek, gain/channel/crossfader and manual 50–200% speed. Manual speed is not beat-aligned SYNC. The centre-full crossfader is not a limiter. Initial iOS gain remains 50%, versus Android's 100%, pending an explicit shared decision.

## Original assets and shared governance

The real Android hero PNG (553 × 436) and corrected splash JPEG (941 × 1672) were extracted without modification and hash-verified. The [asset importer and handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_ARTWORK_IMPORT.md), 22 local importer tests and separate asset package are preserved. Asset staging is not native resource integration or visual approval. Android [design acceptance #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains separate.

Android reference: `feature/v3-deck-aware-mix-20261031` at `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`. Preserve original artwork, authorship and collaboration credit; do not publish private Android implementation, service configuration, music or secrets into this public repository.

Existing [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1), Android [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) and Linear LEN-7/LEN-8 ownership remain in force. Accessible Linear searches returned no playlist matches; completeness is not claimed and no assignments were changed. Jamie decides integration and unresolved differences.

Source, local tests, native compilation, Simulator checks, physical-device acceptance and release approval are distinct. No invented completion percentage, automatic merge, Apple signing, deployment, premium runner, permission change or original music/USB mutation is authorised by this README.
