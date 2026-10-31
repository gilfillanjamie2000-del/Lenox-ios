# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product owner and integration decisions: Jamie.**

Official iOS source repository for LENOX, an AI-assisted DJ and music-management product being developed alongside Android. Cross-platform development follows the owner-approved **LENOX Universal Cross-Platform Development Policy v1.0** (31 October 2026).

> **Team start here:** application work is on the [first-test prototype branch](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/prototype/ios-first-test-20261031), in [draft PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2). It is **not merged into `main`**. This README update does not merge or approve application code.

## Current work and progress — 31 October 2026

| Area | Current evidence | Remaining work |
| --- | --- | --- |
| Repository foundation | Existing README and [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1) preserved; isolated implementation branch created | Independent review and Jamie's integration decision |
| First native iOS test host | SwiftUI Home, Library, Mixer and Status source committed in PR #2 | Xcode/runtime validation and approved final visuals |
| Music selection | Read-only, explicit Files selection; session-only references, bounded count/size | Real iPhone permissions, revocation and persistent library |
| Two-deck audio | AVAudioPlayer A/B load/play/pause/stop/seek, manual speed, gain/channel and crossfader source | Audible device tests; this is not beat-aligned SYNC |
| Portable Swift tests | 41 assertions passed locally; all four deliberate guard/math mutations detected | Exact-source cloud execution and independent review |
| GitHub cloud Mac | [Build attempt 1](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619) started for `a7fc11fab969f79e8f96c26dd055b7ae9860232d` | Result/artifact verification is not yet claimed in this update |
| Test IPA | Unsigned device packaging and separate Simulator package configured | A successful package must have matching source/checksums; no installable IPA claimed |
| iPhone installation | **Blocked: Apple signing and provisioning have not been configured by this work** | Authorised signing setup and physical-device acceptance |
| Android visual/feature parity | Limited behavioural reference only; Android repository unchanged | Approved assets/UI, playlists, AI, BPM/key, SYNC, EQ and waveforms |

Progress is tracked by evidence, not an invented completion percentage. Source code, local tests, cloud compilation, Simulator checks, real-device testing and release approval are separate states.

## What Mike is building

The first milestone is a small **native iOS audio test host**, informed by the Android library and mixer workflow. It lets an authorised tester select local audio, load Deck A and Deck B, explicitly start playback and exercise basic mixing controls. It pauses when the app becomes inactive and does not automatically resume imported tracks.

It is **not the finished Android application port**, not a new approved LENOX design and not a TestFlight/App Store release. Because this repository is public and Android's repository is private, no private Android source, original artwork, Firebase configuration, user music or signing secrets have been published here. The final shared UI architecture remains subject to the existing iOS feasibility work.

## Developer handover and source

- [Active source, Xcode project and detailed build instructions](https://github.com/gilfillanjamie2000-del/Lenox-ios/tree/prototype/ios-first-test-20261031)
- [First-test cross-platform handover](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_FIRST_TEST_HANDOVER.md)
- [Build/signing boundaries and physical acceptance checklist](https://github.com/gilfillanjamie2000-del/Lenox-ios/blob/prototype/ios-first-test-20261031/docs/IOS_BUILD_AND_ACCEPTANCE.md)
- [Cloud build history](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions)

Open `ios/LENOX.xcodeproj` from the prototype branch in Xcode on macOS. Scheme: `LENOX`; minimum target: iOS 16.0. No third-party application packages are required. Portable policy tests can run independently with Swift on Linux or macOS. The handover documents known synchronous-decoding and session-only limitations so another developer can resume without private-chat context.

## Governance and cross-platform continuity

Existing [shared governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62), Linear ownership and contributor credit remain in force. [Policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1) contains the policy, handover template and parity register. PR #2 is stacked on that branch without modifying it.

Changes must document the platform-neutral behaviour, implementation files, tests actually run, precise source/build identity, differences from Android, known failures and the next safe step. Android and iOS must each pass their own applicable acceptance checks; neither platform inherits the other's test success.

No application merge, Apple enrollment, release signing, TestFlight deployment, premium macOS runner or automatic-merge policy is authorised by this README. Never commit or paste signing keys or provisioning credentials into this public repository.
