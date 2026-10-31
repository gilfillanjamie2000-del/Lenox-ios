# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

Official iOS source repository for LENOX, an AI-assisted DJ and music-management product being developed alongside Android. Cross-platform development follows the owner-approved **LENOX Universal Cross-Platform Development Policy v1.0** (31 October 2026).

> **First cloud build verified — 31 October 2026.** [GitHub macOS run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) succeeded for source **`a7fc11fab969f79e8f96c26dd055b7ae9860232d`**. Device and Simulator compilation passed, with 41 portable Swift assertions and 10 generated-audio Simulator checks. The IPA is **UNSIGNED and NOT directly installable on iPhone**. [Verification receipt](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/builds/2026-10-31-a7fc11fab969.json).

> **Team start here:** application work is on the [first-test prototype branch](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/prototype/ios-first-test-20261031), in [draft PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). It is **not merged into `main`**. This README update does not merge or approve application code.

## Current work and progress

| Area | Current evidence | Remaining work |
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

Progress is tracked by evidence, not an invented completion percentage. Source code, local tests, cloud compilation, Simulator checks, real-device testing and release approval are separate states. Documentation-only commits after the tested source are not claimed as newly compiled application revisions.

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

The first milestone is a small **native iOS audio test host**, informed by the Android library and mixer workflow. It lets an authorised tester select local audio, load Deck A and Deck B, explicitly start playback and exercise basic mixing controls. Its lifecycle handler pauses both decks when the app becomes inactive and does not automatically resume them.

It is **not the finished Android application port**, not a new approved LENOX design and not a TestFlight/App Store release. Because this repository is public and Android's repository is private, no private Android source, original artwork, Firebase configuration, user music or signing secrets have been published here. The final shared UI architecture remains subject to the existing iOS feasibility work.

This slice has no persistent playlists, automatic audio-derived BPM/key, beat-aligned SYNC, EQ or waveform display. File metadata lookup/player construction is synchronous and needs profiling. The crossfader follows the Android reference's centre-full curve, not a limiter; begin listening at low volume. The current library is session-only.

## Developer handover and source

- [Active source, Xcode project and detailed build instructions](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/prototype/ios-first-test-20261031)
- [First-test cross-platform handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_FIRST_TEST_HANDOVER.md)
- [Build/signing boundaries and physical acceptance checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)
- [Updated feature-parity register](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/FEATURE_PARITY.md)
- [Cloud build history](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions)

Open `ios/LENOX.xcodeproj` from the prototype branch in Xcode on macOS. Scheme: `LENOX`; minimum target: iOS 16.0. No third-party application packages are required. Portable policy tests can run independently with Swift on Linux or macOS. The handover documents source files, contracts, test commands, limitations and the next safe step so another developer can resume without private-chat context.

The Simulator smoke path uses generated WAV tones and direct lifecycle-handler calls. It does not test the real Files picker, permission revocation, actual OS background transitions, interruption delivery or physical iPhone audio quality. Those checks remain explicitly pending.

## Governance and cross-platform continuity

Existing [shared governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62), Linear ownership and contributor credit remain in force. [Policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1) contains the policy, handover template and original parity register. PR #2 is stacked on that branch without modifying it. No Linear assignment or task state was changed; its current inventory was not accessible through a connected account during this work.

Changes must document platform-neutral behaviour, implementation files, tests actually run, precise source/build identity, differences from Android, known failures and the next safe step. Android and iOS each require their own applicable acceptance checks; neither platform inherits the other's success.

The cloud workflow is restricted to this public repository, explicit prototype branch and standard runner, with read-only token permissions, pinned actions and bounded retention. No application merge, Apple enrollment, release signing, TestFlight deployment, premium macOS runner or automatic-merge policy is authorised by this README. Never commit or paste signing keys or provisioning credentials into this public repository.
