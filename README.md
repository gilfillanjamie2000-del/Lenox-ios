# LENOX iOS — native studio candidate

0.1.1/build 2 correction replaces the picker, checks actual audio before saving, declares open-in-place support and adds real Files UI tests. Mike also requested removal of the 20-song cap: there is now no fixed song-count limit, with the existing file/metadata safeguards retained. [Fix handover](docs/IOS_FILES_PICKER_FIX_20261102.md). Its native build is pending; the 0.1.0 results below do not prove this phone issue fixed.

**Active branch:** `feature/ios-performance-studio-20261102`, [draft PR #5](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/5), stacked on playlist PR #4. Mike develops iOS; Jamie retains product/integration authority.

This candidate adds original home artwork, the approved native boot video, searchable playlists with dedicated details, a graphite/lime native mixer and playback-linked spinning vinyl with bounded jog seeking. It also fixes the Files picker inactivity handoff and adds atomic multi-song import within the existing 20-track limit. Genuine PCM scratching, BPM/waveforms, EQ and SYNC remain unimplemented.

**Native CI passed** on `4d7ce70794a378a0fa6cc517804ca0893ece3a2b`: device ARM64 and separate Simulator builds; 41 mixer / 45 alignment / 60 storage / 28 performance / 22 import assertions; 12 native audio / 5 write / 7 separate-launch restore / 29 performance-import-video checks; four storage mutation probes; two offline intro outcomes and all 8 UI scenarios. [Run](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41523915266) · [Artifact](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41523915266/artifacts/13180496183) · [Exact receipt](docs/builds/2026-11-02-4d7ce70794a3-studio.json). The IPA is **unsigned and not directly installable on iPhone**. Exact-build physical Files-provider testing and independent/owner review remain open. Genuine PCM scratching is not implemented.

Read [the complete studio handover](docs/IOS_STUDIO_HANDOVER.md) for assets/publication authority, data contracts, tests, Android handover and recovery. The existing playlist schema, references, corruption protection and regression chain remain. No merge, signing, TestFlight or release is performed.

Build with `bash scripts/ci-studio.sh` on the existing GitHub macOS/Xcode system. The standard macOS 15 Intel pool is used after GitHub could not allocate the macOS 15 ARM runner. The compiled source is `4d7ce70794a378a0fa6cc517804ca0893ece3a2b`; later documentation commits are not new application builds. Landscape rotation exposes A/mixer/B; portrait uses focused deck controls. Controls are bounded by the window in the UI regression.

---

## Preserved 31 October playlist milestone

# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

One LENOX product, native iOS and Android implementations. Current work is [draft PR #4: persistent playlists and file saving](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/4), building on [PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3) and [PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Application code remains isolated, unmerged and not independently approved.

> **Playlist build verified — 31 October 2026.** [GitHub Mac run 41221542950](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41221542950) succeeded on **`f57009b840f96103a17265018d0e5cf692670a45`**. Device/Simulator compilation, 60 playlist + 41 mixer + 43 alignment assertions, 12 synthetic audio checks and 5 save + 7 relaunch checks passed. The downloaded artifact and IPA/source identities were verified. **The IPA is unsigned and not directly installable on iPhone.** [Exact cloud receipt](docs/builds/2026-10-31-f57009b840f9-cloud.json).

## Team progress

| Area | Verified progress | Remaining gate |
| --- | --- | --- |
| Persistent library | Private saved metadata/bookmarks; synthetic native bookmark-backed loading after a separate process launch | Real Files/provider, iCloud, stale/revoked access and device lock/unlock tests |
| Playlists | Native create, rename, add/remove/reorder, cancel/save, confirmed delete and A/B loading; save/reload exercised in Simulator | Independent review and physical UI acceptance |
| Saving integrity | Local failure-injection, stale-edit, duplicate-name, corrupt-state, bounded import and real temporary-disk tests pass | Full-device storage/recovery and power-loss behaviour not certified |
| Backup files | Native Files export/import implemented; import produces fresh unlinked references, never file-access capabilities | Actual exporter/picker save/cancel interaction; Android adapter not implemented |
| Mac validation | Exact-source first attempt successful; 26 artifact-manifest hashes and 11 source blobs matched | Simulator checks do not establish real-device acceptance |
| Artwork | Original extraction/importer and previous evidence retained unchanged | Original hero/splash still not wired into native app |
| iPhone installation | **Blocked:** no Apple signing/provisioning configured | Authorised signing and physical-device tests |
| Full platform parity | **Not achieved** | Complete navigation, library scanning, artwork, metadata AI, occasions, EQ, waveforms, beat SYNC and paired acceptance |

The [playlist handover](docs/IOS_PLAYLIST_HANDOVER.md), [local receipt](docs/builds/2026-10-31-f57009b840f9-local.json) and [parity register](docs/FEATURE_PARITY.md) support resumable Android/iOS work. Follow-up documentation commits are not newly compiled application revisions; the source ZIP remains the original exact build snapshot.

## Matching test package

Download artifact **`LENOX-iOS-PLAYLISTS-UNSIGNED-f57009b840f96103a17265018d0e5cf692670a45`** from the successful run. It contains the device IPA, separate Simulator application, 40-file source archive, tests, screenshots and provenance. GitHub retention expires **7 November 2026, 16:56 UTC**.

- IPA: `LENOX-iOS-0.1.0-f57009b840f9-UNSIGNED.ipa` — **476987 bytes**.
- SHA-256: `f79e778afc86e46e1c1a6b1d90bd07c3d3f0441c97910bced508231a33805b63`.
- Bundle/version: `app.lenox.ios.test`, 0.1.0 build 1, minimum iOS 16.0.
- Toolchain: Xcode 16.4 (16F6), standard public `macos-15` runner.
- Real ARM64 iOS-device Mach-O, not a renamed Simulator app; no provisioning profile or code-signature load command.

The actual relaunch screenshot shows the saved Night set and reversed synthetic track order. This is not a photograph of a phone, a full UI interaction test or design-parity approval.

## User flow and data safety

Select downloaded audio in Library, then create a playlist, add saved tracks and Save. Edit / rename supports ordering/removal; Cancel discards the draft. Duplicate names cannot overwrite a different playlist. Load A/B does not autoplay. Missing songs remain in playlists and request Relink audio. Relink confirmation explains that all playlists using that reference will point to the selected replacement. Delete playlist removes metadata only. Forget unused reference is blocked while a playlist still uses it; Release session file access retains persistent metadata.

**Save backup to Files exports metadata, not songs.** JSON contains titles, byte sizes and order only. Imports receive new identities and no bookmarks or paths; explicit relinking is required before playback. The new `lenox-playlist` v1 format has a [synthetic example](docs/parity/playlist-transfer-v1.example.json), but Android's existing importer does not yet support it. Cross-platform backup compatibility is not claimed.

Test limits: 20 saved references, 100 playlists, 64 MiB per audio file, 4 MiB metadata. The store writes atomically before publishing memory, refuses stale editors/external changes, and preserves corrupt/unreadable files with writes blocked. This is single-process storage, not distributed locking or certified power-loss recovery. File size is not a content hash. App uninstall removes app-local data; a metadata export cannot restore original audio. Original songs are never copied, moved, overwritten or deleted by these operations.

## Build and reproduce

Open `ios/LENOX.xcodeproj` in Xcode, shared scheme `LENOX`. No third-party application packages.

```bash
mkdir -p .build
swiftc ios/LENOX/PlaylistStore.swift Tests/Playlists/main.swift -o .build/playlist-tests
.build/playlist-tests
python3 scripts/test_playlist_mutations.py
python3 scripts/check_playlists.py
```

The dedicated `ios-playlists.yml` preserves existing audio/alignment checks and tests two distinct Simulator launches with generated WAVs and app-container bookmarks. It does not exercise real Files/exporter UI, iCloud providers, OS-delivered permission changes or audible physical hardware. The job is constrained to this public repository, explicit feature branch and standard runner, with read-only token, pinned actions and bounded retention. No signing, deployment or automatic merge.

## Preserved history and shared governance

First host `a7fc11fab969f79e8f96c26dd055b7ae9860232d`: [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), 41 portable assertions + 10 synthetic audio checks; [receipt](docs/builds/2026-10-31-a7fc11fab969.json). Alignment `cdc101ac7e6b7c9f5826b21e394760798295617f`: [run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323), 41 + 43 assertions + 12 audio checks; [receipt](docs/builds/2026-10-31-cdc101ac7e6b-cloud.json). Those earlier IPAs do not contain persistent playlists.

The original Android hero/splash extraction, 22 importer tests and separate asset package are preserved in [artwork handover](docs/ANDROID_ARTWORK_IMPORT.md). They are not bundled by this playlist work. Native mixer controls remain intact; manual 50–200% speed is not beat SYNC, the centre-full crossfader is not a limiter, and iOS retains 50% initial gain versus Android's 100% pending a shared decision.

[Policy](docs/CROSS_PLATFORM_POLICY_V1.md), [feature register](docs/FEATURE_PARITY.md), [handover template](docs/FEATURE_HANDOVER_TEMPLATE.md), [alignment notes](docs/ANDROID_REFERENCE_ALIGNMENT.md) and [device/signing checklist](docs/IOS_BUILD_AND_ACCEPTANCE.md) remain in force. Android reference is `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed` on `feature/v3-deck-aware-mix-20261031`; existing governance #52, feasibility #62 and LEN-7/LEN-8 ownership are not transferred. Accessible Linear playlist searches returned no matches; inventory completeness is not claimed.

Preserve original authorship and collaboration credit. Do not publish private Android implementation, service configuration, music or credentials. Jamie decides integration and unresolved differences. Source, local tests, compile results, Simulator evidence, physical acceptance and release approval are separate milestones; no invented completion percentage or parity approval.
