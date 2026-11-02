# Native studio, approved artwork and Files import — 2 November 2026

**Lead:** Mike (Iammrmikeman). **Product direction/integration:** Jamie. Preserve all original contributor credit. This is an isolated continuation of iOS PR #4, related to existing LEN-7/LEN-8/LEN-14 and Android #51/#62/#117/#118. No Android ownership or assignments change.

**Branch:** `feature/ios-performance-studio-20261102`. **Starting head:** `1af6c6ccc1f3716b5a74579323b11f0f033f64bf`. Its app, tests, scripts and project match the last compiled implementation `f57009b840f96103a17265018d0e5cf692670a45`; the four changed paths are documentation. Main lacks the application. This branch retains PR #1 → #2 → #3 → #4 ancestry. It must target the playlist branch for a focused review, not main.

## Implemented candidate

- Home / Library / Playlists / Mixer / More navigation; More reaches separate Assistant, Occasions and Status screens. AudioModel remains owned by the app, outside navigation and intro presentation.
- Original home hero, unchanged bytes, in native SwiftUI; the approved bundled MP4 uses AVPlayer/AVPlayerLayer after the lightweight system launch screen. Its movie header is exactly 12.34 seconds (the brief rounded to 12). Muted by default, sound control, accessible Skip, Reduce Motion bypass, finish/error/checksum/15-second timeout/background/interruption exit. No network loading or loading percentages. Intro never restarts on section navigation.
- Searchable playlist list and dedicated details; create/edit/rename/add/remove/reorder/cancel/save/delete and metadata-only Files backup retain the original storage engine. Handles are visible in the editor. Duplicate-name, revision, atomic-save and corrupt-storage protections remain.
- Dedicated graphite/lime mixer: A / channel mixer / B in landscape; focused A/B portrait controls. Real load, play/pause, unload-stop, seek-to-start, elapsed/remaining time, gains, channel levels, crossfader and 50–200% manual speed. Secondary tools are sheets. Playing-deck replacement requires confirmation and validates generation/library revision/deck identity before loading paused.
- Native vinyl rendering derives its angle from the actual AVAudioPlayer position at 33⅓ visual rpm. Pausing holds position; tempo/seek changes affect the display. Reduce Motion keeps the marker static. Touch drag and accessible adjustments perform bounded seek/jog; each event is limited to 250 ms. Portrait also has ±50 ms controls.
- Files import supports multiple selected songs in one atomic metadata transaction within the unchanged 20-reference/64 MiB-per-file limit. A bad member or write failure publishes none of the batch. Relink remains single-file. Brief scene inactivity suspends playback and defers picker completion until active; actual backgrounding invalidates pending results. This addresses a source-identified rejection path matching the owner's reported tap-with-no-import symptom; exact phone reproduction still requires testing.

**Not implemented:** forward/reverse PCM vinyl scratching, waveforms, BPM/key/energy analysis, EQ, beat-grid/SYNC, hot cues, loops, FX, sampler, recording or independent headphone cue. Jog seeking is explicitly labelled and is not scratch rendering. AVAudioPlayer remains the working engine.

## Portable behaviour and data contract

Storage remains `lenox-ios-library` version 1, with no migration, cap increase or reset. `PlaylistStore.saveTracks(_:revision:)` appends an entire validated selection in one transaction. Imported references receive fresh UUIDs and private native bookmarks; backup `lenox-playlist` v1 remains metadata-only and grants no file access. Android backup compatibility remains unimplemented.

`PlaybackGate.setActive(_:invalidatePending:)` defaults to the original background-invalidating behaviour. The app explicitly passes `false` only for a transient inactive scene; no playback or import processing is allowed until active. True background, interruption and session reset still invalidate generations. Files cancellation leaves saved data unchanged. Native security scope is released by SelectedTrack ownership; failed batch candidates are not retained.

`DeckLoadRequest` contains track UUID, deck index, playback generation, library revision and deck generation. Confirmations cannot replace a deck that changed while the dialog was open. A successful load always pauses the target; other deck playback is independent.

## Approved assets and publication authority

Mike reported being with Jamie and explicitly answered on 2 November 2026: **“Yes — Jamie approves these two files in public GitHub.”** This authorises only the following original binaries in the public iOS repository. It is not permission to publish Android code, configuration, user audio or other private assets.

| Asset | Identity | Provenance |
| --- | --- | --- |
| `ios/LENOX/ApprovedAssets/lenox-android-hero.png` | 389384 bytes; 553×436; SHA-256 `4a09a937f442b1d246b0f352f40f9e0bc4036ef37bb8d3d1ad4aeb0784564221` | Existing lossless owner-art crop from Android `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`, exact HTML blob verified by the existing importer |
| `ios/LENOX/ApprovedAssets/lenox-intro.mp4` | 2278410 bytes; 12.34 s; H.264/AAC; SHA-256 `85f30b59c4287db67d4123961bf3e77c22dae340d449e97845c5078eefece668` | Android `c20276acdd5c23ba2817b64438b9b17f6a516192`, retained run 41260378943 artifact 13064633928; extracted exact `assets/lenox-intro.mp4`; HeyGen ID `6e6e013ef2724929a0c48b9388d3fb9d` |

No generation, repainting, resizing or re-encoding. Source and bundled hashes are checked. The 1536×864 V4 reference JPEG was privately read and matched `f133f28fff7f64d15293f699b893a04469e947b607097e5f9d62065848dfe0f5`; it is not bundled as a fake mixer background. The legacy orbital JPEG was verified locally but is not part of this two-file publication.

## Two-way Android handover

Use existing #51/#117/#118 for native layout and #62 for iOS coordination. Compose should use Android-owned deck/state APIs and SAF; SwiftUI uses AudioModel and native bookmarks. Share outcomes and fixture timing, not platform permission tokens. Android can adopt the atomic multi-selection invariant, transient-inactivity deferral, explicit live-deck confirmation and playback-clock platter mapping with its own lifecycle tests. Do not copy iOS bookmarks into SAF or advertise the iOS JSON importer as Android-compatible. Original Android experimental PCM/analysis work is held separately and is not inherited as working iOS functionality.

## Verification and build contract

Run `bash scripts/ci-studio.sh`. It preserves `ci-playlists.sh` → `ci-alignment.sh` → `ci-ios.sh`, original 41 mixer / 60 storage / 12 native audio / 5 write / 7 separate-launch assertions; adding More extends the route/alignment suite from 43 to 45 checks. New portable import/performance suites, native synthetic import/jog/decoder tests and native UI tests add focused coverage. Static source checks are supplementary.

The deterministic project generator registers all native sources, the exact asset folder and UI test target. Generated-project drift must fail CI. Artifacts contain genuine ARM64 iPhoneOS output, separate Simulator app, tracked source archive, checksums, toolchain logs, test reports, screenshots, signing/installability status and provenance. Device output is unsigned and not directly installable on iPhone.

The original `macos-15` attempt 2 of run 41221542950 failed before acquiring a runner: GitHub reported macOS ARM64 capacity constraints. The standard **macOS 15 Intel** pool (`macos-15-intel`) preserves the GitHub/Xcode system and public-repository free standard-runner policy. First fallback wrapper run 41512471689 passed 60/43 tests and stopped on SHA guard; fixed wrapper passes the pinned SHA directly to the verification subprocess. Run 41512834080 checks out unchanged `f57009b…` before candidate promotion. No application source was changed by these baseline wrapper commits.

**Baseline reproduced:** run [41512834080](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41512834080) passed the unchanged `f57009b840f96103a17265018d0e5cf692670a45` application regression chain and uploaded its artifact. **Candidate native result:** pending; consult exact build receipts and PR for final SHA/results. Do not infer a successful candidate from source checks or the historical IPA. No independent QA, physical-device acceptance, signing, merge or release is claimed.

## Remaining acceptance and recovery

On an authorised iPhone: select one and several downloaded files, confirm the actual import UI, cancel, test provider permission denial/revocation, relink, missing/changed media, background during picking, iCloud availability, full storage and repeated imports. Verify original songs unchanged, no autoplay, playlist restart, both decks audible, crossfader endpoints, tempo, jog, intro sound/skip/interruption and rotation/accessibility. Match the exact installed build SHA; preserve the contributor's earlier iPhone XR report as historical evidence only.

Keep this draft unmerged until independent source/security, visual and device review and Jamie's integration decision. Recover the previous build using the untouched playlist branch and its verified original artifact. The metadata schema is unchanged; do not erase app storage to test this candidate. Genuine scratch work must be an isolated AVAudioEngine/PCM milestone, measured on hardware before replacing the working engine.
