# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

LENOX is one DJ and music-management product with native iOS and Android implementations, shared approved designs and documented two-way handovers.

> **Latest milestone: persistent playlists and file saving compiled and tested on GitHub Mac.** [Run 41221542950](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41221542950) succeeded for **`f57009b840f96103a17265018d0e5cf692670a45`**. The downloaded IPA, source snapshot and reports were verified. **The IPA is unsigned and not directly installable on iPhone.** [Verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/builds/2026-10-31-f57009b840f9-cloud.json).

**Team start here:** [draft PR #4](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/4), [active source and detailed README](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-playlist-persistence-20261031). It continues [alignment PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3) and [first-test PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Application code is **not merged into main**. This homepage update does not approve integration or release.

## Verified progress — 31 October 2026

| Area | Evidence | Remaining work |
| --- | --- | --- |
| Saved library | Private persistent metadata/bookmarks and explicit native loading after process relaunch | Real Files/provider, iCloud, stale/revoked access and lock/unlock checks |
| Playlists | Create, rename, add/remove/reorder, cancel/save, confirmed delete and A/B loading implemented; save/reload tested in Simulator | Independent source/security review and physical UI acceptance |
| Safe saving | Failed-save, stale-edit, duplicate-name, corrupt-file, import-permission and disk-reload tests pass | Full-storage and device recovery acceptance; no power-loss certification |
| Backups | Native Save backup to Files and metadata-only import implemented; imports never restore file-access permissions | Real picker/exporter save/cancel tests; Android format adapter not implemented |
| Portable tests | **60 playlist + 41 mixer + 43 alignment assertions passed locally and in cloud** | Four compiled mutation probes additionally passed detection locally; not independent approval |
| Native runtime | **12 audio + 5 playlist-write + 7 relaunch checks passed**, generated WAVs and local-container bookmarks only | Not external Files providers, system permission transitions or physical audio |
| Artifact inspection | ZIP/IPA integrity, all **26 manifest hashes**, source identity and **11 source blobs** verified | Unsigned; no iPhone installation, TestFlight or release acceptance |
| Original artwork | Earlier exact hero/splash extraction and tested importer retained | Images still not wired into native app |
| Full platform parity | **Not achieved** | Complete artwork/navigation, scanning, metadata AI, occasion tools, EQ, waveforms, beat SYNC and paired-platform validation |

Actual Simulator capture shows the restored Night set with two synthetic tracks in the saved order. It is not a physical-phone photograph or comprehensive UI interaction test. Later README/receipt/parity commits are documentation-only, not newly compiled application revisions.

## Test build

From the successful run, download artifact **`LENOX-iOS-PLAYLISTS-UNSIGNED-f57009b840f96103a17265018d0e5cf692670a45`**. It contains the device IPA, separate Simulator application, matching 40-file source ZIP, tests, screenshots, checksums and provenance. GitHub retention expires **7 November 2026 at 16:56 UTC**.

| Identity | Value |
| --- | --- |
| IPA | `LENOX-iOS-0.1.0-f57009b840f9-UNSIGNED.ipa` |
| Size | 476987 bytes |
| SHA-256 | `f79e778afc86e46e1c1a6b1d90bd07c3d3f0441c97910bced508231a33805b63` |
| Bundle / version | `app.lenox.ios.test`, 0.1.0 build 1, iOS 16+ |
| Toolchain | Xcode 16.4 (16F6), standard public `macos-15` runner |
| Executable | ARM64 iOS-device Mach-O; not a renamed Simulator app |
| Installation | **Unsigned:** no provisioning profile or code-signature load command |

## What testers and future developers should know

Select downloaded audio in Library, then create a playlist and Save. Edit / rename supports ordering, addition and removal; Cancel keeps the saved version. Duplicate names cannot overwrite another playlist. Load A/B does not autoplay. Missing files remain listed and request Relink audio. Confirmed relinking changes only the saved reference across playlists. Deleting a playlist never deletes its songs; forgetting an unused reference is blocked while another playlist uses it.

**File saving is metadata saving, not copying or modifying original music.** Backups contain titles, byte sizes and order, not paths, bookmarks or audio. Imported entries receive new IDs and must be explicitly relinked. The documented `lenox-playlist` v1 format is NOT yet readable by Android's existing importer. A separate Android adapter and paired tests are needed before claiming interoperability.

Limits remain explicit: 20 saved references, 100 playlists, 64 MiB per selected audio file and 4 MiB metadata. Private storage is single-process with protected atomic replacement; damaged/unreadable state is retained with writes blocked, not automatically reset. Size is not a content hash. Uninstalling removes app-local data; metadata exports cannot recover the music itself.

- [Playlist/storage handover and native acceptance checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/IOS_PLAYLIST_HANDOVER.md)
- [Local test and mutation receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/builds/2026-10-31-f57009b840f9-local.json)
- [Feature parity register](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/FEATURE_PARITY.md)
- [Synthetic metadata format example](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/parity/playlist-transfer-v1.example.json)
- [Signing and physical-device checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-playlist-persistence-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)

Open `ios/LENOX.xcodeproj` on the implementation branch in Xcode; shared scheme `LENOX`. No third-party application packages are required. No signing keys or user data belong in this public repository.

## Preserved milestones, assets and credit

First native host `a7fc11fab969f79e8f96c26dd055b7ae9860232d`: [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), 41 portable assertions and 10 audio checks; [receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/builds/2026-10-31-a7fc11fab969.json).

Alignment `cdc101ac7e6b7c9f5826b21e394760798295617f`: [run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323), 41 + 43 assertions and 12 audio checks; [receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/builds/2026-10-31-cdc101ac7e6b-cloud.json). Those older IPAs do not contain persistent playlists.

The original Android hero PNG (553 × 436) and corrected splash JPEG (941 × 1672) were extracted unchanged and hash-verified. The [artwork handover/importer](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_ARTWORK_IMPORT.md), 22 local importer tests and separately delivered asset package are retained, not replaced. They are not bundled by this playlist change. Android design acceptance #28 remains separate.

Native A/B transport, seek, gain/channel/crossfader and manual 50–200% speed remain. Manual speed is not beat SYNC; the centre-full crossfader is not a limiter. Initial iOS gain remains 50% versus Android's 100%, pending an explicit shared decision.

## Governance and next acceptance

Android reference: `feature/v3-deck-aware-mix-20261031` at `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`. Existing [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1), Android [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) and LEN-7/LEN-8 ownership remain in force. Accessible Linear playlist searches returned no matches; completeness is not claimed and no assignments were changed. Preserve original authorship and collaboration credit. Jamie decides integration.

Next gates: independent storage/security review and signed-device checks covering Files/exporter cancellation, providers, revoked access, lock/unlock, full storage and playlist recovery. Source, tests, compilation, Simulator checks, physical acceptance and release approval are separate milestones. No invented completion percentage, automatic merge, deployment, paid runner, permission change or original music/USB mutation is authorised by this README.
