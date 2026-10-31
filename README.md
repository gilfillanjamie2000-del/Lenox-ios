# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

Official iOS source repository for LENOX, an AI-assisted DJ and music-management product being developed alongside Android. Cross-platform development follows the owner-approved **LENOX Universal Cross-Platform Development Policy v1.0** (31 October 2026).

> **Team start here:** current native Android-reference alignment is in [draft PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3), on [the alignment branch](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-android-reference-alignment-20261031). It builds on [first-test PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). Neither application PR is merged into `main`. This README update does not merge or approve application code.

## Current work: Android and iOS alignment — 31 October 2026

Jamie's direction, supplied by Mike, is to reproduce the approved LENOX interface and behaviour with native iOS components, not develop a separate product or copy Android implementation into Swift. The reference is Android branch `feature/v3-deck-aware-mix-20261031`, pinned to `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`. Canonical `app/index.html` matches the inspected APK's packaged UI. The Android assets HTML path is generated during packaging at that revision.

**The applications are not visually or functionally indistinguishable yet.** Current progress is a partial native alignment, not parity approval.

| Alignment area | Current evidence | Remaining gate |
| --- | --- | --- |
| Interface and navigation | Native navy/purple/cyan styling, Home/Library/Playlists/Mix dock, feature destinations and responsive two-deck layout implemented in source | Exact-source Xcode rendering and matched-state comparison; full navigation/tools remain incomplete |
| Mixer and library controls | Real title search, explicit Load & play with failed-load protection, matching transport labels and 50–200% tempo in 1% steps | Native runtime tests, physical audio comparison and persistent library behaviour |
| Local tests | Original 41 Swift assertions and 43 new assertions passed; four deliberately broken variants detected | Not SwiftUI compilation, independent review or device evidence |
| Cloud build | [Run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323) created for exact implementation `cdc101ac7e6b7c9f5826b21e394760798295617f`; last checked queued | Read the live run and verify its artifact before claiming compilation or a new IPA |
| Full parity | **BLOCKED**: original assets/splash, complete navigation, persistent playlists/library, reviewed-metadata AI, occasion tools and matched-device acceptance missing | Complete and independently verify each shared feature; obtain Jamie's acceptance |

Read the [alignment handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_REFERENCE_ALIGNMENT.md), [pinned reference and differences](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/parity/android-reference.json) and [local regression receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/builds/2026-10-31-cdc101ac7e6b-local.json). Original Android artwork/source has not been published into this public repository. An authorised asset-distribution path is still required. Android [design acceptance #28](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/28) remains open; the reference branch is not automatically a final design approval.

Necessary iOS system pickers, permission prompts, safe areas and accessibility reflow may differ. LENOX-controlled screens and user-visible outcomes still require comparison. The safer 50% initial iOS gain remains deliberately unchanged from the first prototype, versus Android's 100%; that unresolved difference is documented rather than silently increasing playback volume.

Documentation commits after the implementation SHA are not claimed as newly compiled application revisions. The earlier successful build below validates only its own source, not PR #3.

## First test host: verified baseline

> **First cloud build verified — 31 October 2026.** [GitHub macOS run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) succeeded for source **`a7fc11fab969f79e8f96c26dd055b7ae9860232d`**. Device and Simulator compilation passed, with 41 portable Swift assertions and 10 generated-audio Simulator checks. The IPA is **UNSIGNED and NOT directly installable on iPhone**. [Verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/builds/2026-10-31-a7fc11fab969.json).

| Area | Baseline evidence | Remaining work |
| --- | --- | --- |
| Repository foundation | Existing [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1) preserved; isolated implementation branch and draft PR #2 | Independent review and Jamie's integration decision |
| First native iOS test host | SwiftUI Home, Library, Mixer and Status compiled with Xcode 16.4 | Approved final visuals and real-device acceptance |
| Music selection | Read-only, explicit Files selection implemented; session-only references with count/size limits | Real iPhone Files picker, permissions, revocation and persistent library |
| Two-deck audio | AVAudioPlayer A/B playback, seek, manual speed, gain/channel and crossfader implemented; generated WAV playback exercised in Simulator | Audible device tests; this is not beat-aligned SYNC |
| Portable Swift tests | 41 assertions passed locally and in the cloud; four deliberately broken local variants detected | Independent source/security review |
| GitHub cloud Mac | [Build attempt 1](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) **SUCCESS** on exact source `a7fc11fab969f79e8f96c26dd055b7ae9860232d` | Broader UI tests and physical-device evidence |
| Test IPA | ARM64 iOS-device application packaged; downloaded archive, source identity and SHA-256 verified | Unsigned: signing/provisioning still required for iPhone installation |
| Simulator app | Separate Simulator build and 10 synthetic runtime checks passed | These do not prove real Files permission flows or OS lifecycle behaviour |
| iPhone installation | **Blocked: Apple signing and provisioning have not been configured by this work** | Authorised signing setup and physical-device acceptance |
| Android visual/feature parity | Limited behavioural reference only; Android repository unchanged | Approved assets/UI, playlists, AI, BPM/key, SYNC, EQ and waveforms |

Progress is tracked by evidence, not an invented completion percentage. Source code, local tests, cloud compilation, Simulator checks, real-device testing and release approval are separate states.

## First test build

Open the successful run and download artifact **`LENOX-iOS-UNSIGNED-a7fc11fab969f79e8f96c26dd055b7ae9860232d`**. It includes the unsigned device IPA, separate Simulator app, exact-source ZIP, build provenance, checksums, test reports and an actual Simulator screenshot. Current GitHub artifact retention expires **7 November 2026 at 14:50 UTC**.

| Build identity | Value |
| --- | --- |
| IPA | `LENOX-iOS-0.1.0-a7fc11fab969-UNSIGNED.ipa` |
| Size | 183,932 bytes |
| SHA-256 | `3fc7a73d689f171a9fb2d79ba6c3898f3422dca8baf6ab0ff91fff2d0729d05a` |
| Bundle / version | `app.lenox.ios.test` / 0.1.0, build 1 |
| Minimum iOS | 16.0 |
| Toolchain | Xcode 16.4 (16F6), iPhoneOS SDK 18.5 |
| Runner | Standard GitHub `macos-15` runner in this public repository |
| Installation state | **UNSIGNED: not directly installable on iPhone** |

The executable was inspected as a real ARM64 iOS-device Mach-O, not a renamed Simulator application. It has no code-signature load command or embedded provisioning profile. A green build does not establish TestFlight/App Store readiness, hardware validation or independent reviewer approval.

## What Mike is building

The first milestone was a small **native iOS audio test host**, informed by the Android library and mixer workflow. It lets an authorised tester select local audio, load Deck A and Deck B, explicitly start playback and exercise basic mixing controls. Its lifecycle handler pauses both decks when the app becomes inactive and does not automatically resume them. The next isolated implementation stage is PR #3's Android-reference alignment described above.

It is **not the finished Android application port**, not a new approved LENOX design and not a TestFlight/App Store release. Because this repository is public and Android's repository is private, no private Android source, original artwork, Firebase configuration, user music or signing secrets have been published here. The final shared UI architecture remains subject to the existing iOS feasibility work.

This slice has no persistent playlists, automatic audio-derived BPM/key, beat-aligned SYNC, EQ or waveform display. File metadata lookup/player construction is synchronous and needs profiling. The crossfader follows the Android reference's centre-full curve, not a limiter; begin listening at low volume. The current library is session-only.

## Developer handover and source

- [Current alignment source, Xcode project and detailed instructions](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/feature/ios-android-reference-alignment-20261031)
- [Alignment scope, blockers and continuation](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/feature/ios-android-reference-alignment-20261031/docs/ANDROID_REFERENCE_ALIGNMENT.md)
- [First-test cross-platform handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_FIRST_TEST_HANDOVER.md)
- [Build/signing boundaries and physical acceptance checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)
- [Feature-parity register](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/FEATURE_PARITY.md)
- [Cloud build history](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions)

Open `ios/LENOX.xcodeproj` from the relevant implementation branch in Xcode on macOS. Scheme: `LENOX`; minimum target: iOS 16.0. No third-party application packages are required. Portable policy tests can run independently with Swift on Linux or macOS. Handovers document source files, contracts, test commands, limitations and the next safe step so another developer can resume without private-chat context.

The Simulator smoke path uses generated WAV tones and direct lifecycle-handler calls. It does not test the real Files picker, permission revocation, actual OS background transitions, interruption delivery or physical iPhone audio quality. Those checks remain explicitly pending.

## Governance and cross-platform continuity

Existing [shared governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62), Linear ownership and contributor credit remain in force. [Policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1) contains the policy, handover template and original parity register. PR #2 is stacked on that branch; PR #3 is stacked on PR #2 without changing either existing branch. No Linear assignment or task state was changed. The accessible Linear iOS/mixer searches returned no matches; this is not evidence that the shared workspace has no relevant tasks.

Changes must document platform-neutral behaviour, implementation files, tests actually run, precise source/build identity, differences from Android, known failures and the next safe step. Android and iOS each require their own applicable acceptance checks; neither platform inherits the other's success.

Cloud workflows are restricted to this public repository, their explicit development branches and standard runners, with read-only token permissions, pinned actions and bounded retention. No application merge, Apple enrollment, release signing, TestFlight deployment, premium macOS runner or automatic-merge policy is authorised by this README. Never commit or paste signing keys or provisioning credentials into this public repository.
