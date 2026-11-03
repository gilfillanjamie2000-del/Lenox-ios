# First iOS native audio test — continuation handover

**Classification:** RELATED implementation slice of Android issue #62; not a new competing product task. Related library/mixer records remain LEN-7 and LEN-14. iOS focus: Mike, as stated in the project conversation. Android ownership and all existing contributor credit remain unchanged. Existing policy PR #1 is preserved. The current Linear inventory was not accessible through a connected account in this session; no Linear assignment or status was changed.

## Reference and scope

Android behaviour reference: `gilfillanjamie2000-del/lunox-dj-automation` at `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`, PR #94. This reference is a candidate, not a released product. No Android implementation, original artwork, Firebase configuration, music or private test data is copied into this public iOS repository.

This new iOS code reproduces a limited workflow: explicit selection of local music, independent deck loading, explicit playback, pause/stop/seek, gain/channel/crossfader and manual speed. It deliberately does not implement playlists, metadata AI, BPM/key analysis, beat grids, EQ or waveforms. The SwiftUI screens are a labelled native test harness, not approved Android visual parity and not a decision to replace the planned shared UI/WKWebView architecture. Long-term UI architecture remains for review under #62.

## Files and responsibilities

- `ios/LENOX/LenoxApp.swift`: native test screens and file-picker entry, scene lifecycle notifications.
- `ios/LENOX/AudioModel.swift`: selected URL scope ownership, AVAudioPlayer decks, session interruption handling and explicit synthetic Simulator smoke path.
- `ios/LENOX/MixPolicy.swift`: portable mixer math, finite/bounded control validation and stale-request gate.
- `Tests/main.swift`: 41 executable policy assertions; no Apple UI/audio framework is required.
- `scripts/ci-ios.sh`: exact-SHA device and Simulator compilation, synthetic runtime checks, packaging and checksums.
- `scripts/generate_project.py`: deterministic native Xcode project generation with no external generator.

## Behaviour contract for Android developers

Crossfader position is normalised to [0,1]. Each deck output is capped to [0,1] after multiplying the deck's centre-full fader contribution, gain and channel value. At the midpoint both decks can be at full level. This matches the inspected Android reference curve, NOT a limiter or a perceptually constant-power mix. Defaults are quieter in this test host: gains start at 50%.

Loading never starts playback. Play requires an active scene and a selected track. Losing active state pauses both players; returning does not resume. Picker results from an invalidated generation are rejected. A route disconnect or interruption pauses playback. Manual speed is constrained to 0.5–2.0 and labelled as speed, not SYNC. Missing BPM/key remains unknown.

Android SAF references are not translated into iOS URLs. iOS uses security-scoped Files URLs, retaining access for the current session and balancing release when references are cleared. No durable bookmark/library or playlist persistence is claimed. Original files are never written. Clearing the library releases players before releasing selected-file scopes.

## Evidence and limitations

Portable policy tests executed locally with Swift 6.2.1, Linux: 41 assertions passed. Swift syntax parsing, Info.plist/XML, shell/Python syntax and static source checks passed before publication. These are NOT an iOS compile, independent QA approval or device validation. The cloud workflow records its own current-SHA results and must succeed before an IPA is claimed.

The simulator test opts in through `--ci-smoke`, generates two three-second WAV tones, decodes/loads/plays them, checks progress, volume endpoints, speed and seek, then calls the app's lifecycle handler to check pause and explicit-resume behaviour. It does NOT exercise the real Files picker, real OS background transitions, interruption delivery, real device audio quality, private music or user permissions. Source-level safety checks and direct lifecycle-handler calls do not replace those tests.

Known limitations: synchronous file resource lookup/player construction may stall UI; whole-library scanning is absent; permission revocation after player buffering is not proven; no audio metering or limiter; no persistent session; no final artwork; native architecture choice is provisional. Review those before promoting beyond a small synthetic/local-file prototype.

## Next safe action and recovery

First read the exact run's `build-provenance.json`, `SHA256SUMS`, policy result and simulator report. Reproduce compilation. Independently review selected-file scope and lifecycle behaviour. Securely configure approved Apple signing only after selecting the team, bundle identity, test devices and distribution method. Use the physical acceptance checklist. Do not mark iOS/Android parity from the Simulator result.

All application work is on an isolated prototype branch. No existing branch is force-pushed, merged or deleted. Recovery is to check out the previous commit or leave the prototype unmerged; there is no production migration to reverse. New tests and contracts can be reused independently by Android developers without copying Swift UI code.
