# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

LENOX is one DJ product with native iOS and Android implementations. This branch continues [draft PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2) with an **Android-reference alignment slice** in [draft PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3). It is not merged, not release-approved, and not visually or functionally indistinguishable from Android yet.

## Latest work: original Android assets

Mike requested the actual Android artwork rather than replacement graphics. The original home hero PNG and corrected LENOX splash JPEG have now been extracted from the retained reference APK, matched to the repository's exact HTML blobs, decoded and checked against Android's recorded image hashes. No image generation, resizing or recompression was performed.

The repository now contains a [read-only importer](scripts/import_android_artwork.py), [22 importer tests](tests/test_android_artwork.py) and the [artwork handover](docs/ANDROID_ARTWORK_IMPORT.md). All 22 tests passed locally with the real reference APK, and four deliberately broken integrity-check variants were detected. These results concern asset extraction, not iOS compilation or UI testing.

**The actual image binaries are in the separately delivered verified asset ZIP, not yet committed to this branch.** Native SwiftUI replacement of the textual artwork panel, Xcode resource registration, splash behaviour and a new IPA with verified embedded image hashes remain pending. The importer writes `ios/LENOX/AndroidArtwork` but deliberately does not edit the Xcode project or application code. Asset preparation must not be reported as completed visual parity.

## Team progress — 31 October 2026

| Work | Verified state / next gate |
| --- | --- |
| Reference | Android `feature/v3-deck-aware-mix-20261031`, exact SHA `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`; canonical `app/index.html` verified against packaged APK bytes |
| Native interface | Navy/purple panels, cyan accents, familiar Home/Library/Playlists/Mix dock, main feature destinations and responsive side-by-side deck layout implemented in source |
| Original artwork | Two original Android images extracted and hash-verified locally; importer/tests committed. Native resource integration and artwork-inclusive build remain pending |
| Real controls | Explicit Load & play, Stop, Pause, Resume, seek, gain/channel/crossfader and 50–200% tempo in 1% steps; failed load cannot start an old track |
| Library | Real title search over selected read-only session files; still limited to 20 files / 64 MiB each, not Android folder-scan parity |
| Prior native regression checks | Original 41 Swift assertions plus 43 route/search/format/crossfade assertions were recorded passing for the alignment implementation; importer work does not establish a new Swift build |
| New cloud build | Must be verified on its exact source revision; the earlier successful build does not validate these changes. No new cloud build was started for this importer-only checkpoint |
| Visual parity | **BLOCKED**: native artwork/splash integration, full studio routes and matched-device acceptance missing |
| Functional parity | **BLOCKED**: persistent library/playlists, metadata AI, occasion filters, full planning tools, waveform capture and other differences remain |
| Signed iPhone install | **BLOCKED**: no Apple signing/provisioning configured; no physical iPhone acceptance claimed |

The [alignment handover](docs/ANDROID_REFERENCE_ALIGNMENT.md), [pinned reference manifest](docs/parity/android-reference.json) and newer [artwork handover](docs/ANDROID_ARTWORK_IMPORT.md) describe scope, differences, validation and continuation. Missing features are explicitly unavailable; no fake recommendations, track counts or audio waveforms are used.

## Design and source boundary

Jamie's direction supplied by Mike is to reproduce the approved LENOX design and behaviour using **native iOS components**, not independently redesign the app or copy Android implementation into Swift. The current Android branch is the implementation reference; unresolved [owner-design acceptance #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains a gate.

The Android repository is private and this repository is public. The asset request is not blanket permission to publish Android implementation, service configuration, music or credentials. The importer copies only two identified images and their provenance, never HTML. The separately prepared images do not by themselves make the current textual home panel a matching or approved design.

Native Files pickers, permission prompts, safe areas and accessibility reflow may differ where required by iOS. LENOX-controlled screens and user-visible outcomes still require matched comparison. The safer 50% initial iOS gain is preserved, while Android starts at 100%; this is a recorded unresolved difference, not an unnoticed mismatch.

## Build and test

Open `ios/LENOX.xcodeproj` in Xcode on macOS; scheme `LENOX`, minimum iOS 16.0. No third-party application packages are required.

```bash
mkdir -p .build
swiftc ios/LENOX/MixPolicy.swift Tests/main.swift -o .build/policy-tests
.build/policy-tests
swiftc ios/LENOX/MixPolicy.swift Tests/Alignment/main.swift -o .build/alignment-tests
.build/alignment-tests
python3 scripts/check_source.py
python3 scripts/check_alignment.py
python3 -m unittest discover -s tests -v
```

The last command runs 18 synthetic importer tests and explicitly skips the four real-APK integration tests unless `LENOX_TEST_APK` supplies the authorised local reference APK. See the artwork handover for exact commands and verification. Skips are not passes.

On a reviewed macOS checkout:

```bash
bash scripts/ci-alignment.sh
```

This compiles separate iOS-device and Simulator apps, runs 12 generated-audio Simulator checks and captures seven screen states. It is not a comprehensive UI interaction test or cross-device parity approval. The device IPA is **UNSIGNED and not directly installable on iPhone**. Do not confuse the separately labelled Simulator app with an iPhone package.

The cloud workflow is constrained to this public repository, this isolated alignment branch and standard `macos-15`, with read-only token scope, pinned actions and bounded retention. No signing, TestFlight upload, paid runner or automatic merge is configured.

## Preserve earlier evidence

The first audio-test host at `a7fc11fab969f79e8f96c26dd055b7ae9860232d` passed [cloud run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619): 41 portable assertions and 10 synthetic Simulator checks. Its [build receipt](docs/builds/2026-10-31-a7fc11fab969.json), [first-test handover](docs/IOS_FIRST_TEST_HANDOVER.md) and [signing/device checklist](docs/IOS_BUILD_AND_ACCEPTANCE.md) remain historical evidence for that revision only.

The new native code is not independently approved just because the old build passed. Record new exact source, run, artifact checksum and limitations before promoting its state. Never update a parity flag from a screenshot or build result alone.

## Shared governance and continuation

[Policy v1.0](docs/CROSS_PLATFORM_POLICY_V1.md), [feature handover template](docs/FEATURE_HANDOVER_TEMPLATE.md), [feature register](docs/FEATURE_PARITY.md), [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1), Android [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52) and [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62) remain in force. Existing contributor credit and task ownership are unchanged.

Start with the alignment and artwork handovers, reproduce their tests, inspect exact-revision screenshots and implement a missing shared feature against common fixtures. Jamie decides unresolved design differences and integration. No Android source branch, original music, USB content, policy branch or existing prototype branch is changed by this isolated work.
