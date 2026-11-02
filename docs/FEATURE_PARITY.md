# Current native studio continuation — 2 November 2026

Branch `feature/ios-performance-studio-20261102`, based on playlist PR #4. [Two-way handover](IOS_STUDIO_HANDOVER.md). Native CI and all 8 UI scenarios passed on `4d7ce70794a378a0fa6cc517804ca0893ece3a2b`. [Run](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41523915266) · [receipt](builds/2026-11-02-4d7ce70794a3-studio.json). Paired Android visual comparison and real-device acceptance remain open. The JSON in `docs/parity/android-reference.json` is the frozen historical alignment contract, not a status claim for these new features.

| Feature | iOS candidate | Android reference / outstanding gate |
| --- | --- | --- |
| Original home/intro | Exact owner-authorised hero and bundled MP4, native one-shot player with skip/fallback | V3 `54f01bb…` / intro `c20276a…`; paired visual/device acceptance pending |
| Playlists / LEN-8 | Search, dedicated details, visible reorder controls; original storage and backup policy retained | Naming/order outcomes shared; backup adapter still required |
| Library / LEN-7 | Multi-file selection, atomic batch save, inactive-picker handoff fix | SAF folder scanning differs; real iPhone Files/provider acceptance pending |
| Mixer / LEN-14 / #51 | Native adaptive graphite/lime controls, explicit live-deck replacement, clock-driven platters and bounded jog seek | V4 design #118/#119; Android draft #161 is not inherited as device accepted |
| PCM scratching / analytics / EQ / SYNC | Unimplemented, honestly explained | Android draft #150 and other DSP proposals remain separately unverified |

The exact two approved assets may be published in public GitHub by Jamie's recorded authorisation. No other private media or Android implementation is included. Existing owners/credit remain.

---

# LENOX iOS ↔ Android Feature Parity Register

This is an evidence index, not a replacement for Linear ownership/status, GitHub reviews or CI. Nothing below establishes physical-device acceptance or full parity by itself.

## Current iOS playlist continuation — 31 October 2026

[Draft PR #4](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/4), implementation `f57009b840f96103a17265018d0e5cf692670a45`, base `5922983fc6059ba798724eb9061b277b44b8ecfc`. [Local verification](builds/2026-10-31-f57009b840f9-local.json) · [Native run](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41221542950) · [Resumable handover](IOS_PLAYLIST_HANDOVER.md).

| Shared feature | Current iOS implementation | Evidence / remaining parity gap | Ownership |
| --- | --- | --- | --- |
| Music library / [LEN-7](https://linear.app/lenox-app/issue/LEN-7) | Private persistent selected-file metadata and iOS bookmarks; explicit re-open/relink; no autoplay | Local disk/reference policy tests pass. Native run must be checked independently; actual Files/provider, revocation, iCloud and physical iPhone unverified. 20-reference cap; not Android folder-scan parity | Existing assignment retained; Mike's iOS contribution in PR #4 |
| Saved playlists / [LEN-8](https://linear.app/lenox-app/issue/LEN-8) | Create, name collision guards, rename, add/remove/reorder, cancel/save, confirmed delete, explicit A/B loading | 60 local playlist assertions and four compiled mutation probes. Run includes two separate Simulator processes for persistence; no user-device/UI approval claimed | Existing assignment retained; Mike's iOS contribution in PR #4 |
| Metadata backup / LEN-8 | JSON export to Files; strict import without bookmarks/paths/audio; new unresolved identities | New `lenox-playlist` v1 format; Android importer compatibility is NOT implemented. Common fixture and safety contract in playlist handover; never import file-access authority | No transfer of Android task ownership |
| Two-deck mixer / [LEN-14](https://linear.app/lenox-app/issue/LEN-14) | Existing AVAudioPlayer controls retained; saved-reference adapter adds explicit loading | Prior alignment build `cdc101ac7e6b7c9f5826b21e394760798295617f` has 41 + 43 assertions and 12 synthetic audio checks. New commit requires its own native run. Initial gain differs; SYNC/EQ/waveforms and physical audio still pending | Existing assignment retained |
| AI recommendations / [LEN-10](https://linear.app/lenox-app/issue/LEN-10) | Not implemented | No platform success inherited. Shared metadata/confidence fixtures still required | Existing assignment retained |
| Original artwork / design | Exact Android images extracted; importer and prior evidence retained | Not bundled into current app; no matched-state physical visual acceptance. Android design issue #28 remains separate | Existing design owner/credit retained |
| Android APK evidence / [LEN-6](https://linear.app/lenox-app/issue/LEN-6) | Not applicable to IPA | Android untouched. Inspect Android exact source, artifact, reviews and device evidence separately | Existing assignment retained |

Android reference remains `54f01bb213a5d30eaba99ea1f16f1d547b1d82ed`. Playlist naming follows the inspected Unicode-normalisation/no-overwrite behaviour. Native iOS bookmarks are not SAF URIs. Shared outcomes do not imply interchangeable source, storage capabilities or backup formats.

The accessible Linear playlist query returned no matching issues; workspace completeness is not established. No assignment or task state was changed. Jamie retains integration authority. Physical acceptance, independent QA/security and signed test deployment remain separate gates.

## Preserved historical evidence

- First host / [PR #2](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/2): `a7fc11fab969f79e8f96c26dd055b7ae9860232d`, [run 41211621619](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41211621619); 41 portable assertions + 10 synthetic Simulator checks. At that revision file selection was session-only and playlists were absent. [Receipt](builds/2026-10-31-a7fc11fab969.json) / [handover](IOS_FIRST_TEST_HANDOVER.md).
- Reference alignment / [PR #3](https://github.com/gilfillanjamie2000-del/Lenox-ios/pull/3): `cdc101ac7e6b7c9f5826b21e394760798295617f`, [run 41214780323](https://github.com/gilfillanjamie2000-del/Lenox-ios/actions/runs/41214780323); 41 + 43 portable assertions + 12 synthetic audio checks. [Receipt](builds/2026-10-31-cdc101ac7e6b-cloud.json). Later artwork-import work did not put original images in that IPA.

**Update rule:** link both platform implementations, exact source, actual checks, known failures and next action. Never promote from a screenshot, another revision/platform's run or an unreviewed PR. Later documentation-only commits are not newly compiled builds. [Policy](CROSS_PLATFORM_POLICY_V1.md) · [Handover template](FEATURE_HANDOVER_TEMPLATE.md) · [Device/signing acceptance](IOS_BUILD_AND_ACCEPTANCE.md).
