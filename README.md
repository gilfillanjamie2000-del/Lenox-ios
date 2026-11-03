# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

One LENOX product, native iOS and Android implementations. Work is isolated in [draft PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3), built on [draft PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Neither application PR is merged or release-approved. Visual and functional parity with Android are **not achieved**.

## Latest verified progress — 31 October 2026

| Work | Evidence | Remaining gate |
| --- | --- | --- |
| Android reference | `feature/v3-deck-aware-mix-20261031` pinned to `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`; canonical HTML matches the inspected APK | Owner-design acceptance and paired platform checks |
| Native navigation and mixer | Navy/purple/cyan interface, main feature destinations, responsive two-deck controls, real title search, explicit Load & play with failed-load protection | Full studio navigation, original artwork and equivalent library/features |
| GitHub Mac alignment build | [Run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323) succeeded on **`cdc101ac7e6b7c9f5826b21e394760798295617f`** | Independent source/security review and physical-device acceptance |
| Retained test results | 41 portable Swift assertions, 43 alignment assertions and 12 generated-audio Simulator checks passed | Not real Files permission, audible device or comprehensive UI interaction tests |
| Downloaded build verification | Artifact digest/CRC, all 19 manifest file hashes, IPA integrity, package/source identity and 9 source-file Git blobs checked | No signed iPhone installation or parity approval |
| Original Android images | Exact hero PNG and corrected splash JPEG extracted and locally verified, without resizing/recompression | Binary files are in the separate asset ZIP; not committed or wired into native views yet |
| Artwork importer | [Importer](scripts/import_android_artwork.py), [tests](Tests/test_android_artwork.py), [handover](docs/ANDROID_ARTWORK_IMPORT.md); 22 local tests passed and four deliberately broken integrity checks detected | Xcode resource registration, native home/splash implementation and artwork-inclusive build |
| Persistent library/playlists and intelligence | Missing or limited in iOS; session-only file selection is not Android folder-scan parity | Shared contracts, implementation and two-way tests |
| iPhone install | **Blocked:** no Apple signing/provisioning configured | Authorised signing and real-iPhone acceptance |

The successful cloud run predates the importer/documentation commits. It does **not** contain the original Android artwork, and does not compile or test later branch commits. Importer tests validate extraction, not iOS UI. No new cloud run was started for the importer-only checkpoint.

## Matching unsigned IPA

[Cloud verification receipt](docs/builds/2026-10-31-cdc101ac7e6b-cloud.json) records exactly what was checked. Download artifact `LENOX-iOS-ALIGNMENT-UNSIGNED-cdc101ac7e6b7c9f5826b21e394760798295617f` from the successful run. It contains the unsigned device IPA, separately labelled Simulator app, matching source archive, 7 route captures, test results and provenance. GitHub retention currently expires 7 November 2026 at 15:45 UTC.

- IPA: `LENOX-iOS-0.1.0-cdc101ac7e6b-UNSIGNED.ipa`, 303825 bytes.
- SHA-256: `b7941a6b75324e962bcb46bed6ad3d2bca427384a8981c238c42d45008f62a5d`.
- Bundle: `app.lenox.ios.test`, version 0.1.0, minimum iOS 16.0.
- Toolchain: Xcode 16.4 (16F6); actual ARM64 iOS-device executable.
- **Unsigned: not directly installable on iPhone.** No provisioning profile or code-signature load command was present.

Home and mixer captures were visually inspected. The home still has the explicit missing-artwork warning; the mixer scrolls. No matched Android/iPhone screenshot approval is claimed.

## Use the original assets, not substitute art

Mike requested the real Android assets. The [artwork handover](docs/ANDROID_ARTWORK_IMPORT.md) identifies the exact images and hashes, tested import commands and remaining native integration steps. The original image bytes were preserved. The importer creates `ios/LENOX/AndroidArtwork` from an authorised local reference APK or checkout, and never copies or executes Android HTML.

**The image binaries are supplied in the separately delivered verified asset ZIP, not committed to this branch by this work.** The importer does not edit the Xcode project or SwiftUI views. Staging resources alone must not be labelled visual parity or an artwork-inclusive IPA.

Android is private and this repository is public. The asset request is not blanket permission to publish implementation code, service configuration, music or credentials. Jamie's direction supplied by Mike remains native reproduction of the approved interface, not a separate redesign. Android [design acceptance #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains a gate.

## Build and test

Open `ios/LENOX.xcodeproj` in Xcode on macOS, scheme `LENOX`. There are no third-party application packages.

```bash
mkdir -p .build
swiftc ios/LENOX/MixPolicy.swift Tests/main.swift -o .build/policy-tests
.build/policy-tests
swiftc ios/LENOX/MixPolicy.swift Tests/Alignment/main.swift -o .build/alignment-tests
.build/alignment-tests
python3 scripts/check_source.py
python3 scripts/check_alignment.py
python3 -m unittest discover -s Tests -p 'test_android_artwork.py' -v
```

The Python command runs 18 synthetic importer cases and explicitly skips four real-APK integration tests unless `LENOX_TEST_APK` supplies the authorised local reference APK. See the handover for the integration command. Skips are not passes.

On a reviewed macOS checkout, `bash scripts/ci-alignment.sh` compiles device and Simulator apps, performs 12 synthetic audio checks and captures seven routes. It is not a full UI interaction or physical-device test. Native Files pickers, permission prompts, safe areas and accessibility may require documented platform differences.

The test library is session-only with 20-file / 64 MiB-per-file limits. Tempo is manual 50–200%, not beat SYNC. Initial gain remains 50% on iOS versus Android's 100%; this is recorded rather than silently increased. Persistent playlists, reviewed-metadata AI, occasion filters, full planning tools and waveform capture remain unfinished. Never infer missing metadata or fabricate recognition/track counts.

## Continuity, credit and prior evidence

The [alignment handover](docs/ANDROID_REFERENCE_ALIGNMENT.md), [reference manifest](docs/parity/android-reference.json), [feature register](docs/FEATURE_PARITY.md), [policy v1.0](docs/CROSS_PLATFORM_POLICY_V1.md) and [handover template](docs/FEATURE_HANDOVER_TEMPLATE.md) remain authoritative project records within their scopes. Original ownership and collaboration credit are unchanged.

The first test host `a7fc11fab969f79e8f96c26dd055b7ae9860232d` passed [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619), with 41 portable assertions and 10 Simulator checks. Preserve its [receipt](docs/builds/2026-10-31-a7fc11fab969.json), [handover](docs/IOS_FIRST_TEST_HANDOVER.md) and [signing/device checklist](docs/IOS_BUILD_AND_ACCEPTANCE.md) as historical evidence for that exact source.

Existing [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1), Android [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) and Linear task ownership remain in force. Jamie decides unresolved differences and integration. A build or screenshot does not authorise release or establish parity.

The existing workflow is restricted to this public repository, the alignment branch and standard `macos-15`, with read-only token scope, pinned actions and bounded retention. No Android application changes, live music/USB operations, paid runner, signing, TestFlight upload, permission changes or automatic merges were performed by this checkpoint.
