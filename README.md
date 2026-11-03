# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

LENOX is one DJ product with separate iOS and Android implementations. This branch contains the **first native iOS audio-test slice**, using Android's local-file and two-deck behaviour as its reference. It is not the finished DJ application and is not an approved visual redesign.

> **First cloud build verified — 31 October 2026.** [GitHub macOS run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) succeeded for source **`a7fc11fab969f79e8f96c26dd055b7ae9860232d`**. Device and Simulator builds passed, with 41 portable Swift assertions and 10 generated-audio Simulator checks. The IPA is **UNSIGNED and NOT directly installable on iPhone**. [Full verification receipt](docs/builds/2026-10-31-a7fc11fab969.json).

## Team progress

| Workstream | Verified state | Next gate |
| --- | --- | --- |
| Cross-platform governance | Policy branch and PR #1 preserved; [draft PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2) is stacked on it | Independent review; no automatic merge |
| Native iOS host | SwiftUI Home, Library, Mixer and Status compiled with Xcode 16.4 | Approved final design and physical-device acceptance |
| Local music | User-selected, read-only, session-scoped Files implementation; 20-track / 64 MiB limits | Real Files picker, permissions, revocation and persistence |
| Two decks | AVAudioPlayer A/B playback, seek, manual speed and crossfader exercised with generated WAV files in Simulator | Audible hardware, route changes and real OS lifecycle tests |
| Portable policy | 41 assertions passed locally and in the cloud; four local deliberate mutations detected | Independent technical review |
| First IPA | ARM64 iOS-device executable; package/source/checksums independently inspected after download | Apple signing/provisioning; not an installable beta yet |
| Simulator app | Separate Simulator build packaged and platform identity checked | Broader UI tests; not a replacement for phone testing |
| Final Android parity | Limited behaviour only; no private Android source/artwork published | Approved assets/UI, persistent playlists and shared AI contracts |
| BPM/key, true SYNC, EQ, waveforms | Not implemented in this iOS slice | Separate scoped implementation and two-way handover |

No percentage-complete figure is used. Code, builds, simulator evidence, physical-device evidence and release approval are separate milestones. **This README and receipt were updated after the tested commit; documentation-only commits are not claimed as separately compiled app revisions.**

## Build artifacts and identity

Open the successful run's artifact **`LENOX-iOS-UNSIGNED-a7fc11fab969f79e8f96c26dd055b7ae9860232d`**. It contains the device IPA, separate Simulator app, exact-source ZIP, checksums, build provenance, policy report, simulator report and captured simulator screenshot. Hosted retention currently expires **7 November 2026 at 14:50 UTC**; preserve the downloaded evidence before then.

- IPA: `LENOX-iOS-0.1.0-a7fc11fab969-UNSIGNED.ipa`, **183,932 bytes**.
- SHA-256: `3fc7a73d689f171a9fb2d79ba6c3898f3422dca8baf6ab0ff91fff2d0729d05a`.
- Bundle: `app.lenox.ios.test`; version **0.1.0**, build **1**; minimum iOS **16.0**.
- Toolchain: **Xcode 16.4 (16F6), iPhoneOS SDK 18.5**, standard `macos-15` runner.
- Downloaded outer ZIP matched GitHub's digest; IPA/source CRC and checksums passed. All 16 newly checked source/workflow blobs matched local bytes. The source snapshot contains 19 tracked files including inherited governance documents.

The device executable is not a renamed Simulator app. It has no code-signature load command or embedded provisioning profile. A successful unsigned build is not TestFlight/App Store readiness or independent reviewer approval.

## Run and build

Open `ios/LENOX.xcodeproj` in Xcode on macOS. Shared scheme: `LENOX`. No third-party application packages are required.

```bash
# Device and Simulator compilation, synthetic runtime checks, unsigned packaging:
bash scripts/ci-ios.sh

# Portable policy tests without Xcode (Swift on Linux or macOS):
mkdir -p .build
swiftc ios/LENOX/MixPolicy.swift Tests/main.swift -o .build/policy-tests
.build/policy-tests
python3 scripts/check_source.py
```

`python3 scripts/generate_project.py` deterministically regenerates the checked-in Xcode project. CI rejects project-generation drift. The Simulator `.app` archive is not an iPhone package. Simulator tests opt in via `--ci-smoke` and use generated tones only; they call lifecycle handlers directly rather than proving real OS background transitions or user permission flows.

## Test behaviour and limitations

Choose a downloaded audio file in **Library**, load Deck A or B, then press **Play** explicitly. Nothing scans the whole device, alters original music, autoplays imported tracks, requests a microphone or sends telemetry. Clear removes references, not originals. The session library does not persist across relaunch.

Default gains are 50%. The centre-full crossfader curve matches the Android reference, but there is no limiter; keep levels low. Manual speed is not beat-aligned SYNC. File resource lookup/player construction is synchronous and needs profiling. Saved playlists, metadata AI, audio-derived analysis, waveform rendering and approved artwork remain outside this slice. The native test harness does not replace the planned shared UI/WKWebView decision under #62.

## Team continuation and governance

Active branch: `prototype/ios-first-test-20261031`. It inherits policy source `a0ab643ca4b93985413b4e31351d92476e0152d9` without modifying that branch. Android is unchanged.

Start with the [first-test handover](docs/IOS_FIRST_TEST_HANDOVER.md), [build/signing and physical acceptance checklist](docs/IOS_BUILD_AND_ACCEPTANCE.md), [parity register](docs/FEATURE_PARITY.md), [policy](docs/CROSS_PLATFORM_POLICY_V1.md) and [handover template](docs/FEATURE_HANDOVER_TEMPLATE.md). Existing [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62), [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), Linear ownership and contributor credit remain in force. No Linear status or assignment was changed.

The workflow is restricted to this public repository, explicit prototype branch and standard runner, with pinned actions/read-only credentials and bounded retention. No larger paid runner, Apple signing, TestFlight upload or auto-merge is configured. Store authorised signing assets securely, never in this public repo or a chat. Physical iPhone validation, independent source/security review and Jamie's integration decision remain required.
