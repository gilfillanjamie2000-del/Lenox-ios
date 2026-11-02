# LENOX 0.1.1 build 2 — phone test candidate

[Download unsigned IPA](https://github.com/gilfillanjamie2000-del/Lenox-ios/raw/refs/heads/builds/ios-test-0.1.1-b2-ui-pending/downloads/LENOX-iOS-0.1.1-b2-861b4aeb268e-UNSIGNED.ipa)

Source: `861b4aeb268eca1cd1cabbe43205632bb0bab003`. SHA-256: `51bbf616f4774e6d2f8b0cde1c1b7afbade1ebf80262110598ddb1dd95979b4f`.

This public candidate removes the fixed song-count and audio-file-size caps, replaces the SwiftUI audio importer with a stable native opening picker, adds open-in-place/Documents support and validates audio with bounded decoding before an atomic metadata save. No automatic music copying, storage reset or schema migration.

**Verification state:** device and Simulator compile; all portable suites, 34 native performance/import/video checks (including actual 128 MiB audio), and the eight existing UI scenarios passed. Three new Files UI scenarios failed before selecting anything because their filename selector did not match iOS accessibility labels. Their corrected tests are running at source `8d4012840a83a183928ac657b2ef5dfd9be9b423`; only Tests/UI/StudioUITests.swift differs from this candidate's source. **Full UI pass and exact phone/provider acceptance are not claimed.**

[Candidate diagnostics and tests](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41529283893) · [Corrected UI test run](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41533124675) · [Draft PR #5](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/5).

Unsigned, no provisioning profile; authorised signing/sideloading is required. Native ARM64 iPhoneOS, minimum iOS 16.0, bundle app.lenox.ios.test. Existing metadata-size/playlist-count safeguards and codec/device capabilities remain. Genuine PCM scratching remains unfinished. This is a test candidate, not a release or independent QA approval.
