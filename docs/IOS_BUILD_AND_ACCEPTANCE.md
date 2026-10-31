# iOS build, signing and acceptance

## Build evidence

The workflow runs only on the explicitly scoped prototype branch in this public repository using the standard `macos-15` runner. GitHub documents standard public-repository runner usage as free: https://docs.github.com/en/actions/concepts/billing-and-usage . No premium runner or external build service is configured. Moving the repo to private causes the job's guard to skip; do not remove that guard without quota/billing approval. Artifact retention is seven days for successful candidates and three days for diagnostic reports.

Every successful candidate includes the full Git commit, workflow run ID/attempt, Xcode version, package SHA-256 and executable policy and synthetic Simulator results. README status alone is not a build receipt. No independent reviewer approval is manufactured by CI.

## Unsigned is not installable

`CODE_SIGNING_ALLOWED=NO` builds a real iOS-device Mach-O application without an Apple provisioning profile. It is placed in `Payload/LENOX.app` inside an explicitly `UNSIGNED.ipa` archive. This is useful for compilation/provenance review; it is not a signed development, ad-hoc, TestFlight or App Store distribution package.

An iPhone installation requires an appropriate signing identity and provisioning/distribution setup. See Apple's documentation: https://developer.apple.com/help/account/provisioning-profiles/create-a-development-provisioning-profile and https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices . No Apple account, signing key, profile, device UDID or paid enrollment is assumed available. Do not put those credentials in this public repo, a PR, a chat transcript or the source archive. The current workflow neither reads signing secrets nor signs or deploys releases.

## Physical acceptance — all pending until recorded

1. Record device model, iOS version, signed build checksum, source SHA and installer/distribution method.
2. Select an allowed local audio file; cancel the picker; try an unsupported/empty/oversized file; background during selection. Record errors and preservation of the prior library.
3. Load both decks without autoplay; play/pause/stop/reload; verify independent positions, seek bounds, speed and actual audible crossfader/gain behaviour at low volume.
4. Leave and reopen the app; lock/unlock; receive an interruption; disconnect headphones; change output. Verify no unexpected autoplay and both decks pause safely.
5. Clear the library and verify references stop playing and originals remain unchanged. Relaunch and verify the honest session-only state.
6. Check accessibility, large text, small-screen layout, landscape and VoiceOver labels; preserve the existing design approval process.
7. Independently review audio and file-permission code and update the shared handover/parity record with actual findings. Jamie decides integration. Do not merge or release merely because the debug build is green.
