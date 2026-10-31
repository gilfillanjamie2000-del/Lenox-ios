# LENOX iOS

**iOS development: Mike (Iammrmikeman). Product direction and integration decisions: Jamie.**

LENOX is one DJ product with separate iOS and Android implementations. This branch contains the **first native iOS audio-test slice**, using Android's local-file and two-deck behaviour as its reference. It is not the finished DJ application and is not an approved visual redesign.

## Team progress — 31 October 2026

| Workstream | Evidence-backed state | Next gate |
| --- | --- | --- |
| Cross-platform governance | Existing policy branch and PR #1 preserved; this branch is stacked on that work | Independent review; no automatic merge |
| Native iOS test host | SwiftUI Home, Library, Mixer and Status source implemented | Xcode compile and simulator checks |
| Local music | User-selected, read-only, session-scoped files; 20-track / 64 MiB limits | Real iPhone Files permission and revocation testing |
| Two decks | Native AVAudioPlayer load/play/pause/stop/seek, manual speed, gain/channel/crossfader | Simulator and audible physical-device acceptance |
| Shared policy tests | 41 assertions passed locally with Swift 6.2.1 on Linux | Re-run on exact cloud source SHA |
| Cloud macOS build | Workflow prepared; build result must be read from the exact run, not inferred from this README | Device compile, simulator smoke, artifact verification |
| First IPA | Unsigned packaging configured; no successful IPA claimed at this source revision | Download and verify matching build artifact |
| iPhone installation | **Blocked: no Apple signing identity/provisioning configured by this work** | Authorised secure signing and registered-device acceptance |
| Final Android visual parity | **Pending**; no private Android source or original artwork published here | Owner-approved asset distribution and design review |
| Playlists, AI, BPM/key, SYNC, EQ, waveforms | Not implemented in this iOS slice | Separate scoped work and two-way handovers |

No percentage-complete figure is used: source, tests, builds, simulator results, phone results and approval are separate milestones.

## Where the work is

- Active implementation: `prototype/ios-first-test-20261031`.
- This branch inherits `docs/cross-platform-policy-v1-20261031` at `a0ab643ca4b93985413b4e31351d92476e0152d9` without modifying that branch.
- Existing shared work: [iOS feasibility #62](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/62), [governance #52](https://github.com/gilfillanjamie2000-del/lunox-dj-automation/issues/52), [policy PR #1](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/1).
- [Cloud build runs](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions) are authoritative for compilation. Read the run's **source SHA**, not just a green badge.
- [First-test handover](docs/IOS_FIRST_TEST_HANDOVER.md) records scope, parity, limitations and continuation steps.
- [Cross-platform policy](docs/CROSS_PLATFORM_POLICY_V1.md), [handover template](docs/FEATURE_HANDOVER_TEMPLATE.md) and [parity register](docs/FEATURE_PARITY.md) remain the shared governance documents.

## Run and build

Open `ios/LENOX.xcodeproj` in Xcode on macOS. The shared scheme is `LENOX`; deployment target is iOS 16.0. No third-party application dependencies or package manager are required.

For a local **unsigned** build with both device compilation and synthetic simulator tests:

```bash
bash scripts/ci-ios.sh
```

The script records toolchain versions and source identity, builds a device application and a separate Simulator application, launches the Simulator test with generated audio, and packages the device app as `LENOX-iOS-0.1.0-<commit>-UNSIGNED.ipa` only after all required steps succeed. An unsigned IPA **cannot be installed directly on an iPhone**. The separately named Simulator `.app` archive is not an iPhone application package.

For portable policy tests without Xcode:

```bash
mkdir -p .build
swiftc ios/LENOX/MixPolicy.swift Tests/main.swift -o .build/policy-tests
.build/policy-tests
python3 scripts/check_source.py
```

`python3 scripts/generate_project.py` deterministically regenerates the checked-in Xcode project. Cloud validation rejects generated-project drift.

## What testers should expect

Choose a downloaded audio file in **Library**, load Deck A or B, then press **Play** explicitly. The test app does not scan the entire device, alter original tracks, autoplay imported tracks, request the microphone or send telemetry. Clearing the session removes references, not original files. Selecting files again after relaunch is intentional in this first slice.

Default gains are 50%. The crossfader uses the Android reference's centre-full curve, not an equal-power curve; it does not provide a limiter. Keep listening levels low. Manual speed is not beat-aligned SYNC. File decoding is currently synchronous on the main thread and needs profiling before large-library use.

## Cloud and release boundaries

The workflow is limited to this repository while it is public, the explicit prototype branch and the standard `macos-15` runner. No larger paid runner, signing certificate, deployment, TestFlight upload or auto-merge is configured. Action dependencies are commit-pinned. Retention is bounded; keep the source SHA and checksums with any retained build.

Apple signing assets must be provisioned through an authorised secret-management process, never committed or pasted into issues. A cloud build is not release approval. [Build and signing notes](docs/IOS_BUILD_AND_ACCEPTANCE.md) describe the remaining gates.

## Continue the work

Start with the handover and the latest exact-SHA build evidence. Reproduce the portable tests, run a Simulator build, then perform the explicit iPhone acceptance checklist after authorised signing. Update the shared feature record and README when evidence changes. Preserve original contributor credit and do not transfer Android task ownership.

The existing owner-approved **LENOX Universal Cross-Platform Development Policy v1.0** remains in force. No Android branch or original music file is changed by this work.
