# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

LENOX is an AI-assisted DJ and music-management product being developed alongside Android. The goal is equivalent approved design and behaviour with native iOS components, not a separately designed app.

> **Team start here:** current application work is in [draft PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3), on [feature/ios-android-reference-alignment-20261031](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-android-reference-alignment-20261031). It builds on [first-test PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Application code is **not merged into main**. This homepage is a documentation update, not an integration or release approval.

## Current progress — 31 October 2026

| Area | Verified progress | Remaining work |
| --- | --- | --- |
| Cloud macOS alignment build | [Run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323) **SUCCESS** for `cdc101ac7e6b7c9f5826b21e394760798295617f` | Independent source/security review and real-iPhone acceptance |
| Test evidence | 41 portable Swift assertions, 43 alignment assertions and 12 generated-audio Simulator checks passed | Not comprehensive UI interaction, real Files permission or audible hardware tests |
| Downloaded artifact | Digest/CRC, all 19 manifest file hashes, IPA/source identity and nine source-file Git blobs checked | Does not establish functional or visual parity |
| Native interface | Navy/purple/cyan styling, Home/Library/Playlists/Mix navigation, main destinations and two-deck control layout compiled | Original artwork/splash and complete Android screen flows |
| Mixer | AVAudioPlayer A/B load/play/pause/stop/seek, manual speed, gain/channel/crossfader; explicit Load & play rejects failed loads | Real-device performance, full DJ controls and paired-platform acceptance |
| Original Android artwork | Actual home hero PNG and corrected LENOX splash JPEG extracted, decoded and hash-verified without modification | Images are supplied separately; not committed or wired into the iOS app yet |
| Artwork import support | Read-only importer, 22 passing local tests, four detected deliberate integrity-check regressions and team handover committed | Xcode resource registration, native display and an artwork-inclusive build |
| iPhone installation | **Blocked:** IPA remains unsigned; no provisioning configured | Authorised signing and physical-device acceptance |
| Full platform parity | **Not achieved** | Persistent library/playlists, metadata AI, occasion tools, full navigation, waveform behaviour and other recorded gaps |

The successful cloud run predates the artwork-importer and documentation commits. It validates its exact source only. **The new downloadable alignment IPA does not yet include the original Android hero or splash.** Home and mixer screenshots were inspected; the home still has an explicit artwork-unavailable message and the mixer is scrollable.

## Verified alignment test build

Download artifact `LENOX-iOS-ALIGNMENT-UNSIGNED-cdc101ac7e6b7c9f5826b21e394760798295617f` from the successful run. It contains the device IPA, separately labelled Simulator application, matching source archive, test results, seven screen captures and build provenance. GitHub artifact retention currently expires **7 November 2026 at 15:45 UTC**.

| Identity | Value |
| --- | --- |
| IPA | `LENOX-iOS-0.1.0-cdc101ac7e6b-UNSIGNED.ipa` |
| Size | 303825 bytes |
| SHA-256 | `b7941a6b75324e962bcb46bed6ad3d2bca427384a8981c238c42d45008f62a5d` |
| Bundle / version | `app.lenox.ios.test` / 0.1.0 |
| Minimum iOS | 16.0 |
| Toolchain | Xcode 16.4 (16F6), standard GitHub `macos-15` runner |
| Executable | ARM64 iOS-device Mach-O, not a renamed Simulator application |
| Installation | **UNSIGNED: not directly installable on iPhone** |

The executable has no code-signature load command or embedded provisioning profile. [Detailed verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/builds/2026-10-31-cdc101ac7e6b-cloud.json). No physical iPhone, signing, TestFlight or App Store acceptance is claimed.

## Original Android assets

Mike requested the real Android assets, not generated substitutes. The reference is `gilfillanjamie2000-del/lunox-dj-automation`, branch `feature/v3-deck-aware-mix-20261031`, exact commit `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`.

`lenox-android-hero.png` is the existing 553 x 436 home artwork; `lenox-android-splash.jpg` is the existing 941 x 1672 spelling-corrected splash. Both match Android's recorded hashes. The [artwork handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_ARTWORK_IMPORT.md) documents reproducible extraction, tests, provenance and the remaining native integration steps. Staging files does not put them in an Xcode target or make the screens match.

The Android repository is private and iOS is public. The asset request is not blanket permission to publish Android implementation, Firebase configuration, user music or credentials. The importer copies only two identified images and provenance; it never executes or republishes the HTML. The binary images are in the separately delivered asset package, not added to GitHub by this checkpoint. Android's [design acceptance #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains open.

## Developer and Android handover

- [Active source, Xcode project, test commands and branch README](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-android-reference-alignment-20261031)
- [Android-reference alignment handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_REFERENCE_ALIGNMENT.md)
- [Pinned reference and differences](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/parity/android-reference.json)
- [Feature parity register](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/FEATURE_PARITY.md)
- [Build/signing and device acceptance checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)

Open `ios/LENOX.xcodeproj` from the implementation branch in Xcode; shared scheme `LENOX`. No third-party application packages are required. Current local-file access is read-only and session-only, limited to 20 tracks / 64 MiB per file. Loading alone does not autoplay. Manual tempo is 50–200%, not beat-aligned SYNC. The centre-full crossfader is not a limiter. Initial iOS gain remains 50%, versus Android's 100%; preserve and review that recorded difference rather than silently increasing listening volume.

The Simulator checks use generated WAV audio and direct lifecycle-handler calls. They do not test real Files-picker behaviour, permission revocation, operating-system interruption delivery or physical audio quality. Original music and USB contents remain untouched.

## Earlier evidence and governance

The first audio-test host `a7fc11fab969f79e8f96c26dd055b7ae9860232d` passed [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), with 41 portable assertions and 10 Simulator checks. Its [receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/builds/2026-10-31-a7fc11fab969.json) and [first handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_FIRST_TEST_HANDOVER.md) remain historical evidence, not approval of later changes.

The existing owner-approved cross-platform policy in [PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1), Android [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) and Linear task ownership remain in force. Preserve original authorship and collaboration credit. Jamie decides unresolved product differences and integration.

Source, tests, compilation, Simulator results, device acceptance and release approval are separate milestones; no invented completion percentage is used. Follow-up documentation/importer commits are not claimed as newly compiled application revisions. No app merge, Android-source modification, paid runner, signing, deployment, permission change or automatic-merge policy was performed by this checkpoint.
